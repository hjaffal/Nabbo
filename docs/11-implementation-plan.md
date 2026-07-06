# Implementation Plan

## Overview

The implementation is broken into 6 phases, each building on the previous. The goal is to reach a testable product loop as early as possible — a parent can capture, review, and see items in Today by the end of Phase 4.

---

## Phase 1 — Foundation

**Goal:** Working app shell with auth, household setup, and data layer.

### Tasks

- [ ] Flutter project setup (clean architecture, feature-first folder structure)
- [ ] State management setup (Riverpod)
- [ ] Firebase project creation and configuration (iOS + Android)
- [ ] Firebase Auth integration (email/password)
- [ ] Firestore data model implementation (Household, Family Member, Source Message, Extracted Item)
- [ ] Repository layer (Firestore CRUD for core objects)
- [ ] Onboarding flow screens:
  - Welcome
  - Household setup (name, timezone, language)
  - Add children
  - Add other people (optional)
  - Nabbo email alias display
  - Sharing explanation
  - First capture prompt
- [ ] Basic navigation shell (Home, Review, Today, Settings)
- [ ] Settings screen (household details, family members, account)

### Deliverable
App launches, user can sign up, create a household, add family members, and see the main navigation.

---

## Phase 2 — Capture

**Goal:** All input methods working — content enters Nabbo as Source Messages.

### Tasks

- [ ] Free text capture (type a note → stored as Source Message)
- [ ] Voice capture:
  - Record audio in Flutter
  - Upload to Cloud Storage
  - Cloud Function triggers Speech-to-Text
  - Transcript stored with Source Message
- [ ] Mobile share extension:
  - iOS share extension (Swift, App Group for data passing)
  - Android share target (Kotlin, intent filter)
  - Bridge shared content into Flutter / Firestore
  - Support: text, images, PDFs, URLs
- [ ] Email forwarding service:
  - Cloud Run service to receive inbound emails
  - Custom domain setup (`@nabbo.app`)
  - Parse email (sender, subject, body, attachments)
  - Store as Source Message + attachments in Cloud Storage
  - Unique alias per household
- [ ] Image/PDF processing:
  - Upload to Cloud Storage
  - Cloud Function triggers Vision AI / Document AI
  - Extracted text stored with Source Message
- [ ] Processing status UI (processing, found, no action, error)
- [ ] Capture confirmation screen (source preview, optional child selection)

### Deliverable
Parent can send content to Nabbo via all 4 input methods. Source Messages appear in Firestore with processing status.

---

## Phase 3 — Extraction (AI)

**Goal:** Nabbo understands captured content and produces structured Extracted Items.

### Tasks

- [ ] Extraction prompt engineering:
  - System prompt with Nabbo extraction schema
  - Household context injection (family members, existing events, routines)
  - Output format: structured JSON matching Extracted Item schema
  - Confidence scoring per field
  - Fact/suggestion/inference separation
- [ ] Cloud Function: extraction pipeline
  - Triggered on Source Message creation (status: ready for extraction)
  - Gathers household context from Firestore
  - Calls Vertex AI (Gemini 1.5 Pro)
  - Parses response into Extracted Items
  - Stores in Firestore with confidence and uncertainty
  - Updates Source Message processing status
  - Sends push notification if item is urgent
- [ ] Change detection logic:
  - Query existing approved objects for same household
  - Compare key fields (date, time, location, items)
  - If conflict found → create Change object, flag in Extracted Item
- [ ] Risk detection logic:
  - Evaluate extracted items for gaps (no owner, deadline near, missing info)
  - Create Risk objects when execution gaps detected
- [ ] Error handling:
  - Extraction failure → status "failed", user can retry or add manually
  - No action found → status "no_action", user can dismiss or add manually
  - Partial extraction → mark uncertain fields, require review

### Deliverable
Source Messages are automatically processed. Extracted Items appear in Firestore with structured fields, confidence levels, and linked risks/changes.

---

## Phase 4 — Review

**Goal:** Parent can review, verify, and approve extracted items into the household plan.

### Tasks

- [ ] Review Inbox screen:
  - Query pending Extracted Items for household
  - Sort by urgency (due today → due tomorrow → changes → other)
  - Show card preview (source, summary, member, type, urgency marker)
  - Pull-to-refresh + real-time listener
- [ ] Review Card UI:
  - Zone 1: Source indicator (icon + label)
  - Zone 2: Operational summary
  - Zone 3: Extracted fields with confidence labels (Clear, Check this, Missing, Suggested)
  - Zone 4: Uncertainty highlights
  - Zone 5: Suggested actions
  - Zone 6: Source preview (expandable to full source)
- [ ] Review actions:
  - Approve → commit objects to household plan collections
  - Edit → inline field editing (date, time, location, owner, items, amount)
  - Dismiss → remove with optional reason
  - Snooze → delay with time picker (later today, tomorrow, weekend, next week, custom)
  - Assign owner → pick household member
  - Mark handled → record as completed
  - Split → create separate cards from multi-action extraction
  - Merge → link to existing object, confirm change
- [ ] Approval logic (Cloud Function):
  - Creates committed objects (Event, Task, Deadline, Checklist, Form, Payment, etc.)
  - Runs risk evaluation (owner gaps, deadline proximity)
  - Returns confirmation message
- [ ] Source view screen (full original content, metadata, linked objects)

### Deliverable
Full review flow working. Parent can verify, correct, and approve items. Approved items appear as committed objects in Firestore.

---

## Phase 5 — Today Command Center

**Goal:** Parent sees a clear daily execution view of approved items.

### Tasks

- [ ] Today screen with 7 zones:
  - Zone 1: Today status (summary generated from object counts + risk level)
  - Zone 2: Next action (highest priority item with action button)
  - Zone 3: Departure & movement (events with times, locations, owners)
  - Zone 4: Timeline (chronological events, past faded)
  - Zone 5: Checklist (required items grouped by member + event)
  - Zone 6: Risks & changes (owner gaps, time changes, deadline alerts)
  - Zone 7: Evening reset (tomorrow prep, appears later in day)
- [ ] Today item actions:
  - Mark done / packed / paid / submitted
  - Assign owner
  - View source
  - Edit
  - Dismiss risk
  - Open checklist
  - Confirm change
- [ ] Real-time updates (Firestore listeners on today's objects)
- [ ] Empty state ("Nothing needs attention today.")
- [ ] Manual add from Today (free text → extraction → review → commit)
- [ ] Daily view mode adaptation (morning/daytime/evening/weekend priority shifts)

### Deliverable
Full Today Command Center working. Parent opens the app and sees what needs to happen, what's at risk, and can execute the day.

---

## Phase 6 — Notifications & Polish

**Goal:** Proactive notifications bring the parent back at the right time.

### Tasks

- [ ] FCM setup (token registration, topic subscription per household)
- [ ] Notification types implementation:
  - Review needed
  - Change detected
  - Deadline risk
  - Owner gap
  - Preparation needed
  - Daily brief
- [ ] Cloud Tasks scheduling:
  - Morning brief (configurable time)
  - Evening reset (configurable time)
  - Deadline checks (every 15 min or event-driven)
  - Preparation reminders (event time minus prep window)
- [ ] Notification logic (Cloud Functions):
  - Priority evaluation (high/medium/low)
  - Grouping (by event, child, time window)
  - Suppression (completed, dismissed, snoozed, already acted on)
  - Deep-link payload (route to specific screen + object)
- [ ] Notification settings screen:
  - Toggle by category (review, changes, deadlines, owner gaps, prep, briefs)
  - Quiet hours configuration
  - Morning/evening brief timing
- [ ] Quiet hours enforcement
- [ ] Notification deep-linking (open correct screen on tap)

### Deliverable
Nabbo proactively notifies the parent when action is needed. Notifications are useful, grouped, timed well, and lead directly to the relevant action.

---

## Post-v1 Roadmap

After the 6 phases are complete and tested:

- Household memory / routine learning
- Multi-user support (co-parent, child, caregiver accounts)
- Advanced change detection (pattern-based)
- Weekly family brief
- Prep modes (morning launch, evening reset as focused views)
- Calendar export (optional, per event)
- Travel time estimation
- Notification escalation
- Per-child notification routing
- Analytics and household insights

---

## Timeline Estimate

| Phase | Scope | Estimated Duration |
|-------|-------|-------------------|
| Phase 1 | Foundation | 2–3 weeks |
| Phase 2 | Capture | 3–4 weeks |
| Phase 3 | Extraction | 2–3 weeks |
| Phase 4 | Review | 3–4 weeks |
| Phase 5 | Today | 2–3 weeks |
| Phase 6 | Notifications | 2–3 weeks |
| **Total** | **v1 complete** | **14–20 weeks** |

These estimates assume one developer working full-time. Parallel work on backend (Cloud Functions, Cloud Run) and frontend (Flutter) can compress the timeline significantly.

---

## Open Technical Questions

1. **State management** — Riverpod recommended. Confirm preference.
2. **Monorepo or multi-repo** — Single repo with `app/`, `functions/`, `services/` recommended for v1.
3. **Firebase project** — Need project name and billing account setup.
4. **Email domain** — Need to register and verify `nabbo.app` for inbound email.
5. **Vertex AI region** — Choose based on user base location (EU or US).
6. **Share extension data passing** — App Groups (iOS) and content providers (Android) for bridging to Flutter.
7. **Offline-first priority** — How much of the app should work offline? (Today view minimum, Review requires network for AI.)

# Development Rules

## Source of Truth

The following documents are the source of truth for Nabbo's product and technical requirements:

- `docs/02-product-requirements.md` — Product Requirements (v1 scope)
- `docs/03-product-loop.md` — Core Product Loop
- `docs/04-data-model.md` — Core Data Model (2 collections + household + members)
- `docs/05-ai-extraction.md` — AI Extraction Specification (prompt, change detection, multimodal)
- `docs/06-app-flow.md` — App Flow & Screen Map
- `docs/07-review-card.md` — Review Card Spec
- `docs/08-feed.md` — Feed Spec
- `docs/09-notification-strategy.md` — Notification Strategy
- `docs/10-technical-architecture.md` — Technical Architecture
- `docs/11-layouts-specs.md` — Layout Specifications (UI component designs)

## Rules

### 1. Follow Requirements Strictly

- Every code change MUST be traceable to a documented requirement.
- Do NOT implement features, behaviors, or flows that are not described in the requirements documents.
- Do NOT remove or alter existing functionality unless explicitly instructed and documented.

### 2. Conflict Resolution

- If the user provides instructions that CONTRADICT the requirements documents, I MUST:
  1. Inform the user of the contradiction
  2. Reference the specific document and section
  3. Wait for the user to confirm whether to update the requirements doc
  4. Only proceed after the requirements doc is updated
- The user and I work TOGETHER on updating requirements before implementing changes.

### 3. Always Update Specs Before Implementing

- EVERY feature change, behavior change, or new functionality MUST be documented in the relevant spec file BEFORE implementing the code.
- Update the spec docs first, then implement.
- If a change touches multiple spec files, update all of them.
- Spec docs must always reflect the CURRENT state of the app — not a past or future state.
- After implementing, verify specs still match the implementation.

### 4. No Undocumented Changes

- Do NOT add dummy data
- Do NOT change navigation structure without updating docs
- Do NOT rename screens/tabs without updating docs
- Do NOT alter the product loop without updating docs
- Do NOT change the data model without updating docs
- Do NOT change the AI extraction behavior without updating docs
- Do NOT change the Feed/Review/Edit UI without updating layout specs

### 5. Git & Deployment

- Do NOT push to git unless the user explicitly asks
- Do NOT run the app (simulator/web/device) unless the user explicitly asks
- Commit messages should reference which requirement/phase the change implements

### 6. Code Quality

- Every change must compile without errors before presenting to user
- Do NOT introduce regressions — check existing functionality is preserved
- Use the design system (AppColors, AppSpacing, nabbo_widgets) consistently
- Follow the established architecture (Riverpod, Freezed, feature-first)

### 7. Current App State

The app currently has:
- **Feed tab** — shows source messages (analyzing/failed/noAction) + items (pendingReview/confirmed/cancelled) grouped by date. Weather widget top-right. Swipe left to hide.
- **Review tab** — shows items with `status: pendingReview` with approve/edit actions
- **Settings tab** — household (name, timezone, language, location via Places), family members (with color + photo), notifications, account
- **Animated expandable FAB** with text/voice/image capture
- **AI extraction** via Gemini 2.5 Flash Cloud Function (text + multimodal image support)
- **Change detection** — AI detects updates/cancellations of existing items (action: create/update/cancel)
- **Recurrence** — items expand client-side, single occurrence cancellation via exceptions array
- **Member colors** — random on create, picker in edit, used in Feed child chips (photo fallback to color initial)
- **Email forwarding** via SendGrid → Cloud Run
- **Push notifications** on extraction + hourly deadline check
- **Auth persistence** — user stays signed in until manual sign out

### 8. Data Model (current)

- **2 Firestore collections per household:** `sourceMessages/` and `items/`
- **Item types:** event, task, deadline
- **Item statuses:** pendingReview, confirmed, completed, cancelled, hidden
- **Item actions:** create, update, cancel (for change detection)
- **Recurrence:** rule + exceptions array, expanded client-side
- **Family members:** name, role, color, photoUrl — stored in `members/` subcollection
- **Household:** name, timezone, language, city, emailAlias

### 9. Known Gaps (documented but not yet built)

- Risk detection (auto-generating risks from gaps)
- Source traceability (tap to see original message from feed item)
- Notification deep-linking
- Multi-language string translations
- iOS native share extension (currently using receive_sharing_intent plugin)
- History view (see hidden/completed items)

# Feed Spec (formerly "Today Command Center")

## Purpose

The Feed is the primary screen in Nabbo. It shows the household's chronological stream of items — from the moment something is captured through execution.

**It is not a calendar. It is not a task list. It is not a dashboard.**

It answers:

> What is happening in my family, and what needs attention?

---

## Architecture

The Feed reads from **two collections**:

```
households/{householdId}/sourceMessages/{id}   ← shows "Analyzing" state
households/{householdId}/items/{id}            ← shows all extracted/confirmed items
```

### Feed Query

```
1. Source messages where processingStatus in ['pending', 'processing']
   → Show as "Analyzing..." cards at top

2. Items where status in ['pendingReview', 'confirmed']
   → Show grouped by date, chronological
```

Completed and cancelled items are hidden from the main Feed (accessible via item detail or history).

---

## Core Principle

**Chronological and action-first.**

The parent sees everything grouped by date:
- What's happening today
- What's happening tomorrow
- What's coming up

Pending review items appear at the top with clear "Review" badges so the parent knows what needs their attention.

---

## Feed Structure

### Header
- Greeting (time-based: Good morning / Good afternoon / Good evening)
- "Your family feed"

### Content Sections (top to bottom)

1. **Analyzing** — Source messages being processed by AI (spinner + "Analyzing...")
2. **Needs Review** — Items with `status: pendingReview` (yellow badge)
3. **Today** — Confirmed items for today's date
4. **Tomorrow** — Confirmed items for tomorrow
5. **Upcoming** — Confirmed items for the next 4 weeks (grouped by date)

### Date Headers

Each date group has a pill-shaped header:
- "Today"
- "Tomorrow"
- "Wed, 9 Jul"
- etc.

---

## Feed Cards

### Card Content

| Element | Source |
|---------|--------|
| **Icon** | Based on item `type`: event (calendar), task (checkmark), deadline (clock) |
| **Title** | `item.title` |
| **Child** | `item.childName` shown as chip |
| **Owner** | `item.ownerName` shown as chip |
| **Subtitle** | Location, time, or contextual info |
| **Status badge** | Review / Active / Done / Cancelled |

### Card States

| Item Status | Card Appearance |
|-------------|----------------|
| Source analyzing | Blue tint, "Analyzing..." subtitle, spinner |
| `pendingReview` | Yellow tint, "Review" badge |
| `confirmed` | Normal card, "Active" badge |
| `completed` | Faded, "Done" badge |
| `cancelled` | Faded + strikethrough, "Cancelled" badge |

### Card Tap Behavior

| Item Type | Opens |
|-----------|-------|
| Source message (analyzing) | Nothing (still processing) |
| `pendingReview` item | Review Detail Screen (full fields, approve/edit/delete) |
| `confirmed` / `completed` / `cancelled` item | Item Detail Screen (full fields, edit/mark done/cancel) |

---

## Recurring Items

Recurring items are expanded **client-side** into virtual cards:

1. Read `recurrence` field: `{ frequency, dayOfWeek, startDate, endDate }`
2. Generate occurrence dates from `startDate` to min(`endDate`, now + 4 weeks)
3. Check `exceptions` array:
   - If `{ date, status: "cancelled" }` → skip that date
   - If `{ date, overrides: {...} }` → apply overrides to that card
4. Each occurrence renders as a separate card under its date header
5. Icon shows repeat indicator for recurring items

---

## Source Message Cards

While AI is processing, the source message itself appears in the Feed:

- Shows `originalContent` (truncated)
- Input method icon (text/voice/email/image/share)
- "Analyzing..." subtitle with blue tint
- Once AI completes: source card is **replaced** by the extracted items

Source messages with `processingStatus: completed` are hidden from Feed (their items are shown instead).

---

## Capture Flow (What the User Sees)

```
1. User captures text/voice/image
2. Card appears IMMEDIATELY in Feed: "Analyzing..."
3. 2-10 seconds pass (AI processing)
4. Card transforms into one or more items with "Review" badge
5. User taps → Review detail → Approve
6. Item becomes "Active" in Feed under its date
```

This gives immediate feedback that the capture worked, without waiting for AI.

---

## Empty State

> "Nothing in your feed yet."
> "Capture something to get started."

With a subtle prompt icon. No fake productivity suggestions.

---

## FAB (Floating Action Button)

Positioned bottom-right on Feed tab only.

**Closed state:** "+" icon (rotates 45° to "×" when open)

**Open state (speed dial):**
- 📝 Text — opens text capture sheet
- 🎤 Voice — opens voice capture sheet  
- 📷 Photo — opens image capture sheet

Labels appear beside each mini-FAB. Tap outside closes.

---

## Item Detail Screen (from Feed)

Full-screen view when tapping a confirmed/completed/cancelled item:

### Shows:
- Title (large)
- Type badge (Event / Task / Deadline)
- Status badge
- Summary (if exists)
- All fields: date, time, location, child, owner
- Additional extracted fields as key-value list
- Recurrence info
- "View original message" link (opens source)

### Actions:
- **Edit** — opens edit mode (inline field editing)
- **Mark done** → `status: completed`
- **Cancel** → `status: cancelled`
- **Assign owner** → pick parent/adult
- **View source** → shows linked source message

### Editing

Items are **always editable** at any lifecycle stage. Edit mode allows changing all fields. Save writes directly to the item document.

---

## Sorting Logic

```
1. Analyzing source messages (newest first) — TOP
2. Pending review items without date (newest first)
3. Pending review items with date (date ascending)
4. Confirmed items grouped by date (today first, then tomorrow, then future)
   Within each day: time ascending, undated items at top of their group
```

---

## Completion Behavior

When a user marks an item done or cancels it:
- Card fades in the Feed
- Remains visible briefly, then hidden on next refresh
- Accessible from item detail if user searches or navigates back

Fast and satisfying, but **not gamified**.

---

## Design Rules

- Clear, calm, chronological
- No dense dashboards or colorful clutter
- No motivational text or gamification
- No calendar-heavy layouts
- Make pending review items visually distinct (yellow tint)
- Analyzing items show clear progress (blue tint + spinner)
- Work well under pressure (quick scan, tap to act)
- Information must be **scannable**
- Show child name prominently — parents need to know WHO
- Date grouping helps parents plan ahead

---

## What Feed Does NOT Include (v1)

- Calendar grid view
- Departure time calculations
- Risk detection cards
- Change detection ("this may update X")
- Evening reset / tomorrow prep section
- Next action surfacing
- Owner gap alerts

These may be added in future versions. v1 Feed is a clean chronological stream with review + execution.

---

## Success Metrics

| Metric | What It Measures |
|--------|-----------------|
| Daily active households opening Feed | Daily relevance |
| Time from capture to review | Responsiveness |
| Items approved per session | Throughput |
| Tap-through rate on cards | Engagement |
| Repeat usage after 7 days | Sustained value |

The strongest signal: **whether parents open Nabbo when they receive a school message**.

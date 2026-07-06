# Today Command Center Spec

## Purpose

The Today Command Center is the main execution view in Nabbo. It's where approved family information becomes a clear daily operating plan.

**It is not a calendar. It is not a task list. It is not a dashboard.**

It answers one question:

> What needs to happen today, and what could be missed?

---

## Core Principle

**Action-first.**

- A normal calendar shows time → Nabbo shows **execution**
- A normal task app shows work → Nabbo shows **family readiness**

The parent should not scan a long list and interpret what matters. Nabbo organizes the day around decisions, preparation, and risk.

---

## Main Questions Today Answers

1. What is happening next?
2. When do we need to leave?
3. What must be brought?
4. What is due today?
5. What changed?
6. Who owns each action?
7. What has no owner?
8. What is at risk?
9. What is already done?
10. What should I prepare for tomorrow?

---

## Default Behavior

| State | What Opens |
|-------|-----------|
| Urgent review items pending | Home → directs to Review first |
| Review clear / no urgent items | Opens Today Command Center |
| Nothing exists | Empty Today state |

The product decides what needs attention — the parent doesn't choose between views.

---

## Page Structure (7 Zones)

### Zone 1: Today Status

Quick operational summary of the day.

**Examples:**
- "Light day. 2 events, no risks."
- "Busy day. 5 events, 2 deadlines, 1 missing owner."
- "High-pressure day. Pickup conflict at 17:00."

**Labels:** Clear, Normal, Busy, Needs attention, At risk

Generated from actual household objects, not generic motivational copy. Factual, not emotional.

---

### Zone 2: Next Action

The most important thing the parent should act on **now**.

**Examples:**
- "Sign Yara's permission form before school."
- "Pack Adam's blue jersey and size 4 ball."
- "Assign pickup owner for football training."
- "Pay €8 school trip fee by 18:00."
- "Leave for dentist appointment by 15:25."

Selected based on urgency, time sensitivity, owner gap, and risk.

**One primary action button:** Mark done / Assign owner / Open checklist / Set reminder / View source / Confirm change.

The parent should not have to decide what matters most. Nabbo surfaces it.

---

### Zone 3: Departure & Movement

Family logistics often fail around movement.

Each item shows:
- Event
- Family member
- Location
- Start time
- Suggested departure time
- Pickup/drop-off owner
- Required items
- Travel risk (if known)

**Example:**
> Football training, Adam, 18:30 at Sports Hall. Leave by 18:00. Pickup owner missing.

If travel time is unknown, say "Travel time not set" or "Add departure reminder?" — do not invent precision.

---

### Zone 4: Today Timeline

Approved events in chronological order. Vertical, compact.

Each event shows:
- Time
- Title
- Family member
- Location
- Owner
- Preparation status
- Risk marker (if needed)

Past events collapse or fade. Current and next events are easiest to see.

**The timeline is one part of the command center — not the whole product.**

---

### Zone 5: Checklist

What must be prepared today. Combines required items from events, tasks, routines, and extracted messages.

**Grouped by family member and event.**

**Example:**
```
Adam — Football Training:
☐ Water
☐ Blue jersey
☐ Size 4 ball
☐ Football boots

Yara — School Trip:
☐ Packed lunch
☐ Raincoat
☐ Signed form
```

**Item states:** Not ready / Ready / Not needed / Already handled / Owner missing

Supports fast marking. No heavy forms. No deep navigation.

---

### Zone 6: Risk & Change

Where Nabbo becomes different from a calendar. Shows what might fail.

**Risk types:**
- No owner assigned
- Deadline due today / overdue
- Changed time or location
- Unpaid payment
- Unsigned form
- Required item not ready
- Pickup conflict
- Missing location
- Contradictory message

Each risk includes:
- What is wrong
- Why it matters
- Suggested action
- Primary action button

**Example:**
> "Pickup owner missing. Adam has football at 18:30. Assign someone."

**Changes show old and new values:**
> "Training time changed from 17:00 to 18:30."

Only show items that need attention. Avoid noise.

---

### Zone 7: Evening Reset

Helps the parent prepare for tomorrow. Appears more prominently later in the day.

Shows:
- Tomorrow's first event
- Items to pack tonight
- Forms due tomorrow
- Payments due tomorrow
- Early departures
- Owner gaps
- Schedule conflicts

**Example:**
> "Tomorrow starts with swimming. Pack towel, goggles, shampoo, and snack tonight."

Family stress often starts the night before or early morning. Nabbo helps the parent act before the pressure window.

---

## Daily View Modes

The command center adapts by time of day:

| Time | Focus |
|------|-------|
| **Morning Launch** | School readiness, bags, lunch, forms, weather items, departure times, drop-offs |
| **Daytime** | Deadlines, pickups, changes, appointments, reminders |
| **After-School Run** | Activity logistics, transport, snacks, sports gear, owner assignments |
| **Evening Reset** | Tomorrow, packing, forms, payment deadlines, unresolved risks |
| **Weekend Mode** | Activities, travel, family plans, shopping, irregular schedules |

These are different priorities within the same view — not separate products.

---

## Object Priority Logic

| Priority | Items |
|----------|-------|
| **Highest** | Time/location changes for today, pickup/drop-off with no owner, deadlines due today, overdue forms/payments, required items for upcoming events, conflicting events, next departure |
| **Medium** | Tasks due today, checklists for later today, payments/forms due tomorrow, owner gaps for tomorrow |
| **Low** | Future events, routine suggestions, non-urgent checklist improvements, general notes |

Parents should not have to sort the day manually.

---

## Owner Visibility

Every task, event, payment, form, pickup, and checklist shows who owns it.

If no owner → **"Owner missing"**

Do not hide owner gaps. They are risk points.

**Examples:**
- "Form due today — owner missing"
- "Pickup at 17:30 — assigned to Hasan"
- "Packing checklist — assigned to Yara"

Ownership creates clarity, not blame. Tone stays neutral.

---

## Completion Behavior

Mark items done quickly:
- Mark done / Packed / Paid / Submitted / Handled / Not needed / Cancelled

Completed items collapse but remain available if needed. Nabbo stops reminding about them.

Fast and satisfying, but **not gamified**. This is not a productivity toy.

---

## Empty State

> "Today is clear. Nothing needs attention."

Optional prompt: "Nabbo a message when something comes in."

Do not fill with fake productivity suggestions. Empty means empty.

---

## Notification Connection

Notifications bring the parent to the relevant part of Today:
- "Pickup owner missing" → opens that risk
- "Pack football items" → opens the checklist
- "Training time changed" → opens the change card

Never dump the user on a generic home screen.

---

## Source Traceability

Every item in Today links back to its source when relevant.

- Form deadline → original email or screenshot
- Changed time → the message that caused the change

Nabbo should never make the parent wonder: "Where did this come from?"

---

## Manual Add from Today

Fast manual adding:
- Task, Reminder, Required item, Payment, Form, Event, Risk note

Free text is the default method. Nabbo processes it like any other input.

Should not become a full task form unless the parent chooses to edit details.

---

## Example Today View

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TODAY STATUS
Busy day. 4 events, 2 checklists, 1 missing owner.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

NEXT ACTION
→ Assign pickup owner for Adam's football training.
  [Assign Owner]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DEPARTURE & MOVEMENT
• Adam football training, 18:30, Sports Hall
  Leave by 18:00. Pickup owner missing.
• Yara piano lesson, 17:00, Music School
  Owner: Sara ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

TIMELINE
08:00  School drop-off
15:30  Dentist appointment
17:00  Piano lesson
18:30  Football training

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CHECKLIST
Adam — Football:
☐ Water
☐ Blue jersey
☐ Size 4 ball
☐ Football boots

Yara — Piano:
☐ Piano book
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

RISKS & CHANGES
⚠ Football time changed: 17:00 → 18:30
⚠ Pickup owner missing

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EVENING RESET
Tomorrow: school photo day.
→ White shirt needed.
→ Order form due Friday.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

This is not a calendar view. It is a **household execution view**.

---

## Design Rules

- Clear, calm, practical
- No dense dashboards or colorful clutter
- No motivational text or gamification
- No calendar-heavy layouts
- Make priority visible
- Work well under pressure (leaving the house, packing, coordinating pickup)
- Information must be **scannable**
- Some things matter now, some can wait — make that distinction visible

---

## Success Metrics

| Metric | What It Measures |
|--------|-----------------|
| Daily active households opening Today | Daily relevance |
| Sessions during morning/after-school/evening windows | Real-moment usage |
| Checklist items marked complete | Preparation execution |
| Owner gaps resolved from Today | Responsibility clarity |
| Risks resolved before deadline | Failure prevention |
| Source views opened from Today | Trust verification |
| Notifications that lead to action | Notification quality |
| Repeat usage after 7 days | Sustained value |

The strongest signal: **whether parents use Today during real pressure moments**.

---

## Failure Modes

The Today Command Center fails if:
- It becomes a calendar
- It shows too much
- The parent has to interpret everything manually
- Risks are noisy
- Owner gaps are hidden
- Checklists are buried
- Source messages are not traceable
- The parent opens the app and still thinks "What do I need to do?"

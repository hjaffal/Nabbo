# Review Card Spec

## Purpose

The Review Card is the first place where the parent sees what Nabbo understood. This is the **trust moment**.

Nabbo receives messy information, extracts operational meaning, and presents it back in a structured card. The parent verifies quickly, corrects mistakes, assigns ownership, and approves into the household plan.

**If the parent has to rebuild the message by hand, the product has failed.**

---

## Core Principle

The Review Card separates three things clearly:

1. **What the source says** (original content)
2. **What Nabbo extracted** (structured fields)
3. **What Nabbo suggests** (inferred actions)

> Parents can tolerate AI uncertainty. They will not tolerate hidden guessing.

---

## Card Structure (6 Zones)

### Zone 1: Source Indicator
Where the item came from: WhatsApp, forwarded email, screenshot, voice note, free text, PDF.

### Zone 2: Operational Summary
Short, plain-English summary of what Nabbo found. Action-focused, not a generic recap.

### Zone 3: Extracted Fields
Structured details Nabbo detected (with confidence labels).

### Zone 4: Uncertainty & Confidence
Fields with low confidence clearly marked.

### Zone 5: Suggested Actions
What Nabbo recommends: approve, assign owner, add checklist, set reminder, resolve risk.

### Zone 6: Source Message
Expandable original source for verification.

---

## Required Card Elements

- Source type
- Affected family member
- Detected object type
- Operational summary
- Key extracted fields
- Confidence / uncertainty markers
- Suggested next step
- Primary action button
- Secondary actions
- Source preview + full source access
- Review status

---

## Field Display by Object Type

| Object | Fields Shown |
|--------|-------------|
| **Event** | Name, family member, date, time, location, required items, owner, related tasks, detected change |
| **Task** | Name, family member, due date, owner, related event, priority, reminder suggestion |
| **Deadline** | Title, due date/time, related task, owner, urgency |
| **Checklist** | Title, family member, related event, items, owner, needed by |
| **Form** | Name, required action, due date, owner, submission method, attachment |
| **Payment** | Title, amount, currency, due date, payment method, owner, related event |
| **Change** | What changed, previous value, new value, affected event/task, impact |
| **Risk** | Title, why it matters, affected person, related object, suggested action, severity |

---

## Confidence Display

Do NOT show numeric confidence to parents (no "87% confidence").

Use simple labels:

| Label | Meaning |
|-------|---------|
| **Clear** | Explicitly stated in source |
| **Check this** | Likely but needs verification |
| **Missing** | Not found |
| **Suggested** | Inferred from context |

**Examples:**
- Date: Friday — *Clear*
- Location: Sports Hall — *Check this*
- Owner — *Missing*
- Add water bottle to checklist — *Suggested*

---

## Uncertainty Rules

If Nabbo is uncertain, show it beside the field:
- "Location may be Main Hall"
- "Child not detected"
- "Time unclear"
- "Owner missing"
- "This may update an existing event"

Uncertain fields should be **editable directly from the card**.

---

## Source Message Rules

- Original source always available
- Short preview by default, full source expandable
- For emails: sender, subject, date, relevant excerpt, attachments
- For screenshots/images: image preview + extracted text
- For voice: transcript + audio reference
- For WhatsApp/messages: shared text or screenshot

**The source message is the trust anchor.**

---

## Primary Actions

Every card has one clear primary action (context-dependent):

| Card Context | Primary Action |
|-------------|---------------|
| Standard extraction | Approve |
| Low-confidence extraction | Review and approve |
| Missing owner | Assign owner |
| Detected change | Confirm change |
| Risk | Resolve |
| Form | Add task |
| Payment | Add payment reminder |

---

## Secondary Actions

- Edit
- Dismiss
- Snooze
- Assign
- Mark as handled
- Split item
- Merge with existing
- View source
- Create routine

Secondary actions sit in a compact menu — do not crowd the card.

---

## Action Behaviors

### Approve
Commits to household plan. Creates/updates relevant objects. Shows confirmation with any remaining issues visible.

### Edit
Fast, inline. Editable fields: family member, date, time, location, owner, due date, required items, amount, payment method, form action, reminder, checklist items.

**If editing feels like data entry, Nabbo loses.**

### Dismiss
Removes from review queue. Optional reason: not relevant, duplicate, already handled, wrong extraction, spam/noise, no action needed. Recoverable briefly.

### Snooze
Delays decision. Options: later today, tomorrow, this weekend, next week, custom. Card returns at selected time. Remains findable.

### Assign
Choose owner: primary parent, second parent, child, caregiver, grandparent, unassigned. Assignment possible during review, not just after approval.

### Mark Handled
Item is real but already done (already paid, already returned, already packed). Different from dismiss. Recorded as completed.

### Split
When one card contains too much (e.g., school email with trip + payment + form + packing list). Creates separate cards or objects. Suggested when card includes many action types.

### Merge
When new info appears to update something existing. Shows: "This may update Adam's football training." Options: confirm change, keep original, create separate, dismiss. Critical for avoiding duplicates.

---

## Special Card Types

### Change Review Card

Shows:
- Existing information
- New information
- Source of new info
- Impact
- Actions: Confirm change / Keep original / Create separate / Dismiss

**Example:**
> Training time changed.
> Previous: Friday 17:00
> New: Friday 18:30
> Impact: Departure time and checklist reminder may need updating.

---

### Risk Review Card

Calm and action-focused. No panic.

**Example:**
> "Pickup has no owner."
> Why: Adam's football training starts at 18:30.
> Suggested: Assign pickup owner.
> Actions: Assign / Snooze / Dismiss

Only show risks when action is useful. Too many = noise.

---

## Review Queue Priority

**High priority:**
- Due today / tomorrow
- Time or location change
- Missing pickup owner
- Payments / forms due soon
- Conflicting events
- Required items for today

**Low priority:**
- Future events with complete information
- Routine suggestions
- Non-urgent checklist suggestions
- General notes

---

## Review Card Quality Bar

A good Review Card passes five tests:

1. ✅ Parent understands the item in **5 seconds**
2. ✅ Parent can verify the source **quickly**
3. ✅ Uncertainty is **visible**
4. ✅ Next action is **obvious**
5. ✅ Approval does not require **manual reconstruction**

---

## Examples

### School Trip Card

```
Source: Forwarded school email
Family member: Adam — Clear

Summary: Adam has a school trip to the science museum on Friday. He needs
packed lunch, water bottle, and raincoat. Permission form due Wednesday.
Payment of €8 required.

Extracted:
  Event: Science museum trip — Clear
  Date: Friday — Clear
  Location: Science museum — Clear
  Required: packed lunch, water bottle, raincoat — Clear
  Form: permission form, due Wednesday — Clear
  Payment: €8 via school portal — Clear
  Owner: Missing

Suggested: Add event, create trip checklist, add form deadline,
add payment task, assign owner.

[Approve All]  [Edit] [Split] [Assign] [Snooze] [Dismiss]
```

### Sports Change Card

```
Source: Shared WhatsApp message
Family member: Adam — Clear

Summary: Football training moved to Friday at 18:30 at Sports Hall.
Bring blue jersey and size 4 ball.

Change detected:
  Existing: football training Friday at 17:00
  New time: 18:30
  New location: Sports Hall

Required items: blue jersey, size 4 ball
Owner: Missing

Suggested: Update time, update location, add items to checklist,
assign packing owner.

[Confirm Change]  [Keep Original] [Create Separate] [Edit] [Dismiss]
```

### Free Text Card

```
Source: Typed note

Summary: Yara needs €5 for school tomorrow.

Extracted:
  Family member: Yara — Clear
  Payment: €5 — Clear
  Due: tomorrow — Clear
  Task: give Yara €5 — Suggested
  Owner: Missing

[Add Reminder]  [Assign] [Mark Handled] [Edit] [Dismiss]
```

---

## Design Rules

- Clean, compact, decisive
- No technical AI details shown to user
- No raw JSON or confidence numbers
- Don't hide source material
- Don't bury uncertain fields
- Don't make editing feel like form filling
- Don't make every card look the same if the decision type differs
- Don't treat changes as normal events
- Don't allow important actions to enter the plan without review

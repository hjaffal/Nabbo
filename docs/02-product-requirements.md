# Product Requirements Document (v1)

## Purpose

This defines the first buildable release of Nabbo. The goal is to prove the core behavior:

> Do not remember it. Nabbo it.

A parent should be able to send messy family information into Nabbo, see what the system understood, verify the extracted details, and turn them into clear household actions.

---

## What This Release Must Prove

1. Parents can capture family signals quickly
2. Nabbo can extract useful household meaning
3. Parents can verify the extraction without heavy effort
4. Approved items become actionable
5. The Today view gives enough value to bring parents back

---

## Core Product Loop (v1)

```
Capture → Understand → Review → Approve/Correct → Commit to Plan → Use Today
```

The loop is successful when the parent feels that sending something to Nabbo is easier than remembering it.

---

## Supported Input Methods

### Mobile Share

Share content into Nabbo from iOS or Android:
- Plain text, copied message text
- Screenshots, images
- PDFs, documents
- Shared content from WhatsApp, Messages, school apps, email apps, browsers

The system preserves the original source content.

### Email Forwarding

Each household gets a unique Nabbo email alias. The parent forwards school emails, club emails, activity messages, newsletters, booking confirmations, payment reminders, and form requests.

The forwarded email remains attached as the source.

### Free Text / Voice Inside the App

The parent opens Nabbo and types or speaks a quick note:
- "Adam has football Friday at 18:30, bring blue jersey."
- "Yara needs €5 tomorrow."
- "Dentist appointment Tuesday at 4, pick Adam up early."

Voice input is transcribed before extraction.

---

## Capture Requirements

Capture must be fast. The parent should send something to Nabbo with minimal friction.

| Requirement | Detail |
|-------------|--------|
| Accept shared content from mobile share sheets | ✅ |
| Accept forwarded emails to unique alias | ✅ |
| Accept typed free text | ✅ |
| Accept voice input (if feasible in v1) | ✅ |
| Create Source Message record for every input | ✅ |
| Show processing status | ✅ |
| Notify when review items are ready | ✅ |

**Success:** Parent captures an input in under 10 seconds.
**Failure:** Parent must manually copy details into multiple fields before Nabbo can process.

---

## Extraction Requirements

Nabbo must extract **operational meaning**, not just summarize text.

### Detected Fields

- Affected family member
- Event
- Task
- Deadline
- Required item / checklist item
- Form
- Payment
- Location
- Owner (if stated)
- Change (if it updates existing information)
- Risk (if something is missing, urgent, or unassigned)
- Uncertainty
- Source reference

### Confidence Levels

Every extracted field includes confidence:
- **Clear** — explicitly stated
- **Check this** — likely but not fully explicit
- **Missing** — not found
- **Suggested** — inferred from context

### Rules

- Separate facts from suggestions
- Never silently guess important fields (child, date, time, location, deadline, payment amount, form action, owner)
- If a field is unclear, mark it clearly

---

## Review Inbox Requirements

After extraction, items appear in the Review Inbox — the trust layer.

- Show pending extracted items as Review Cards
- Each card shows: source, summary, extracted fields, uncertainty, suggested actions
- Original source always visible or expandable
- User can: approve, edit, dismiss, snooze, assign owner, mark handled, split, merge

### Urgency Priority

Highest priority items:
- Due today / tomorrow
- Time or location change
- Payment or form due soon
- Missing owner for pickup or deadline
- Required item for today

---

## Review Card Requirements

Each Review Card answers:
1. What did Nabbo find?
2. Who is affected?
3. What needs to happen?
4. When does it matter?
5. What is uncertain?
6. What does the parent need to do next?

### Required Elements

- Source type
- Affected family member
- Object type
- Operational summary
- Extracted fields with confidence labels
- Suggested action
- Primary action button
- Secondary actions menu
- Source preview / full source access

### Primary Actions

- Approve
- Review and approve
- Confirm change
- Assign owner
- Add reminder
- Resolve risk

### Secondary Actions

- Edit, Dismiss, Snooze, Assign, Mark handled, Split, Merge, View source

---

## Edit Requirements

Editing must be lightweight. Editable fields:

- Family member, event title, date, time, location
- Task title, due date, owner
- Required items, payment amount, payment method
- Form action, reminder time, checklist items

The product must avoid forcing the parent into a long form for simple corrections.

---

## Approval Requirements

When approved, Nabbo commits the object into the household plan. May create:
- Event, Task, Deadline, Required item, Checklist, Form, Payment, Reminder, Change, Risk, Owner assignment

After approval, show short confirmation:
> "Added to Friday. Checklist created. Owner still missing."

Approval must not hide unresolved issues.

---

## Dismiss, Snooze & Mark Handled

### Dismiss
Removes from Review Inbox with optional reason (not relevant, duplicate, already handled, wrong extraction, no action needed, spam/noise). Recoverable for a short period.

### Snooze
Delays review decision. Options: later today, tomorrow, this weekend, next week, custom date. Returns at selected time.

### Mark Handled
For items that are real but already done (payment already paid, form already returned, item already packed). Different from dismiss.

---

## Today View Requirements (v1)

Simple but action-first. Not a calendar grid.

### Sections

| Section | Shows |
|---------|-------|
| Next action | Most important thing to handle now |
| Today's events | Approved events for today |
| Tasks due today | Actions needed today |
| Required items | Things to bring/pack/prepare |
| Forms due soon | Documents needing action |
| Payments due soon | Money actions needed |
| Owner gaps | Actions with no assigned owner |
| Changes | Updated times, locations, requirements |
| Risks | Potential failure points |

Each item shows: affected family member, time/deadline, owner, status, source access, action button.

---

## Owner Requirements

Every action should have an owner or be marked unassigned.

**Owner states (v1):** Assigned, Unassigned, Completed

**Supported owner labels:**
- Primary parent
- Other parent / adult
- Child
- Unassigned

Full invitation and account permission logic comes later.

---

## Source Traceability

Every extracted and approved item must link back to the original source. The parent must be able to view the original message, email, screenshot, image, PDF, transcript, or free text note.

**No committed item should exist without a source** (unless manually created by the user).

---

## Change Detection (v1)

If a new input appears to update an existing approved event or task, flag it.

Detected changes:
- Time, date, location changed
- Required item added
- Deadline changed
- Event cancelled
- Payment changed
- Form requirement added

The Review Card shows previous value and new value. User can: confirm change, keep original, create separate item, or dismiss.

---

## Risk Detection (v1)

Risks generated when there is a clear execution gap:
- No owner assigned
- Deadline due today/tomorrow
- Payment or form due soon
- Required item for today not marked ready
- Time/location change needs confirmation
- Missing date, time, or family member

Do not create risk spam. Each risk has a suggested action.

---

## Notification Requirements

Notifications should be useful, not noisy.

**Good:** "Training time changed. Review needed."
**Bad:** "Nabbo processed your content."

Types: item ready for review, urgent item needs review, deadline due soon, change detected, owner missing for urgent action, required item needed today.

Notifications deep-link to the relevant Review Card or Today item.

---

## Account & Household (v1)

Minimum setup:
- Household name
- Primary parent name
- Children names
- Optional second adult name
- Timezone
- Default language
- Unique Nabbo email alias

Does not need full multi-user authentication for this release.

---

## Privacy Requirements

- Original source messages stored securely
- User data not used for public examples without consent
- Test/production data not exposed across households
- User can delete source messages and extracted items
- Clear explanation that shared/forwarded content is processed for household actions
- No manual human review in production without disclosure and consent

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Weekly captures per active household | ≥ 5 |
| Households capturing ≥ 3 items in first 7 days | ≥ 40% |
| Extracted items approved or edited+approved | ≥ 60% |
| Approved items requiring major correction | < 25% |
| Households opening Today ≥ 3 days/week | ≥ 50% |
| Households capturing after day 3 | ≥ 50% |
| Owner gaps / due items resolved before deadline | ≥ 30% |

---

## v1 Scope Summary

### Included

- Mobile share capture
- Email forwarding capture
- Free text capture
- Voice input (if feasible)
- Source message storage
- AI extraction
- Structured Review Cards
- Approve, Edit, Dismiss, Snooze, Assign, Mark handled
- Basic split and merge (if feasible)
- Today view
- Basic change detection
- Basic risk detection
- Basic notifications
- Household and family member setup
- Source traceability

### Excluded

- Full calendar sync
- Direct app integrations
- WhatsApp monitoring
- School portal integrations
- Full co-parent accounts
- Child / caregiver accounts
- In-app chat
- Payment processing
- Monthly calendar grid
- Advanced household memory
- Advanced routines
- Advanced travel time automation

---

## Key Risks

1. **Capture friction** — If capture is slower than remembering, parents won't use Nabbo
2. **Extraction trust** — If Nabbo gets important details wrong too often, users stop relying on it
3. **Review burden** — If review feels like manual data entry, the product fails
4. **Weak Today value** — If Today doesn't help during real pressure moments, users won't come back
5. **Over-scoping** — If this release tries to build the full family operations system, it becomes slow and unfocused
6. **Privacy sensitivity** — Parents share personal family data; trust must be protected from the start

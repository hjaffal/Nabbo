# Extraction Schema

## Purpose

Nabbo receives messy family signals and must convert them into structured household objects that can be reviewed, corrected, assigned, tracked, reminded, prepared, changed, and completed.

The extraction layer is **not a summary engine**. A summary tells the parent what the message says. Nabbo must tell the parent **what needs to happen**.

The output should be action-first, trust-aware, and reviewable.

---

## Supported Input Types

| Category | Examples |
|----------|----------|
| Mobile share | WhatsApp messages, SMS, school app messages, copied text, screenshots, images, PDFs, documents |
| Forwarded email | School emails, activity updates, newsletters, forms, booking confirmations, payment requests |
| Free text | Short typed notes ("Yara needs €5 tomorrow") |
| Voice input | Spoken reminders, verbal notes, dictated family logistics |
| Image-based | Screenshots, photos of paper forms, school letters, timetables, posters, payment slips |

Each input must preserve the original source.

---

## Standard Extraction Output

Every input produces a structured result:

```
source_message_id
input_type
detected_language
extracted_text
operational_summary
affected_family_member
detected_objects[]
confidence_summary
uncertain_fields[]
suggested_actions[]
review_requirement
source_traceability
```

A single input may produce zero, one, or many detected objects.

---

## Extracted Object Types

### Event

Something scheduled at a specific date, time, or period.

**Fields:**
- Event title, Affected family member
- Start/end date and time
- Location, Event category (School, Sports, Medical, Activity, Travel, Birthday, Family, Appointment)
- Related: required items, tasks, deadline, form, payment
- Owner, Recurrence
- Change from existing event
- Confidence per field

**Rule:** Do not create an event unless there is a clear scheduled activity or commitment.

---

### Task

An action someone must complete.

**Fields:**
- Task title, Description
- Affected family member, Owner
- Due date/time
- Related: event, form, payment, source message
- Priority, Completion criteria
- Confidence per field

**Rule:** Create a task when the input requires someone to do something. Always has an owner or is marked unassigned.

---

### Deadline

A date/time by which something must be done.

**Fields:**
- Deadline title, Due date/time
- Affected family member
- Related: task, form, payment, event
- Owner, Urgency, Reminder suggestion
- Confidence per field

**Rule:** If the source says "by," "before," "due," "submit by," "pay by," "return by" — create a deadline. A deadline without a linked action is weak; suggest the related task.

---

### Required Item

Something to bring, pack, prepare, buy, print, sign, or make available.

**Fields:**
- Item name, Quantity
- Affected family member
- Needed by date/time
- Related: event, checklist
- Owner, Category (Clothing, Sports gear, Food, Drink, Document, Money, Medicine, Device, School material)
- Required or suggested
- Confidence

**Rule:** If the source says "bring," "pack," "wear," "prepare," "take," "do not forget" — extract required items.

---

### Checklist

A grouped set of required items or preparation actions.

**Fields:**
- Checklist title, Affected family member
- Related: event
- Items, Owner, Date
- Type (Morning launch, Evening reset, School trip, Sports activity, Medical, Travel, Weekend, Event prep)
- Generated from source or routine
- Confidence

**Rule:** Create a checklist when the input includes more than one required item or preparation step.

---

### Form

A document or approval needing action.

**Fields:**
- Form title, Affected family member
- Required action (Read, Sign, Print, Complete, Upload, Submit online, Return physically, Bring on the day)
- Due date, Submission method
- Related: event
- Owner, Attachment reference
- Confidence

**Rule:** If the input references a permission slip, consent form, registration, medical form, school form, or attached document requiring action — create a form object and usually a related task.

---

### Payment

A money-related action.

**Fields:**
- Payment title, Amount, Currency
- Affected family member
- Due date, Payment method, Payment link
- Related: event
- Owner, Confidence

**Rule:** If the input mentions an amount, fee, contribution, registration cost, portal payment, bank transfer, cash amount, or payment link — create a payment object.

---

### Location

A place linked to an event, pickup, drop-off, activity, task, or routine.

**Fields:**
- Location name, Address (if available)
- Type
- Related: event
- Affected family member
- Pickup/drop-off relevance
- Confidence, Change from previous location

**Rule:** If the source mentions a place, extract it. If the place changes an existing event, create a change object.

---

### Change

A detected difference between new information and existing household data.

**Fields:**
- Related object
- Change type (Date, Time, Location, Event cancelled, Required item added/removed, Deadline, Payment, Form requirement, Owner)
- Previous value, New value
- Source message, Affected family member
- Impact level, Confidence

**Rule:** If new input contradicts or updates existing approved household information, create a change object. Compare against approved data, not just other pending items.

---

### Risk

A possible household failure point.

**Fields:**
- Risk title, Description
- Type (No owner, Deadline near, Deadline overdue, Conflicting events, Changed location/time, Item not packed, Payment unpaid, Form incomplete, Missing/contradictory info, Travel time risk)
- Affected family member, Related objects
- Severity, Suggested action
- Owner, Confidence

**Rule:** Create a risk when extracted information suggests something may be missed, unclear, unassigned, conflicting, or time-sensitive. Do not create fake risks for everything.

---

### Routine Suggestion

A possible recurring pattern.

**Fields:**
- Routine title, Affected family member
- Frequency, Common location, Common required items
- Default owner, Confidence, Evidence
- Suggested action

**Rule:** Do not create routines too early. Suggest only after repeated verified patterns.

---

## Confidence Scoring

**Field-level** confidence, not just item-level:

| Level | Meaning |
|-------|---------|
| **High** | Clearly stated in the source |
| **Medium** | Likely but not fully explicit |
| **Low** | Inferred or ambiguous |
| **Unknown** | Missing |

Important fields requiring confidence:
- Affected family member
- Date, Time, Location
- Action, Deadline
- Required items
- Payment amount
- Form requirement
- Owner
- Change detection

**Nabbo should never hide uncertainty.**

---

## Fact / Suggestion / Inference Rules

| Type | Definition | Example |
|------|-----------|---------|
| **Fact** | Explicitly stated in the source | "Training is Friday at 18:30" |
| **Suggestion** | Recommended based on context or household memory | "Add football boots if this is a football routine" |
| **Inference** | Likely interpretation, not directly stated | "May affect Adam if Adam is the only child with football" |

The parent must be able to see the difference. This is critical for trust.

---

## Review Requirement Rules

### Review Required When:
- Item creates or changes an event
- Item creates a deadline
- Item creates a payment
- Item creates a form action
- Item affects pickup, drop-off, location, or time
- Item has low-confidence fields
- Item creates a risk
- Item assigns an owner
- Item contradicts existing information

### Review May Be Optional When:
- User manually types a clear instruction
- Item matches a trusted routine
- Confidence is high and impact is low

Even then, allow quick undo.

---

## Parent Review Actions

For each extracted item, the parent can:
- Approve
- Edit
- Dismiss
- Snooze
- Assign owner
- Mark as already handled
- Split the item
- Merge with existing item
- View source message
- Create routine from item

Review must be fast. If it feels like manual data entry, the product fails.

---

## Extraction Examples

### Example 1: School Trip Email

**Input:**
> "Dear parents, Adam's class will visit the science museum on Friday. Children must bring a packed lunch, water bottle, and raincoat. Please submit the permission form by Wednesday and pay €8 through the school portal."

**Output:**

| Object | Details |
|--------|---------|
| Event | Science museum trip, Adam, Friday, high confidence |
| Required Items | Packed lunch, water bottle, raincoat — high confidence |
| Form | Permission form, submit, due Wednesday — high confidence |
| Payment | €8, school portal — high confidence |
| Tasks | Submit permission form; Pay €8; Pack trip items |
| Risks | Form due soon; Payment has no owner; Packing has no owner |

---

### Example 2: WhatsApp Sports Update

**Input:**
> "Training moved to Friday 18:30 at Sports Hall. Bring blue jersey and size 4 ball."

**Output:**

| Object | Details |
|--------|---------|
| Event update | Training, Friday, 18:30, Sports Hall |
| Change | Time/location changed (if existing event differs) |
| Required Items | Blue jersey, size 4 ball |
| Checklist | Training checklist |
| Risks | Required items need owner |

---

### Example 3: Free Text

**Input:**
> "Yara needs €5 tomorrow for school."

**Output:**

| Object | Details |
|--------|---------|
| Payment | €5, Yara, due tomorrow |
| Task | Give Yara €5, owner unassigned |
| Risk | Payment action has no owner |

---

### Example 4: Voice Note

**Input:**
> "Remind me that Adam has dentist next Tuesday at four, and I need to pick him up early from school."

**Output:**

| Object | Details |
|--------|---------|
| Event | Dentist appointment, Adam, next Tuesday, 16:00 |
| Task | Pick Adam up early from school, owner: user |
| Risk | Pickup timing needs confirmation |

---

### Example 5: Screenshot

**Input (extracted text):**
> "Reminder: Class photo day is Monday. Students must wear white shirt. Order forms due Friday."

**Output:**

| Object | Details |
|--------|---------|
| Event | Class photo day, Monday |
| Required Item | White shirt |
| Form | Order form, deadline Friday |
| Task | Return order form |
| Risk | Form deadline due soon (if Friday is near) |

---

## AI Behavior Rules

- Extract actions, not just summaries
- Preserve the source
- Identify the affected family member or mark as uncertain
- Create multiple objects when the input contains multiple operational needs
- Separate facts from suggestions
- Show uncertain fields
- Do not guess silently
- Do not create fake precision from vague language
- Do not auto-assign owners unless the source or household routine supports it
- Do not create reminders without actions
- Detect changes against approved household data
- Avoid over-alerting
- Prefer clear review over hidden automation

---

## The Five Questions

Every extraction should answer:

1. **Who** is affected?
2. **What** needs to happen?
3. **When** does it matter?
4. **Who** owns it?
5. **What** could be missed?

If Nabbo cannot answer one of these, it should show the gap clearly.

The goal is not perfect AI. The goal is **trusted household execution**.

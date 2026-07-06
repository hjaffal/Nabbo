# Core Data Model

## Core Principle

Nabbo is **action-first, not calendar-first**.

A calendar event is only one possible output. The product must also understand tasks, deadlines, required items, forms, payments, changes, risks, owners, routines, and source messages.

The core question is not "When is this happening?" — it's **"What does this mean for the household, and what needs to happen next?"**

---

## Object Overview

| # | Object | Purpose |
|---|--------|---------|
| 1 | Household | Top-level container for one family unit |
| 2 | Family Member | Any person connected to the household |
| 3 | Source Message | Raw input sent into Nabbo |
| 4 | Extracted Item | Nabbo's first structured interpretation (pre-review) |
| 5 | Decision Status | What the user did with an extracted item |
| 6 | Event | Something scheduled at a specific time |
| 7 | Task | An action that needs to be completed |
| 8 | Deadline | A time-sensitive requirement |
| 9 | Required Item | Something to bring, pack, prepare, buy, print, sign |
| 10 | Checklist | Grouped set of required items or preparation actions |
| 11 | Form | Document/approval to read, sign, complete, submit |
| 12 | Payment | Money-related action |
| 13 | Location | Place linked to an event, task, or routine |
| 14 | Owner | Person responsible for an action |
| 15 | Reminder | Prompt to act at the right time |
| 16 | Change | Detected difference between new and existing info |
| 17 | Risk | Potential household failure point |
| 18 | Routine | Repeated family pattern Nabbo can learn |
| 19 | Household Plan | Current operational view (daily/weekly) |
| 20 | Completion | Tracks whether something has been resolved |

---

## Object 1: Household

The top-level container. All people, messages, actions, routines, plans, risks, and history belong to a household.

**Key Fields:**
- Household ID
- Household name
- Primary user
- Members
- Timezone
- Default language
- Notification preferences
- Shared Nabbo email alias
- Household routines
- Household locations
- Status

---

## Object 2: Family Member

Any person connected to the household.

**Key Fields:**
- Member ID, Name, Role, Age group
- Relationship to household
- Contact method, Permissions
- Default responsibilities
- Linked routines
- Color / visual identifier
- Status

**Roles:** Primary parent, Secondary parent, Child, Caregiver, Grandparent, Babysitter, Other trusted person

---

## Object 3: Source Message

The raw input sent into Nabbo — the **trust anchor**.

**Key Fields:**
- Source message ID, Household ID
- Submitted by
- Input method (mobile share, email forwarding, free text, voice, image, screenshot, PDF)
- Original content, Attachment type
- Source app or channel
- Received / processed timestamps
- Language, Extracted text
- Processing status
- Linked extracted objects
- Confidence summary, Privacy status

> The source message must always allow the parent to see where an extracted action came from.

---

## Object 4: Extracted Item

Nabbo's first structured interpretation — sits in the review layer until the parent decides.

One source message can create **multiple** extracted items.

**Key Fields:**
- Extracted item ID, Source message ID, Household ID
- Affected family member
- Item type (Event, Task, Deadline, Required item, Payment, Form, Location update, Change, Risk, Routine suggestion)
- Extracted summary
- Detected: date, time, location, action, required items, deadline, payment, form, owner, urgency, change, risk
- Confidence level, Uncertain fields
- Suggested next step
- Review status

---

## Object 5: Decision Status

Tracks what the user did with an extracted item.

**Key Fields:**
- Decision ID, Extracted item ID
- Status (Pending review, Approved, Edited and approved, Dismissed, Snoozed, Assigned, Already handled, Needs clarification)
- Decision made by, timestamp
- Edited fields, Dismissal reason, Snooze date, Notes

---

## Object 6: Event

Something scheduled at a specific time or period.

**Key Fields:**
- Event ID, Household ID, Title
- Affected family member
- Start/end date and time
- Location, Owner
- Related: source message, tasks, checklist, required items, payment, form
- Recurrence, Confidence level
- Change history, Reminder settings
- Status (Pending, Confirmed, Changed, Cancelled, Completed, Missed)

> Many family messages contain events, but the event alone is not enough. The value comes from linking the event to preparation, ownership, risks, and changes.

---

## Object 7: Task

An action that needs to be completed. May or may not be linked to an event.

**Key Fields:**
- Task ID, Household ID, Title, Description
- Affected family member, Owner
- Due date/time, Priority
- Related: event, source message, form, payment, checklist
- Completion status, Reminder settings
- Status (Open, Assigned, In progress, Completed, Dismissed, Overdue, Blocked)

> "Sign the form," "pay €10," "pack blue jersey," "reply to teacher" — these are tasks, not events.

---

## Object 8: Deadline

A time-sensitive requirement.

**Key Fields:**
- Deadline ID, Household ID, Title
- Due date/time
- Affected family member, Owner
- Related: task, form, payment, event, source message
- Urgency level, Reminder schedule
- Status (Upcoming, Due today, Overdue, Completed, Dismissed)

---

## Object 9: Required Item

Something that must be brought, prepared, packed, bought, printed, signed, or available.

**Key Fields:**
- Required item ID, Household ID
- Item name, Quantity
- Affected family member
- Related: event, checklist, source message
- Owner, Needed by date/time
- Packed status
- Category (Clothing, Sports gear, School material, Food/drink, Document, Money, Medicine, Device, Other)
- Recurring item flag, Suggested by system, Confidence

---

## Object 10: Checklist

Grouped set of required items or preparation actions.

**Key Fields:**
- Checklist ID, Household ID, Title
- Type (Morning launch, Evening reset, Sports activity, School trip, Weekend plan, Travel, Daily departure, Event preparation)
- Affected family member
- Related: event, routine
- Items, Owner, Date
- Completion status
- Created manually or automatically

---

## Object 11: Form

A document or approval that needs action.

**Key Fields:**
- Form ID, Household ID, Title
- Affected family member, Source message
- Related: event, deadline
- Owner, Required action (Read, Sign, Print, Upload, Return to school, Submit online, Bring physically)
- Submission method, Due date
- Status (Not started, In progress, Completed, Submitted, Overdue, Dismissed)
- Attachment, Reminder settings

---

## Object 12: Payment

A money-related action.

**Key Fields:**
- Payment ID, Household ID, Title
- Amount, Currency
- Affected family member
- Related: event, source message, deadline
- Owner, Payment method, Payment link
- Due date
- Status (Pending, Paid, Overdue, Dismissed, Unknown)

---

## Object 13: Location

A place linked to events, tasks, pickups, drop-offs, schools, clubs, or routines.

**Key Fields:**
- Location ID, Household ID
- Name, Address
- Type (Home, School, Sports club, Activity venue, Doctor, Caregiver location, Pickup point, Drop-off point, Other)
- Linked: family members, routines, events
- Travel notes, Default travel time
- Confidence level

---

## Object 14: Owner

The person responsible for an action.

**Key Fields:**
- Owner ID
- Person assigned
- Assigned object type and ID
- Assigned by, timestamp
- Status (Assigned, Accepted, Declined, Completed, Unassigned, Needs reassignment)
- Completion confirmation, Escalation status

> A task without an owner is not handled. It is only stored.

---

## Object 15: Reminder

A prompt to act at the right time — linked to specific actions, not generic alerts.

**Key Fields:**
- Reminder ID, Household ID
- Related object type and ID
- Recipient, Reminder time
- Type (Task, Deadline, Departure, Checklist, Payment, Form, Change, Owner reminder)
- Message, Status (Scheduled, Sent, Dismissed, Completed, Failed)
- Channel

> No reminder without an action.

---

## Object 16: Change

A detected difference between new information and existing household information.

**Key Fields:**
- Change ID, Household ID
- Related object type and ID
- Source message
- Previous value, New value
- Change type (Time, Date, Location, Required item added/removed, Deadline, Event cancelled, Owner, Payment, Form requirement added)
- Detected timestamp, Confidence level
- Impact level, Review status

> Change detection is one of Nabbo's strongest differentiators.

---

## Object 17: Risk

A potential household failure point.

**Key Fields:**
- Risk ID, Household ID
- Title, Description
- Affected family member, Related objects
- Type (No owner, Deadline near, Deadline overdue, Conflicting events, Location changed, Required item not packed, Payment unpaid, Form incomplete, Travel time risk, Missing/contradictory information)
- Severity, Suggested action
- Owner, Status (Open, Acknowledged, Resolved, Dismissed)

> Calendars show what is planned. Nabbo shows what might fail.

---

## Object 18: Routine

A repeated family pattern Nabbo can learn and reuse.

**Key Fields:**
- Routine ID, Household ID
- Name, Affected family member
- Type (School day, Sports activity, Music lesson, Swimming, Weekend activity, Morning launch, Evening reset, Pickup routine, Travel routine)
- Frequency, Common location
- Common required items
- Default owner, Default checklist
- Linked events, Confidence level, Last used date

---

## Object 19: Household Plan

The current operational view — combines everything into a daily/weekly plan.

**Key Fields:**
- Plan ID, Household ID
- Plan date or period
- Type (Today, Tomorrow, This week, Morning launch, Evening reset, Weekend plan)
- Events, Tasks, Deadlines, Checklists
- Risks, Unassigned items, Changes
- Completed items, Open items
- Generated summary

---

## Object 20: Completion

Tracks whether an action has been resolved.

**Key Fields:**
- Completion ID
- Related object type and ID
- Completed by, timestamp
- Method, Notes
- Evidence attachment
- Confirmation status

---

## Object Relationships

```
Household
├── Family Members
├── Source Messages
│   └── Extracted Items
│       └── Decision Status
│       └── Committed Objects (Event, Task, Deadline, Form, Payment, etc.)
├── Events
│   ├── Tasks
│   ├── Required Items
│   ├── Checklists
│   ├── Reminders
│   └── Risks
├── Routines
│   └── Suggested: events, tasks, checklists, items, reminders
├── Changes
├── Risks
└── Household Plan (combines all for a time period)
```

---

## Object Lifecycle

### Extracted Items
Captured → Processed → Pending review → Approved / Edited / Dismissed / Snoozed → Committed

### Tasks
Created → Assigned → Open → Completed / Overdue / Dismissed

### Events
Detected → Pending review → Confirmed → Changed / Completed / Cancelled

### Risks
Detected → Open → Acknowledged → Resolved / Dismissed

### Routines
Suggested → Accepted → Active → Edited / Disabled

---

## Confidence & Uncertainty

Field-level confidence, not just item-level:

| Level | Meaning |
|-------|---------|
| High | Clearly stated in the source |
| Medium | Likely but not fully explicit |
| Low | Inferred or ambiguous |
| Unknown | Missing |

One item can be partly clear and partly uncertain. Example: date and time are high confidence, but location is low confidence.

**The product should never hide uncertainty.**

---

## Data Model Rules

- Do not force every input into an event
- Do not create reminders without actions
- Do not create tasks without owners or unassigned status
- Do not hide uncertainty
- Do not lose the source message
- Do not mix facts and suggestions
- Do not treat changes as normal new events
- Do not let risks sit silently
- Do not let household memory override explicit user input
- Do not over-automate before trust is earned

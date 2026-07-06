# App Flow & Screen Map

## Core Navigation (v1)

```
┌──────────────────────────────────────────────┐
│                    Home                        │
│  (Routes to Review or Today based on urgency) │
└────────┬─────────────────────┬───────────────┘
         │                     │
    ┌────▼────┐          ┌────▼────┐
    │ Review  │          │  Today  │
    │  Inbox  │          │ Command │
    └────┬────┘          │ Center  │
         │               └─────────┘
    ┌────▼────┐
    │ Review  │
    │  Card   │
    └─────────┘
```

Four main areas:
1. **Home** — Decides what the user needs next
2. **Review Inbox** — Extracted items needing parent decision
3. **Today** — Approved items become action, preparation, ownership, and risk visibility
4. **Settings** — Household details, family members, email alias, notifications, privacy

No deep menu structure. No monthly calendar as a main tab.

---

## First-Time User Flow

### Step 1: Welcome

> "Don't remember it. Nabbo it."

Short explanation: "Send school emails, WhatsApp messages, screenshots, voice notes, or quick reminders into Nabbo. We turn them into actions, owners, checklists, and daily plans."

→ **Set up household**

### Step 2: Household Setup

- Household name (required)
- Primary parent name (required)
- Timezone (required)
- Default language (required)

### Step 3: Add Children

- Child name (required)
- Age group (optional)
- School (optional)
- Common activities (optional)

Keep it light. Don't ask for too much upfront.

### Step 4: Add Other People (optional)

- Second parent
- Caregiver
- Grandparent
- Child owner labels

For v1, these are labels, not full user accounts.

### Step 5: Create Nabbo Email Alias

Show the family's unique forwarding email:
> `familyname@nabbo.app`

Explain: "Forward school emails and activity updates here."

### Step 6: Enable Sharing

Explain how to use the mobile share sheet:
> "When you see a message, screenshot, PDF, or note you don't want to remember, share it to Nabbo."

### Step 7: First Capture Prompt

Three options:
- Share something now
- Forward an email
- Type a quick note

**Onboarding ends with action, not education.**

---

## Returning User Flow

| State | Behavior |
|-------|----------|
| Urgent review items exist | Open Home with Review priority: "3 items need review. One is due tomorrow." |
| No urgent reviews | Open Today: "Today is ready. 4 events, 2 tasks, 1 owner gap." |
| Nothing exists | Show empty Today: "Nothing needs attention today. Nabbo a message when something comes in." |

---

## Capture Flows

### Mobile Share

1. Parent sees family-related content in another app
2. Taps Share → selects Nabbo
3. Lightweight capture confirmation screen shows:
   - Source preview
   - Selected household
   - Optional: affected child, note
4. Primary action: **Send to Nabbo**
5. After sending: "Captured. Nabbo will review this."
6. If fast → show Review Card immediately
7. If slower → "Processing. We'll let you know when it's ready."

The user should NOT be forced to classify during capture.

### Email Forwarding

1. Parent forwards email to Nabbo alias
2. Nabbo creates Source Message and processes
3. If objects found → creates Review Cards
4. If nothing actionable → records as "no action found"
5. Notification: "School email reviewed. 2 items need review."

**Failure state:** "We received the email, but could not extract a clear action." → View source / Add manually / Dismiss

### Free Text

1. Parent opens Nabbo → taps **Add**
2. Types short note (e.g., "Yara needs €5 tomorrow for school")
3. Nabbo processes → shows Review Card
4. Primary action: **Add to Today**
5. Secondary: Edit, Assign, Dismiss

### Voice

1. Parent taps **Add Voice**
2. Speaks a reminder
3. Nabbo transcribes
4. Shows transcript (editable)
5. Extracts objects from transcript
6. Primary action: **Review and approve**

Voice should not create hidden actions without review.

---

## Processing States

| State | Message |
|-------|---------|
| Processing | "Nabbo is reading this." |
| Actionable found | "1 item needs review." |
| Multiple items | "4 items found. Review needed." |
| No clear action | "No clear family action found." |
| Error | "We could not process this. Try again or add manually." |

The no-action state is important — Nabbo should not invent actions from every message.

---

## Review Inbox Flow

Shows all pending Review Cards, prioritized by urgency.

**Highest priority:**
- Due today / tomorrow
- Time or location change
- Payment / form due soon
- Pickup owner missing
- Required item for today

Each card shows: source, affected family member, object type, operational summary, urgency marker, confidence marker, primary action.

**Do not encourage bulk approval** — it creates trust risk.

---

## Review Card Flow

Opens from Review Inbox or notification.

**Shows:**
- Operational summary
- Extracted fields
- Uncertain fields
- Suggested actions
- Source preview
- Primary + secondary actions

**Parent can:**
- Approve → commits to household plan
- Edit → inline field editing
- Dismiss → removes with optional reason
- Snooze → delays decision (later today, tomorrow, weekend, next week, custom)
- Assign owner → choose household member
- Mark handled → item is real but already done
- Split → separate multi-action card into individual cards
- Merge → combine with existing item (critical for change detection)
- View full source

---

## Approve Flow

1. Parent taps **Approve**
2. Nabbo commits object to household plan
3. Creates/updates: Event, Task, Deadline, Required item, Checklist, Form, Payment, Change, Risk, Owner assignment
4. Shows confirmation: "Added to Friday. Checklist created. Owner still missing."

**Approval must not hide unresolved issues.**

---

## Change Detection Flow (Merge)

When new input appears to update something existing:

1. Nabbo shows: "This may update Adam's football training."
2. Options: Confirm change / Keep original / Create separate event / Dismiss
3. If confirmed → existing item updated, Today updated

---

## Today Flow

Shows approved and active household items.

**Sections:** Today status, Next action, Events today, Tasks due, Required items, Forms & payments, Owner gaps, Changes, Risks, Tomorrow prep.

**Item actions from Today:**
- Mark done / Mark packed
- Assign owner
- View source
- Edit
- Dismiss risk
- Open checklist
- Confirm change
- Set reminder

**Today is interactive enough to execute the day, not just read it.**

---

## Error States

| Error | Message | Actions |
|-------|---------|---------|
| Unsupported file | "This file type is not supported yet." | Add manually |
| Extraction failed | "Nabbo could not read this clearly." | View source, Add manually, Try again |
| No action found | "No clear family action found." | Save as note, Dismiss, Add manually |
| Missing key detail | "Time is missing." | Add time, Snooze, Dismiss |
| Possible duplicate | "This may already exist." | Merge, Create new, Dismiss |

---

## Empty States

| Screen | Message | Action |
|--------|---------|--------|
| Review Inbox | "Nothing to review." | Go to Today |
| Today | "Nothing needs attention today." | Nabbo a message |
| No family members | "Add a child or household member so Nabbo knows who messages affect." | Add family member |
| No email alias used | "Forward school emails to your Nabbo address." | Copy email alias |

Empty states teach behavior without becoming noisy.

---

## Primary Flow Map

```
Flow 1: Mobile Share
External app → Share to Nabbo → Capture confirmation → Processing → Review Card → Approve/Edit → Today updated

Flow 2: Email Forwarding
Email client → Forward to alias → Processing → Notification → Review Inbox → Review Card → Approve/Edit → Today updated

Flow 3: Free Text
Nabbo → Add → Type note → Processing → Review Card → Approve/Edit → Today updated

Flow 4: Voice
Nabbo → Add Voice → Record → Transcript → Review Card → Approve/Edit → Today updated

Flow 5: Change Detection
Input received → Nabbo matches existing item → Change Review Card → Confirm change → Existing item updated → Today updated

Flow 6: Risk Detection
Approved item has execution gap → Risk appears in Review or Today → Parent assigns/completes/dismisses → Risk resolved
```

---

## Screen Map (v1)

- Welcome
- Household Setup
- Add Family Members
- Nabbo Email Alias Setup
- Capture Confirmation
- Processing State
- Review Inbox
- Review Card
- Edit Field
- Assign Owner
- Snooze
- Source View
- Today
- Checklist Detail
- Risk Detail
- Change Detail
- Manual Add
- Voice Add
- Settings
- Family Members Settings
- Notifications Settings
- Privacy Settings
- Recent Activity

**Not included in v1:** Calendar grid, chat, analytics dashboard, routine builder.

---

## Notification Flow

Notifications deep-link to the relevant object. See [Notification Strategy](./09-notification-strategy.md) for full rules.

**Key principles:**
- No action, no notification
- Every notification opens the relevant screen (Review Card, checklist, change card, assignment action, or Today)
- Group related items instead of sending separate alerts
- Default to quiet; let users control categories

**Examples:**
- "1 item needs review." → Opens Review Card
- "Training time changed." → Opens Change Review Card
- "Payment due tomorrow." → Opens payment item in Today
- "Pickup owner missing." → Opens owner gap risk

---

## Product Flow Rules

- Always move toward action
- Do not ask users to classify inputs during capture
- Do not hide source messages
- Do not auto-commit important extracted items
- Do not treat all inputs as events
- Do not allow approved actions to lose owner visibility
- Do not make Today a calendar grid
- Do not show notifications without a clear action
- Do not let review become manual data entry
- Do not force advanced setup before the first capture

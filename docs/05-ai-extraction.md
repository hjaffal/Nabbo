# AI Extraction — Complete Specification

## Purpose

Nabbo receives messy family signals and converts them into structured items that can be reviewed, edited, approved, tracked, and completed.

The extraction layer is **not a summary engine**. A summary tells the parent what the message says. Nabbo must tell the parent **what needs to happen**.

The output is action-first, trust-aware, and reviewable.

---

## Architecture

```
Source Message (raw input)
        │
        ▼
  Cloud Function: extractSourceMessage
  (Gemini 2.5 Flash via @google/genai SDK)
        │
        ▼
  Items written to: households/{id}/items/
  with status: 'pendingReview'
```

- **Function:** `extractSourceMessage` in `functions/index.js`
- **Trigger:** `onDocumentCreated` on `households/{householdId}/sourceMessages/{messageId}`
- **Region:** `europe-west1`
- **Secret:** `GEMINI_API_KEY` (stored in Firebase Secrets)
- **No intermediate collection.** AI writes directly to items.
- **Approval = status change** on the same document (`pendingReview` → `confirmed`)

---

## Supported Input Types

| Method | Examples |
|--------|----------|
| Free text | Typed notes ("Adam has football Friday at 18:30") |
| Voice | Spoken reminders, transcribed on-device |
| Mobile share | WhatsApp messages, screenshots, copied text, PDFs |
| Forwarded email | School emails, activity updates, payment requests |
| Image | Photos of letters, forms, timetables, posters |

Each input is stored as a `sourceMessage` and preserved for traceability.

---

## Processing Pipeline

```
1. Source message created (processingStatus: 'pending')
2. Function triggers
3. Set processingStatus → 'processing'
4. Gather household context:
   a. Family members (id, name, role)
   b. Confirmed items (for change detection + dedup)
   c. Today's date (for relative date resolution)
5. Build extraction prompt (includes existing items so AI can detect changes)
6. Call Gemini 2.5 Flash
7. Parse JSON response (strip markdown fences)
8. For each extracted result:
   a. If action == "create": write new item with status 'pendingReview'
   b. If action == "update": write change proposal (new item referencing the target)
   c. If action == "cancel": write cancellation proposal (new item referencing the target)
   d. Match childName/ownerName → family members
   e. Parse dates → Firestore Timestamps
9. Update source message:
   - processingStatus → 'completed' (or 'noAction' if empty, 'failed' on error)
   - processedAt → server timestamp
10. Send push notification (if items created)
```

---

## Item Types (3 only)

The extraction produces exactly **3 types**: `event`, `task`, `deadline`.

All other concepts (payments, forms, required items, pickups) are expressed as enriched **tasks**.

### Event

A scheduled activity or commitment at a specific date/time.

| Field | Source |
|-------|--------|
| `title` | Activity name |
| `childName` | Affected family member |
| `date` | Start date + time (Timestamp) |
| `endDate` | End date + time if mentioned (Timestamp) |
| `location` | Where it happens |
| `ownerName` | Responsible adult if mentioned |
| `recurrence` | `{ frequency, dayOfWeek, startDate, endDate }` |
| `extractedFields.category` | school, sports, medical, activity, travel, birthday, family, appointment |

**When to create:** The source describes a scheduled activity, appointment, class, match, trip, visit, or commitment with a date/time.

**Examples:**
- "Adam has football Friday at 18:30" → event
- "Dentist next Tuesday at 4pm" → event
- "School trip to museum on Friday" → event
- "Training every Tuesday at 16:00" → event (recurring)

---

### Task

An action someone must complete.

| Field | Source |
|-------|--------|
| `title` | Action-focused title |
| `childName` | Affected family member |
| `date` | Due date/time if applicable |
| `ownerName` | Who must do it (adults only, never children) |
| `extractedFields` | Any additional structured data AI detects |

**When to create:**
- Source says do/bring/pack/pay/sign/submit/prepare/pickup/drop-off
- Source references money, documents, items to bring
- Source assigns a to-do action to someone

**Examples:**
- "Bring packed lunch and water bottle" → task: "Bring packed lunch and water bottle"
- "Pay €8 through school portal" → task: "Pay €8 through school portal"
- "Sign permission slip by Wednesday" → task: "Sign permission slip"
- "Pick up Adam from school" → task: "Pick up Adam from school"
- "Buy milk" → task: "Buy milk"

---

### Deadline

A hard due date by which something must be done.

| Field | Source |
|-------|--------|
| `title` | What's due |
| `childName` | Affected family member |
| `date` | Due date + time (Timestamp) |
| `ownerName` | Who's responsible |
| `extractedFields.urgency` | `low`, `medium`, `high` |

**When to create:** The source uses "by", "before", "due", "submit by", "pay by", "return by", "deadline". A deadline should usually have a related task — create both.

---

## Change Detection

Not every source message creates new items. Some messages **update or cancel** existing items. The AI must detect this.

### Actions

Each extracted result has an `action` field:

| Action | Meaning | Example input |
|--------|---------|---------------|
| `create` | New item, nothing like this exists | "Adam has basketball Friday at 17:30" |
| `update` | Modifies an existing confirmed item | "Training moved to Thursday 18:00" |
| `cancel` | Cancels an existing confirmed item | "Football cancelled tomorrow" |

### How It Works

1. The prompt includes the household's confirmed items as context
2. AI compares the new message against existing items
3. If AI detects a match, it returns `action: "update"` or `action: "cancel"` with a `targetItemTitle` referencing which existing item is affected
4. The function finds the matching item by title (fuzzy) + child + type
5. A **change proposal** is written to `items/` with `status: pendingReview`

### Change Proposal Item

When `action` is `update` or `cancel`, the extracted item is written with additional fields:

```json
{
  "type": "event",
  "status": "pendingReview",
  "title": "Football training",
  "action": "update",
  "targetItemId": "matched-item-id or null",
  "targetItemTitle": "Football training",
  "changes": {
    "date": "new value",
    "location": "new value"
  },
  "previousValues": {
    "date": "old value",
    "location": "old value"
  },
  ...other fields with the NEW values
}
```

For cancellations:

```json
{
  "type": "event",
  "status": "pendingReview",
  "title": "Football training",
  "action": "cancel",
  "targetItemId": "matched-item-id or null",
  "targetItemTitle": "Football training",
  "summary": "Football cancelled tomorrow"
}
```

### Review Flow for Changes

When the user reviews a change proposal:

| Action in proposal | Approve does | UI shows |
|--------------------|-------------|----------|
| `update` | Updates the target item's fields with the new values | "Update football training? Time: 17:30 → 18:00, Location: Sports Hall → Main Hall" |
| `cancel` | Sets target item status to `cancelled` (or adds exception for single occurrence) | "Cancel football training tomorrow?" |
| `create` | Creates item as normal (status → confirmed) | Normal review card |

### Approve Logic (for changes)

**Update approval:**
1. Find target item by `targetItemId` (or fuzzy match by title + child + type)
2. Apply `changes` map to the target item document
3. Delete the change proposal item (it served its purpose)

**Cancel approval:**
1. Find target item by `targetItemId`
2. If target is recurring + change is for one date → add exception `{ date, status: "cancelled" }`
3. If target is non-recurring → set `status: "cancelled"`
4. Delete the change proposal item

**Reject (delete the proposal):**
- Simply delete the change proposal item. Target item stays unchanged.

### Matching Existing Items

The function matches against confirmed items using:
1. `targetItemTitle` (from AI) compared to existing `title` (case-insensitive, fuzzy)
2. Same `childName` (if provided)
3. Same `type`
4. Date proximity (within same week for recurring, same day for one-off)

If no match found: `targetItemId` stays null. The review screen shows the proposal but warns "Could not find matching item. Review carefully."

### AI Output Schema (with action)

```json
{
  "action": "create|update|cancel",
  "type": "event|task|deadline",
  "title": "Title of the item (new or existing)",
  "targetItemTitle": "Title of existing item being changed (for update/cancel only)",
  "changes": { "fieldName": "new value" },
  "summary": "What changed or why cancelled",
  "childName": "...",
  "ownerName": "...",
  "date": "...",
  "endDate": "...",
  "location": "...",
  ...
}
```

### Examples

**Schedule change:**
> "Basketball moved to Thursday at 18:00 this week"

```json
[{
  "action": "update",
  "type": "event",
  "title": "Basketball training",
  "targetItemTitle": "Basketball training",
  "changes": { "date": "thursday 18:00" },
  "summary": "Moved from regular day to Thursday 18:00 this week",
  "childName": "Adam",
  "date": "thursday 18:00"
}]
```

**Cancellation:**
> "No swimming tomorrow, pool is closed"

```json
[{
  "action": "cancel",
  "type": "event",
  "title": "Swimming",
  "targetItemTitle": "Swimming",
  "summary": "Pool is closed tomorrow",
  "childName": "Yara",
  "date": "tomorrow"
}]
```

**New item (no change):**
> "Adam has dentist next Tuesday at 4pm"

```json
[{
  "action": "create",
  "type": "event",
  "title": "Dentist appointment",
  "childName": "Adam",
  "date": "next tuesday 16:00"
}]
```

---

## Item Document Structure

Every extracted item is written to Firestore as:

```json
{
  "householdId": "string",
  "type": "event | task | deadline",
  "status": "pendingReview",
  "action": "create | update | cancel",
  "title": "Action-focused title",
  "summary": "Longer explanation (optional)",
  "childId": "matched member ID or null",
  "childName": "matched member name or null",
  "ownerId": "matched adult ID or null",
  "ownerName": "matched adult name or null",
  "date": "Firestore Timestamp (with time!) or null",
  "endDate": "Firestore Timestamp or null",
  "location": "string or null",
  "recurrence": "{ frequency, dayOfWeek, startDate, endDate } or null",
  "exceptions": [],
  "sourceMessageId": "links to source",
  "targetItemId": "ID of existing item being changed (update/cancel only)",
  "targetItemTitle": "title of existing item (for matching)",
  "changes": { "fieldName": "new value" },
  "previousValues": { "fieldName": "old value" },
  "extractedFields": {},
  "confidence": { "fieldName": "high|medium|low|unknown" },
  "uncertainFields": ["field names needing verification"],
  "suggestedActions": ["recommended next steps"],
  "createdAt": "Timestamp",
  "updatedAt": null
}
```

**Notes:**
- `action` defaults to `"create"` for new items
- `targetItemId`, `targetItemTitle`, `changes`, `previousValues` are only set for `update`/`cancel` actions
- Items with `action: "create"` behave exactly as before (approve → confirmed)

---

## Prompt Specification

### System Context

The prompt MUST include:

1. **Role definition:** "You are Nabbo, a family logistics AI."
2. **Family members:** Names + roles (e.g., "Adam (child), Yara (child), Hassan (primaryParent), Sarah (secondaryParent)")
3. **Existing items context:** Last 20 confirmed items for dedup awareness
4. **Today's date:** So relative dates can be resolved accurately

### Extraction Rules (in prompt)

- Extract **actions**, not summaries
- Types allowed: `event` (scheduled activity), `task` (action to do), `deadline` (hard due date)
- **Detect changes:** If the message updates or cancels something that matches an existing item, use `action: "update"` or `action: "cancel"` with `targetItemTitle`. If it's new, use `action: "create"`.
- Match affected child to family member if possible
- Match owner/responsible person to adult family members if mentioned
- If recurring, include recurrence object with `frequency`, `dayOfWeek`, `startDate`, `endDate`
- Mark uncertain fields explicitly
- Do NOT guess dates/times — mark as uncertain if unclear
- Extract end times when mentioned (store as `endDate`)
- Keep titles action-focused and natural (no artificial prefixes)

### Expected AI Output Schema

```json
[
  {
    "action": "create|update|cancel",
    "type": "event|task|deadline",
    "title": "Short action-focused title",
    "summary": "Longer explanation if needed",
    "targetItemTitle": "Title of existing item (for update/cancel only, null for create)",
    "changes": { "fieldName": "new value (for update only)" },
    "childName": "Name of affected child or null",
    "ownerName": "Name of responsible adult or null",
    "date": "ISO date-time string, relative string, or null",
    "endDate": "ISO date-time string, relative string, or null",
    "location": "Where it happens or null",
    "recurrence": {
      "frequency": "weekly|daily|biweekly|monthly",
      "dayOfWeek": "monday|tuesday|...|sunday",
      "startDate": "YYYY-MM-DD",
      "endDate": "YYYY-MM-DD or null"
    },
    "fields": {},
    "confidence": {
      "date": "high|medium|low|unknown",
      "location": "high|medium|low|unknown",
      "childName": "high|medium|low|unknown",
      "ownerName": "high|medium|low|unknown"
    },
    "uncertainFields": ["field names that need verification"],
    "suggestedActions": ["recommended next steps"]
  }
]
```

---

## Confidence Scoring

Field-level confidence, not item-level:

| Level | Meaning | Display to user |
|-------|---------|-----------------|
| `high` | Clearly stated in source | "Clear" |
| `medium` | Likely but not fully explicit | "Check this" |
| `low` | Inferred or ambiguous | "Unclear" |
| `unknown` | Missing from source | "Missing" |

**Fields that require confidence scoring:**
- `childName` — who is affected?
- `date` — when?
- `location` — where?
- `ownerName` — who's responsible?

**Nabbo should never hide uncertainty.** If a field is guessed, it must be in `uncertainFields`.

---

## Owner Matching

Ownership means "who is responsible for this action." It is always an adult.

| Source text | Match to |
|-------------|----------|
| "Dad", "Father" | Family member with parent role (male) |
| "Mum", "Mom", "Mother" | Family member with parent role (female) |
| "I", "me", "remind me" | The user who submitted the source message |
| Adult name (e.g., "Sarah") | Matched family member by name |
| Not mentioned | `ownerName: null`, add to `uncertainFields`, suggest "Assign owner" |

**Never assign ownership to a child.** Children are `childName` (who is affected), never `ownerName` (who is responsible).

---

## Date & Time Parsing

The AI returns dates as strings. The function resolves them to Firestore Timestamps.

| Input format | Resolution |
|--------------|------------|
| `"2026-07-15"` | July 15, 2026 at 00:00 |
| `"2026-07-15T16:30:00"` | July 15, 2026 at 16:30 |
| `"tomorrow"` | Next day at 00:00 |
| `"tomorrow at 4pm"` | Next day at 16:00 |
| `"friday"` | Next Friday at 00:00 |
| `"friday 18:30"` | Next Friday at 18:30 |
| `"next tuesday at 16:00"` | Next Tuesday at 16:00 |
| `"monday at 4pm"` | Next Monday at 16:00 |

### Time format handling

- `4pm`, `4 pm`, `16:00`, `16h00` → 16:00
- `18:30`, `6:30pm`, `6.30pm` → 18:30
- `noon`, `12pm` → 12:00
- `morning` → 09:00 (mark as uncertain)
- `afternoon` → 14:00 (mark as uncertain)
- `evening` → 18:00 (mark as uncertain)

**Critical rule:** If a time is mentioned, it MUST be preserved in the Timestamp. Never store midnight when a time was provided.

---

## Recurrence

| Source pattern | Extracted recurrence |
|----------------|---------------------|
| "every Tuesday" | `{ frequency: "weekly", dayOfWeek: "tuesday", startDate: "YYYY-MM-DD" }` |
| "every Tuesday until December" | `{ frequency: "weekly", dayOfWeek: "tuesday", startDate: "...", endDate: "2026-12-31" }` |
| "daily" | `{ frequency: "daily", startDate: "YYYY-MM-DD" }` |
| "every other week" | `{ frequency: "biweekly", dayOfWeek: "...", startDate: "..." }` |
| "monthly on the 15th" | `{ frequency: "monthly", startDate: "YYYY-MM-15" }` |

Recurring items are expanded **client-side** in the Feed (next 4 weeks). Cancelled occurrences are stored in the `exceptions` array.

---

## Multi-Item Extraction

A single source message can produce **multiple items**. The AI must split complex messages:

| Source content | Items created |
|----------------|--------------|
| "Trip Friday. Bring lunch, water. Form due Wednesday. Pay €8." | 1 event + 3 tasks |
| "Dentist Tuesday at 4. Pick up early." | 1 event + 1 task |
| "Cancel football tomorrow" | 1 task (cancel action) |
| "Nothing today" | 0 items (noAction) |

Each item links back to the same `sourceMessageId`.

---

## JSON Response Parsing

The `parseExtractionResponse` function MUST handle:

1. Clean JSON array: `[{...}]`
2. JSON wrapped in ` ```json\n...\n``` `
3. JSON wrapped in ` ```\n...\n``` ` (no language tag)
4. JSON with leading/trailing whitespace
5. JSON with trailing newlines after closing fence

### Stripping Algorithm

```
1. Trim whitespace
2. If starts with "```json" → remove first line
3. Else if starts with "```" → remove first line
4. If ends with "```" → remove last "```" occurrence
5. Trim again
6. Parse as JSON
7. Validate: must be array, each element must have `type` and `title`
```

---

## Suggested Actions

The `suggestedActions` array provides helpful next steps:

| Context | Suggested action |
|---------|-----------------|
| Owner missing | "Assign owner" |
| Date uncertain | "Verify date" |
| Multiple items from one source | "Review all items from this message" |
| Recurring detected | "Confirm recurrence schedule" |
| Child not matched | "Confirm which child this is for" |

Maximum 3 suggested actions per item.

---

## Error Handling

| Scenario | processingStatus | Items created | User sees |
|----------|-----------------|---------------|-----------|
| AI returns valid items | `completed` | 1+ items | Items in Feed with "Review" badge |
| AI returns empty array | `noAction` | 0 | "No clear action found" |
| AI returns unparseable response | `failed` | 0 | "Could not process this" + Try again |
| API call fails/times out | `failed` | 0 | "Could not process this" + Try again |

### Retry Policy

- Up to 3 retries on Gemini API 5xx errors (exponential backoff: 1s, 2s, 4s)
- No retry on 4xx errors
- User can manually retry via "Try again" button (resets `processingStatus` to `pending`)

---

## Household Context Injection

Before each extraction call, gather:

```javascript
// 1. Family members
const members = await db.collection('households/{id}/members').get();
// → [{ id, name, role }]

// 2. Recent confirmed items (last 20)
const existing = await db.collection('households/{id}/items')
  .where('status', '==', 'confirmed')
  .orderBy('createdAt', 'desc')
  .limit(20)
  .get();
// → ["[event] Adam football Tuesday 17:30", "[task] Pack lunch for trip", ...]

// 3. Today's date
const today = new Date().toISOString().split('T')[0];
```

This context helps Gemini:
- Match children by name accurately
- Detect changes to existing items
- Avoid duplicate extraction
- Resolve "he"/"she" references based on household composition

---

## Notification After Extraction

When items are created successfully:

```javascript
{
  token: userFcmToken,
  notification: {
    title: "3 items to review",
    body: "Adam's school trip on Friday + 2 more"
  },
  data: { type: "review_needed", householdId: "..." }
}
```

---

## Performance Requirements

| Metric | Target |
|--------|--------|
| Function cold start | < 5s |
| Gemini extraction latency | < 15s |
| Total processing time | < 30s |
| Firestore writes (batch) | < 2s |
| Memory allocation | 256MB |
| Function timeout | 60s |

---

## Security

- Gemini API key stored as Firebase Secret (never in code or git)
- Function runs with service account (minimum IAM permissions)
- Only reads/writes within the triggering household's subcollections
- No cross-household data access possible
- Source content not logged in full (privacy)

---

## Review Flow (v1)

After extraction, the parent reviews each item based on its `action`:

### New items (`action: "create"`)
- **Approve** → status changes to `confirmed`
- **Edit** → modify any field, then approve
- **Delete** → remove the item

### Changes (`action: "update"`)
- **Approve** → applies `changes` to the target item, deletes the proposal
- **Edit** → modify the proposed changes, then approve
- **Reject** → delete the proposal, target item stays unchanged

### Cancellations (`action: "cancel"`)
- **Approve** → cancels the target item (or adds exception for single occurrence of recurring)
- **Reject** → delete the proposal, target item stays unchanged

Items are always editable regardless of status.

---

## The Five Questions

Every extraction should answer:

1. **Who** is affected? → `childName`
2. **What** needs to happen? → `title` + `type`
3. **When** does it matter? → `date`
4. **Who** owns it? → `ownerName`
5. **What** could be missed? → `uncertainFields` + `suggestedActions`

If Nabbo cannot answer one, it shows the gap clearly.

---

## Testing Scenarios

### Must Extract Correctly

| Input | Expected |
|-------|----------|
| "Adam has football Friday at 18:30" | 1 event (create): Adam, Friday 18:30 |
| "Yara needs €5 for school tomorrow" | 1 task (create): "Give Yara €5 for school", Yara, tomorrow |
| "School trip Friday. Bring lunch, water, raincoat. Form due Wednesday. Pay €8." | 1 event + 3 tasks (all create) |
| "Training moved to Thursday 17:00 at Sports Hall" | 1 event (update): changes date+location on existing training |
| "No swimming tomorrow, pool closed" | 1 event (cancel): cancels tomorrow's swimming |
| "Dentist next Tuesday at 4pm, pick up early" | 1 event (create) + 1 task (create) |
| "Every Tuesday Yara has swimming at 16:00" | 1 event (create): recurring weekly/tuesday, 16:00 |
| "Dad needs to sign the permission slip by Friday" | 1 task (create): owner: Dad, date: Friday |
| "Basketball cancelled this week" | 1 event (cancel): cancels this week's basketball |
| "Football moved from 17:30 to 18:00" | 1 event (update): changes time on football |
| "Nothing special today" | 0 items (noAction) |

### Must NOT Break

| Input | Expected |
|-------|----------|
| Empty string | noAction, 0 items |
| Very long email (5000+ chars) | Extracts relevant items, no timeout |
| Non-family content ("sale at store") | noAction or low-confidence |
| Mixed languages | Extracts in detected language |
| "Cancel something" (no match possible) | 1 item (cancel) with targetItemId: null, warning shown |

---

## Known Defects (to fix)

1. **Time not preserved:** `parseDate("next tuesday at 16:00")` → midnight instead of 16:00
2. **endDate never set:** Events with duration always get `endDate: null`
3. **Owner never extracted:** Prompt doesn't ask for owner, function doesn't match
4. **extractedFields unstructured:** No defined field vocabulary in prompt
5. **Recurrence endDate missing:** Can't store "until end of term"
6. **Fragile fence stripping:** Edge cases in JSON cleanup can fail
7. **No today's date in prompt:** Relative dates lack anchor for accurate resolution

---

## Design Principles

- **Speed over perfection** — extract quickly, let the user correct
- **Trust over automation** — show what was understood, never hide guesses
- **Action over summary** — "what needs to happen" not "what the message says"
- **Simple over clever** — 3 types, clear fields, natural titles
- **Reviewable over auto-committed** — everything starts as `pendingReview`

The goal is not perfect AI. The goal is **trusted household execution**.

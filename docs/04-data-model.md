# Core Data Model

## Core Principle

Nabbo uses **two Firestore collections** per household. This keeps the architecture simple, queries fast, and the codebase maintainable.

```
households/{householdId}/sourceMessages/{id}   ← raw captured inputs
households/{householdId}/items/{id}            ← everything: extracted, reviewed, committed
```

---

## Collection 1: Source Messages

A Source Message is the raw input sent into Nabbo. It is the **trust anchor** — the original content the parent shared.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Document ID |
| `householdId` | string | Parent household |
| `submittedBy` | string | User ID who captured this |
| `inputMethod` | enum | How it entered Nabbo |
| `originalContent` | string | The raw text/transcript |
| `attachmentUrl` | string? | URL to uploaded file (image, PDF, audio) |
| `attachmentType` | string? | Type of attachment (image, pdf, audio) |
| `sourceApp` | string? | Detected source app (WhatsApp, email, etc.) |
| `processingStatus` | enum | Current processing state |
| `receivedAt` | Timestamp | When it was captured |
| `processedAt` | Timestamp? | When AI finished processing |

### Processing Status Enum

| Value | Meaning |
|-------|---------|
| `pending` | Just captured, waiting for AI |
| `processing` | AI is currently analyzing |
| `completed` | AI finished, items created |
| `failed` | AI failed to process |
| `noAction` | AI found nothing actionable |
| `dismissed` | User deleted/dismissed the capture |

### Input Method Enum

| Value | Description |
|-------|-------------|
| `freeText` | Typed note inside the app |
| `voice` | Voice transcription |
| `emailForwarding` | Forwarded email via SendGrid |
| `mobileShare` | Shared from another app |
| `imageUpload` | Photo or screenshot |

---

## Collection 2: Items

An Item is **everything** — from the moment AI extracts it (pending review) through the user's approval and into execution. There is no copy between collections. The lifecycle is managed via the `status` field.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Document ID |
| `householdId` | string | Parent household |
| `type` | enum | What kind of item this is |
| `status` | enum | Lifecycle state |
| `title` | string | Short action-focused title |
| `summary` | string? | Longer operational summary from AI |
| `childId` | string? | ID of affected family member (child) |
| `childName` | string? | Name of affected child |
| `ownerId` | string? | ID of responsible parent/adult |
| `ownerName` | string? | Name of responsible parent/adult |
| `date` | Timestamp? | Primary date/time for this item |
| `endDate` | Timestamp? | End time (for events with duration) |
| `location` | string? | Where this happens |
| `recurrence` | map? | Recurrence rule (see below) |
| `exceptions` | array? | Modified/cancelled single occurrences |
| `sourceMessageId` | string? | Link back to original capture |
| `action` | string? | `create`, `update`, or `cancel` (defaults to `create`) |
| `targetItemId` | string? | ID of existing item being changed (update/cancel only) |
| `targetItemTitle` | string? | Title of existing item for matching |
| `changes` | map? | Fields being changed with new values (update only) |
| `previousValues` | map? | Fields being changed with old values (update only) |
| `extractedFields` | map | All AI-detected fields as key-value pairs |
| `confidence` | map? | Per-field confidence: { fieldName: "high"\|"medium"\|"low"\|"unknown" } |
| `uncertainFields` | array? | List of field names AI was unsure about |
| `suggestedActions` | array? | AI-suggested next steps |
| `createdAt` | Timestamp | When created |
| `updatedAt` | Timestamp? | Last modification |

### Item Type Enum

| Value | Description | Example |
|-------|-------------|---------|
| `event` | Something scheduled at a specific time | "Basketball training Tuesday 17:30" |
| `task` | An action someone must complete (includes things to bring/pack) | "Pack towel and goggles", "Reply to teacher" |
| `deadline` | A hard due date that triggers reminders | "Permission form due Wednesday" |

### Item Status Enum

| Value | Meaning |
|-------|---------|
| `pendingReview` | AI extracted this, waiting for parent to verify |
| `confirmed` | Parent approved, part of the household plan |
| `completed` | Action done (task finished, item packed, etc.) |
| `cancelled` | Cancelled (event cancelled, no longer needed) |

### Lifecycle

```
AI extracts → status: pendingReview
    ↓ (user approves)
status: confirmed (appears in Feed as active)
    ↓ (user marks done OR event passes)
status: completed
    ↓ (alternatively: user cancels)
status: cancelled (shown with strikethrough in Feed)
```

**Editing:** Users can edit any item at any point in the lifecycle — whether it's pending review, confirmed, completed, or cancelled. Editing does not change the status.

---

## Recurrence

For recurring items (e.g., "basketball every Tuesday"), the item stores a **recurrence rule**. The Feed expands it into virtual occurrences client-side.

### Recurrence Map

| Field | Type | Description |
|-------|------|-------------|
| `frequency` | string | `weekly` \| `daily` \| `biweekly` \| `monthly` |
| `dayOfWeek` | string? | Day name (for weekly): `monday` through `sunday` |
| `startDate` | string | ISO date when recurrence begins (YYYY-MM-DD) |
| `endDate` | string? | ISO date when recurrence ends (null = ongoing) |

### Exceptions Array

Each entry represents a single occurrence that differs from the rule:

```json
{
  "date": "2026-07-22",
  "status": "cancelled"
}
```

Or an override:

```json
{
  "date": "2026-08-05",
  "overrides": {
    "time": "18:00",
    "location": "Sports Hall B"
  }
}
```

### Feed Expansion Logic

1. Read recurrence rule from item
2. Generate occurrences from `startDate` to min(`endDate`, now + 4 weeks)
3. For each occurrence date, check `exceptions`:
   - If `status: cancelled` → skip this date
   - If `overrides` exist → apply them to the card
4. Each occurrence renders as a separate card in the Feed under its day header

### Modification Rules

| Action | What happens |
|--------|-------------|
| Cancel one occurrence | Add `{ date, status: "cancelled" }` to exceptions |
| Modify one occurrence | Add `{ date, overrides: {...} }` to exceptions |
| Cancel entire series | Set item `status: "cancelled"` |
| Edit the series | Update the item's fields (affects all future occurrences) |

---

## Household Document

The household document lives at `households/{householdId}`.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Document ID |
| `name` | string | Household display name |
| `primaryUserId` | string | UID of the primary parent account |
| `timezone` | string | Household timezone (e.g., "Europe/Amsterdam") |
| `language` | string | Default language (e.g., "en") |
| `emailAlias` | string? | Forwarding email (e.g., "jaffal@nabboapp.com") |
| `zipCode` | string? | Zip/postal code |
| `city` | string? | City name |
| `country` | string? | Country name or code |
| `memberIds` | array | List of user IDs with access |
| `createdAt` | Timestamp | When created |
| `updatedAt` | Timestamp? | Last modification |

### Location Fields

- `zipCode`, `city`, `country` can be set manually in Settings → Edit Household
- They can also be auto-detected from the device's GPS location (with permission)
- Used by AI extraction for local context (school names, activity venues, currency)

---

## Family Members

Stored in `households/{householdId}/members/{memberId}`.

The **primary parent is automatically added** as a family member when the household is created (during onboarding). This ensures they are available in the Owner dropdown for item assignment.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Document ID |
| `householdId` | string | Parent household |
| `name` | string | Display name |
| `role` | enum | `primaryParent`, `secondaryParent`, `child`, `caregiver`, `grandparent`, `babysitter`, `other` |
| `ageGroup` | enum? | `toddler`, `child`, `teenager`, `adult` |
| `photoUrl` | string? | Profile photo URL (uploaded to Cloud Storage) |
| `color` | string | Hex color code (e.g., `#7B61D9`). Randomly assigned on creation, editable by user. |
| `defaultResponsibilities` | array | Default responsibilities for this member |
| `createdAt` | Timestamp | When added |

### Color Assignment

- When a family member is created, a **random color** is assigned from a predefined palette
- The user can change the color via the Edit Family Member screen in Settings (color picker)
- This color is used in the app to visually identify the member:
  - Item card child chip (background tint + text color)
  - Review card child chip
  - Item detail screen child field
- Palette (soft, warm, distinct colors that work on light backgrounds):
  - `#7B61D9` (purple)
  - `#FF6B6B` (coral)
  - `#4ECDC4` (teal)
  - `#FFB347` (orange)
  - `#77DD77` (green)
  - `#6BB5FF` (blue)
  - `#FF85A2` (pink)
  - `#B19CD9` (lavender)

---

## Relationships

```
Household
├── Fields: name, timezone, language, emailAlias, zipCode, city, country
├── Family Members (subcollection: members/)
│   └── Each member has: name, role, ageGroup, photoUrl, color
├── Source Messages (subcollection: sourceMessages/)
│   └── linked to Items via item.sourceMessageId
└── Items (subcollection: items/)
    ├── childId → references a family member
    ├── ownerId → references a family member (parent/adult only)
    └── sourceMessageId → references a source message
```

### Key Relationships

- **Item → Source Message**: Every item has `sourceMessageId` for traceability (except manually created items)
- **Item → Child**: `childId`/`childName` = which family member this is ABOUT
- **Item → Owner**: `ownerId`/`ownerName` = which adult is RESPONSIBLE (parents/caregivers only, never children)

---

## Queries

### Feed Query (main screen)

```
items where status in ['pendingReview', 'confirmed', 'cancelled']
  order by date ascending
```

Shows: pending items first, then chronological. Cancelled items remain visible with strikethrough + badge.

### Completed/History

```
items where status in ['completed', 'cancelled']
  order by updatedAt descending
```

### By Child

```
items where childId == {memberId} and status == 'confirmed'
```

### Overdue/Urgent

```
items where type == 'deadline' and status == 'confirmed' and date < now
```

---

## What Happens at Each Stage

### 1. Capture

User captures content → `sourceMessages/` document created with `processingStatus: pending`

### 2. AI Extraction

Cloud Function fires → reads source message → calls Gemini → writes one or more documents to `items/` with `status: pendingReview` and `sourceMessageId` set.

Also updates source message: `processingStatus: completed`

### 3. Review

User sees items with `status: pendingReview` in Feed (and Review tab). User can:
- **Approve** → `status: confirmed`
- **Edit** → update fields, then approve
- **Delete** → delete the item document, mark source as `dismissed`

### 4. Execution

Confirmed items appear in Feed grouped by date. User can:
- **Mark done** → `status: completed`
- **Cancel** → `status: cancelled`
- **Edit** → update any field

### 5. Recurrence

Recurring items show multiple cards via client-side expansion. Single occurrences can be cancelled/modified via `exceptions` array.

---

## Migration from Current State

The current app has 9+ subcollections (events/, tasks/, payments/, etc.). Migration:

1. Stop writing to separate collections
2. Cloud Function writes directly to `items/`
3. Approval = status change on same document (no copy)
4. Feed queries single `items/` collection
5. Old collections can be ignored (or migrated later)

---

## Data Model Rules

- Do NOT create separate collections for each item type
- Do NOT copy data between collections on approval
- Do NOT force every input into a specific type — let the AI decide
- Show uncertainty clearly — `confidence` map and `uncertainFields` array
- Keep the original source always accessible via `sourceMessageId`
- Owner is ALWAYS a parent/adult, never a child
- Child is WHO the item is about, owner is WHO must act on it

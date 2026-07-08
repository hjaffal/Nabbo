# Family Activity Feed Spec

## Purpose

The Family Activity Feed gives parents a chronological timeline of household actions — captures, approvals, edits, completions, and cancellations. It makes the household feel "alive" by surfacing what has happened recently, providing shared visibility into family logistics activity.

This is distinct from the existing Feed (which shows items grouped by date for forward-looking planning). The Activity Feed is a backward-looking timeline answering: "What has happened in our household recently?"

The feature works with the current single-user authentication model but is designed to scale naturally when multi-user households are introduced later.

---

## Glossary

| Term | Definition |
|------|-----------|
| Activity_Feed | A chronological timeline view displaying recent household actions |
| Activity_Event | A single recorded action (approval, capture, edit, completion, cancellation) |
| Actor | The family member who performed an action (resolved from auth user) |
| Activity_Card | A UI component rendering a single Activity_Event in the timeline |
| Activity_Collection | Firestore subcollection `households/{householdId}/activityEvents/` |
| Activity_Type | One of: capture, approval, autoApproval, edit, completion, cancellation |

---

## Data Model

### Activity Event Document

```
households/{householdId}/activityEvents/{id}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | string | yes | Auto-generated document ID |
| householdId | string | yes | Parent household |
| activityType | string | yes | capture, approval, autoApproval, edit, completion, cancellation |
| actorId | string | yes | Firebase Auth UID or "system" for auto-approval |
| actorName | string | yes | Resolved at write-time from primaryParent member |
| title | string | yes | Human-readable action title |
| subtitle | string | no | Additional context |
| childId | string | no | Affected child's member ID |
| childName | string | no | Affected child's name |
| relatedItemId | string | no | The item this event is about |
| sourceMessageId | string | no | For capture events — the source message ID |
| metadata | map | no | Activity-type-specific data |
| createdAt | timestamp | yes | When the action occurred |

### Metadata Examples

| activityType | metadata contents |
|-------------|-------------------|
| capture | `{ itemCount: 3, inputMethod: "email" }` |
| edit | `{ changedFields: ["date", "location"] }` |
| approval | `{}` |
| autoApproval | `{}` |
| completion | `{}` |
| cancellation | `{}` |

---

## Requirements

### 1. Record Household Activity Events

**User Story:** As a parent, I want household actions to be automatically recorded as activity events, so that I can see what has happened without manually logging anything.

**Acceptance Criteria:**

1. WHEN a parent approves an item → create Activity_Event with actor, item title, child name (if assigned), timestamp
2. WHEN a source message is processed and items extracted → create Activity_Event with actor, item count, input method, timestamp
3. WHEN a parent marks an item as completed → create Activity_Event with actor, item title, child name (if assigned), timestamp
4. WHEN a parent cancels an item → create Activity_Event with actor, item title, child name (if assigned), timestamp
5. WHEN a parent edits a confirmed item → create Activity_Event with actor, item title, changed field names, timestamp
6. WHEN auto-approval confirms a high-confidence item → create Activity_Event with actorId "system", item title, child name (if assigned), timestamp
7. Each Activity_Event stored in `activityEvents/` subcollection
8. IF the Activity_Event write fails → originating action still completes successfully (fire-and-forget)

---

### 2. Activity Event Data Structure

**Acceptance Criteria:**

1. Fields: id, householdId, activityType, actorId, actorName, title, subtitle, childId, childName, relatedItemId, sourceMessageId (optional), metadata, createdAt
2. activityType enum: capture, approval, autoApproval, edit, completion, cancellation
3. Store actorId + actorName (no extra lookups at read time)
4. Store childId + childName (no extra lookups at read time)
5. metadata stores type-specific details (changed fields, item count, input method)
6. In single-user mode: actorName resolved from family member with role primaryParent, falling back to auth user displayName

---

### 3. Display Activity Timeline

**User Story:** As a parent, I want to see a chronological timeline of recent household activity.

**Acceptance Criteria:**

1. Reverse chronological order (newest first)
2. Grouped by relative date: "Today", "Yesterday", formatted date for older (e.g., "Wed, 9 Jul")
3. Each card shows: actor avatar, action description, child chip (if set), relative timestamp
4. Avatar: photoUrl if available, else colored circle with first initial
5. Timestamps: "2 min ago" (<60 min), "3:45 PM" (same day, >60 min), time only (previous days)
6. Initial load: 50 events max. Scroll to bottom → load next 50 (cursor pagination)
7. Empty state: "No activity yet. Capture something to get started." with icon

---

### 4. Activity Card Content Formatting

**User Story:** As a parent, I want descriptions to read naturally like a family story, not a system log.

**Formats:**

| activityType | Format | Child chip? |
|-------------|--------|-------------|
| approval | "[Actor] approved [title]" | Yes (if childName set) |
| capture | "[Actor] captured [N] item(s) from [method]" | No |
| completion | "[Actor] completed [title]" | Yes (if childName set) |
| cancellation | "[Actor] cancelled [title]" | Yes (if childName set) |
| edit | "[Actor] updated [title]" + up to 2 field names, "+ N more" if >2 | No |
| autoApproval | "Auto-approved [title]" + sparkle ✨ | Yes (if childName set) |

**Rules:**
- If childName is null → omit child chip entirely
- No duplicate Activity_Events for same activityType + relatedItemId within 5 seconds

---

### 5. Navigation and Placement

**User Story:** As a parent, I want to access the activity feed easily without disrupting my workflow.

**Acceptance Criteria:**

1. Accessible as a toggle/tab at the top of the Feed screen ("Feed" | "Activity")
2. Switches inline (no page navigation). Loads within 2 seconds.
3. Switching back to Feed preserves Activity scroll position (per session)
4. Opening Activity tab resets unread badge to zero
5. Unread badge shows count (up to 99, then "99+")
6. Last-viewed timestamp stored in SharedPreferences (resets on reinstall)
7. Activity load failure shows error + retry, doesn't affect Feed view

---

### 6. Tap Navigation

**User Story:** As a parent, I want to tap an activity event to see the related item.

**Acceptance Criteria:**

1. Tap card with item status confirmed/completed/cancelled → Item Detail screen
2. Tap card with item status pendingReview → Review Detail screen
3. Tap card with deleted/unavailable item → inline message "This item is no longer available" for 3s
4. Tap capture card with pending items → Review Detail for that source message
5. Capture cards disabled while source is still processing (pending/processing status)

---

### 7. Real-Time Updates

**User Story:** As a parent, I want the feed to update in real time.

**Acceptance Criteria:**

1. Firestore real-time listener on activityEvents/ (events arrive within 3s of write)
2. New event while viewing → prepend with fade-in animation (200-400ms)
3. New event while NOT viewing → increment unread badge (max 99)
4. Network disconnect → show offline indicator, auto-reconnect on restore
5. Returning to Activity with unread > 0 → reset badge, show all events in position

---

### 8. Performance

**Acceptance Criteria:**

1. Composite Firestore index on householdId + createdAt (descending)
2. Initial query: max 50 docs, render within 2 seconds
3. Pagination: cursor-based (startAfter), non-blocking
4. Loading indicator shown while fetching more
5. Query timeout (10s) → "Couldn't load activity. Tap to retry."

---

### 9. Multi-User Readiness

**Acceptance Criteria:**

1. actorId = Firebase Auth UID (or "system")
2. actorName resolved at write-time (no extra reads at display)
3. householdId as top-level field (queryable without joins, no migration later)
4. Security rules: any authenticated household member can read all events
5. Write access: only UID matching actorId, or Cloud Functions for system events
6. Stale actorId (member removed) → display using stored actorName, no error

---

### 10. Retention

**Acceptance Criteria:**

1. Default view: last 30 days
2. Scroll to bottom → can load up to 90 days back
3. Scheduled Cloud Function deletes all events >90 days old
4. Never delete events <90 days old via automation

---

## UI Design Notes

### Feed Screen Toggle

```
┌──────────────────────────────────┐
│  [Feed]  [Activity •3]           │  ← toggle with unread badge
├──────────────────────────────────┤
│                                  │
│  Today                           │
│  ┌────────────────────────────┐  │
│  │ 🟣 Hassan approved         │  │
│  │   "Football training"      │  │
│  │   [Adam]  ·  2 min ago     │  │
│  └────────────────────────────┘  │
│  ┌────────────────────────────┐  │
│  │ ✨ Auto-approved           │  │
│  │   "Dentist appointment"    │  │
│  │   [Yara]  ·  1h ago       │  │
│  └────────────────────────────┘  │
│                                  │
│  Yesterday                       │
│  ┌────────────────────────────┐  │
│  │ 🟣 Hassan captured         │  │
│  │   3 items from email       │  │
│  │   ·  3:45 PM               │  │
│  └────────────────────────────┘  │
│                                  │
└──────────────────────────────────┘
```

### Activity Card Structure

```
┌─────────────────────────────────────────┐
│  [Avatar]  [Action text]                │
│            [Item title — bold]          │
│            [Child chip]  ·  [Timestamp] │
└─────────────────────────────────────────┘
```

### Design System

- Card background: `AppColors.cardBackground`
- Actor avatar: member color circle (10px radius) or photo
- Child chip: colored background matching child's color + white text
- Timestamp: `AppColors.textMuted`, 11px
- Action text: `AppColors.textSecondary`, 13px
- Item title: `AppColors.textPrimary`, 14px, semi-bold
- Auto-approval sparkle: `✨` emoji or `Icons.auto_awesome` in `AppColors.warmYellow`
- Date headers: `AppColors.textSecondary`, 12px, uppercase, letter-spaced

---

## Implementation Notes

### Where to write Activity_Events

Activity events are written client-side (in the item repository methods) as fire-and-forget:

- `approve()` → write approval event
- `updateItem()` (on confirmed items) → write edit event
- `deleteItem()` / cancel flows → write cancellation event
- `markComplete()` → write completion event
- Cloud Function `extractSourceMessage` → write capture event (server-side)
- Cloud Function auto-approval → write autoApproval event (server-side)

### Firestore Index Needed

```
Collection: activityEvents
Index: householdId ASC, createdAt DESC
```

### File Structure (feature-first)

```
lib/features/activity/
├── data/
│   ├── models/
│   │   └── activity_event_model.dart
│   └── repositories/
│       └── activity_repository.dart
├── presentation/
│   ├── activity_feed_view.dart
│   └── widgets/
│       ├── activity_card.dart
│       └── activity_empty_state.dart
└── providers/
    └── activity_providers.dart
```

# Notification Strategy

## Purpose

Notifications are the only way Nabbo reaches the parent **outside the app**. They must earn trust by being useful, timely, and rare.

> Notify when action is needed. Stay quiet when information can wait.

---

## Core Rules

1. **No action, no notification** — system events (processed, stored) are not user events
2. **High urgency should be rare** — if everything is urgent, nothing is
3. **Every notification opens the right screen** — never the generic home
4. **Group related items** — don't send 5 alerts for one event
5. **Suppress after action** — once done/dismissed, stop notifying
6. **Default to quiet** — users opt-in to more, not opt-out of less

---

## Notification Types

### 1. Items Need Review

New items extracted from a capture that need parent approval.

| Trigger | Example | Priority |
|---------|---------|----------|
| AI extracted items with deadline today/tomorrow | "School trip found — form due tomorrow" | High |
| AI extracted items (general) | "3 items to review" | Medium |
| AI detected a change to existing item | "Football training moved to 18:30" | High |

**Opens:** Review Detail screen for that source message.

### 2. Deadline Approaching

A confirmed deadline or task with a date that's coming up.

| Trigger | Example | Priority |
|---------|---------|----------|
| Deadline due today | "Permission form due today" | High |
| Deadline due tomorrow | "Enroll in summer school — due tomorrow" | Medium |
| Deadline in 3 days (optional) | "Payment due in 3 days" | Low |

**Opens:** Item Detail screen.

### 3. Event Reminder

A confirmed event is coming up soon.

| Trigger | Example | Priority |
|---------|---------|----------|
| Event in 1 hour | "Basketball in 1 hour at Sports Hall" | High |
| Event tomorrow morning | "Dentist tomorrow at 9:00" | Medium |

**Opens:** Item Detail screen.

### 4. Daily Brief (opt-in)

A morning summary of what's happening today.

| Trigger | Example | Priority |
|---------|---------|----------|
| 7:30 AM (configurable) | "Today: 3 events, 1 deadline. Yara has swimming at 16:00." | Low |

**Opens:** Feed screen.

---

## What We Do NOT Notify About

- Item processed/stored (system event)
- Item approved (user just did this)
- Low-priority future events (they're in the Feed)
- Routine suggestions
- Items without dates (they sit in the Feed quietly)
- Completed/hidden items

---

## Timing

| Window | What gets sent |
|--------|---------------|
| **Morning (7:30)** | Daily brief (opt-in), deadlines due today |
| **Midday (12:00)** | Deadlines due today still unresolved |
| **Afternoon (15:00)** | Event reminders for today's after-school activities |
| **Evening (19:00)** | Tomorrow's events and deadlines |

Notifications outside these windows only for:
- Newly extracted items with HIGH urgency (deadline today/change today)
- Time-sensitive changes (event in next 2 hours moved/cancelled)

### Quiet Hours

Default: 22:00 — 07:00. No notifications.
Exception: none (not even high priority during quiet hours — it can wait until morning).
User configurable.

---

## Notification Content

### Format

```
Title: Short, specific (what)
Body: Context + action (why + what to do)
```

### Examples

| Good ✅ | Bad ❌ |
|---------|--------|
| "Basketball moved to 18:30" | "You have updates" |
| "Yara needs €5 for school tomorrow" | "Nabbo needs attention" |
| "Permission form due tomorrow" | "Check Nabbo for details" |
| "3 items to review from school email" | "New items processed" |
| "Dentist at 4pm today — pick up Adam early" | "Reminder" |

---

## Grouping

Don't send multiple notifications for the same source:

**Bad:**
- "Football training on Friday"
- "Bring blue jersey"
- "Bring size 4 ball"
- "Pickup owner missing"

**Good:**
- "Football Friday at 18:30 — 2 items to pack, pickup needs owner"

Group by: source message, event, child, time window.

---

## Deep Linking

| Notification | Opens |
|-------------|-------|
| Items to review | Review Detail (source message) |
| Deadline approaching | Item Detail |
| Event reminder | Item Detail |
| Change detected | Review Detail (for the change proposal) |
| Daily brief | Feed screen |

---

## Implementation Architecture

### In-App Notification Center

The app has a **Notifications tab** (bell icon with badge) accessible from the Feed header. This is NOT a separate bottom nav tab — it's a screen opened from the Feed.

```
Feed Header:
┌────────────────────────────────────────────────────┐
│  Good evening, Hassan            🔔 (3)   🌤 22°  │
│  Your family feed                                  │
└────────────────────────────────────────────────────┘
```

The bell icon shows an unread badge count. Tapping opens the Notifications screen.

### Notifications Collection

```
households/{householdId}/notifications/{id}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Auto-generated |
| `type` | string | `review_needed`, `deadline`, `event_reminder`, `change_detected`, `daily_brief` |
| `title` | string | Short notification title |
| `body` | string | Notification body text |
| `itemId` | string? | Related item ID (for deep linking) |
| `sourceMessageId` | string? | Related source message ID |
| `priority` | string | `high`, `medium`, `low` |
| `read` | boolean | Whether user has seen it |
| `actedOn` | boolean | Whether user took action (approved, completed, etc.) |
| `createdAt` | Timestamp | When notification was created |
| `expiresAt` | Timestamp? | Auto-dismiss after this time (optional) |

### Notifications Screen

Shows a chronological list of notifications (newest first):

```
┌────────────────────────────────────────────────────┐
│  ← Notifications                     Mark all read │
├────────────────────────────────────────────────────┤
│                                                    │
│  ● 3 items to review                    2 min ago  │
│    From school email about summer school           │
│                                                    │
│  ● Basketball moved to 18:30           30 min ago  │
│    Adam's training time changed                    │
│                                                    │
│  ○ Permission form due tomorrow         2 hrs ago  │
│    Already reviewed                                │
│                                                    │
│  ○ Dentist tomorrow at 9:00             5 hrs ago  │
│    Event reminder                                  │
│                                                    │
└────────────────────────────────────────────────────┘
```

- **● Unread** — bold, with dot indicator
- **○ Read** — normal weight, no dot
- Tap → opens the relevant item/review screen
- Swipe to dismiss individual notifications
- "Mark all read" button in header

### Badge Count

- Badge = count of unread notifications where `read == false`
- Shown on the bell icon in Feed header
- Updated in real-time via Firestore stream
- Resets when user opens Notifications screen (marks visible ones as read)

### Notification Flow

```
1. Trigger occurs (extraction complete, deadline approaching, etc.)
2. Cloud Function:
   a. Writes notification document to notifications/ subcollection
   b. Sends FCM push notification to device
3. App:
   a. Push notification shows on device (if app is in background)
   b. In-app badge updates via Firestore stream
   c. Tapping push notification → deep links to item
   d. Tapping bell icon → opens Notifications screen
```

### Push Notification (FCM)

Push notifications are sent **in addition to** the in-app notification. They serve as the external trigger when the app is closed.

```javascript
{
  token: userFcmToken,
  notification: {
    title: "Basketball moved to 18:30",
    body: "Adam's training time changed. Tap to review."
  },
  data: {
    type: "change_detected",
    householdId: "...",
    itemId: "...",
    notificationId: "..." // links to in-app notification
  },
  apns: {
    payload: {
      aps: { sound: "default", badge: unreadCount }
    }
  }
}
```

---

## Suppression Rules

Stop notifying when:
- Item is approved (review notification suppressed)
- Item is completed/hidden (deadline reminder suppressed)
- Item is cancelled (event reminder suppressed)
- User has already opened the item since last notification
- Source message is dismissed

---

## User Settings

### Notification Preferences (in Settings)

| Setting | Default |
|---------|---------|
| Items need review | ✅ On |
| Deadline reminders (today) | ✅ On |
| Deadline reminders (tomorrow) | ✅ On |
| Event reminders (1 hour before) | ✅ On |
| Change detected | ✅ On |
| Daily morning brief | ❌ Off |
| Quiet hours start | 22:00 |
| Quiet hours end | 07:00 |

Stored on household document:
```json
{
  "notificationPrefs": {
    "reviewAlerts": true,
    "deadlineToday": true,
    "deadlineTomorrow": true,
    "eventReminders": true,
    "changeAlerts": true,
    "dailyBrief": false,
    "quietStart": "22:00",
    "quietEnd": "07:00"
  }
}
```

---

## Priority → Behavior

| Priority | Behavior |
|----------|----------|
| High | Send immediately (respects quiet hours), sound + badge |
| Medium | Send in next time window, sound + badge |
| Low | No push notification — lives in app only (Feed, daily brief) |

---

## Implementation Phases

### Phase 1: In-App Notification Center
- Create `notifications/` subcollection in Firestore
- Bell icon with badge in Feed header
- Notifications screen (list of notifications, mark as read, tap to navigate)
- Badge count via Firestore stream

### Phase 2: Cloud Function Triggers
- After extraction: write notification to `notifications/` + send FCM push
- Hourly deadline check: write notification for deadlines due in 24h
- Change detection: write notification when `action: update/cancel`
- Event reminders: check for confirmed events in next 2 hours

### Phase 3: Push Notifications (FCM)
- Reliable FCM token registration on iOS/Android
- Push notification sent alongside in-app notification
- Deep linking: tapping push opens specific item/review screen
- Badge count on app icon

### Phase 4: User Preferences
- Notification settings screen (toggle per type)
- Quiet hours configuration
- Daily brief opt-in (morning summary at configured time)

### Phase 5: Smart Features (future)
- Grouping (one notification per source, not per item)
- Suppression (auto-dismiss after user acts)
- Per-owner notifications (when multi-user)
- Smart timing (learn user patterns)

---

## Metrics

| Metric | Target |
|--------|--------|
| Notification open rate | > 40% |
| Action within 5 min of notification | > 25% |
| Notifications per day per household | 2-5 |
| Mute/disable rate | < 10% |
| Notifications that lead to approval | > 60% |

**The goal: every notification makes the parent think "glad I saw that" not "another alert."**

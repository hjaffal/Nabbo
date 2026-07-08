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

### Current (v1)

```
Cloud Functions → FCM → Device
```

Two triggers:
1. **`extractSourceMessage`** — sends notification after items are created (already implemented)
2. **`checkDeadlines`** — scheduled hourly, checks for deadlines in next 24h (already implemented)

### Needed additions

3. **Event reminders** — scheduled function checks for confirmed events in next 2 hours
4. **Daily brief** — scheduled function at 7:30 AM (user timezone), compiles summary
5. **Change notifications** — sent immediately when AI detects `action: update/cancel`

### Notification Payload

```javascript
{
  token: userFcmToken,
  notification: {
    title: "Basketball moved to 18:30",
    body: "Adam's training changed from 17:00. Tap to review."
  },
  data: {
    type: "review_needed | deadline | event_reminder | daily_brief | change_detected",
    householdId: "...",
    itemId: "..." // for deep linking
  },
  apns: {
    payload: {
      aps: { sound: "default", badge: unreadCount }
    }
  }
}
```

### FCM Token Storage

```
userTokens/{userId}/
  fcmToken: "device-token"
  updatedAt: Timestamp
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

### Phase 1 (done)
- ✅ Notification after extraction (items to review)
- ✅ Hourly deadline check (24h window)

### Phase 2 (next)
- Event reminders (2 hours before confirmed events)
- Change notifications (immediate when `action: update/cancel`)
- Better grouping (count of items, not one per item)

### Phase 3 (later)
- Daily brief (morning summary)
- User notification preferences (settings screen already exists)
- Deep linking to specific items
- Badge count management

### Phase 4 (future)
- Per-owner notifications (when multi-user)
- Smart timing (learn when user acts, send at that time)
- Escalation for ignored deadlines

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

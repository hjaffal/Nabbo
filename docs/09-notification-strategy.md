# Notification Strategy

## Purpose

Notifications are critical but dangerous. A good notification helps a parent act before something is missed. A bad notification becomes another source of noise.

Nabbo must not behave like a generic reminder app. It should notify only when the message protects the household from forgetting, delay, confusion, or missed ownership.

> Notify when action is needed. Stay quiet when information can wait.

---

## Core Principle

**Every Nabbo notification must have a clear action. No action, no notification.**

The product should not send notifications just because something was processed, stored, categorized, or updated. Those are system events, not user events.

**Good:** "Training time changed. Review needed."
**Bad:** "Nabbo processed your content."

---

## Philosophy

Parents already receive too many alerts from schools, WhatsApp, email, activity groups, work apps, and family chats. Nabbo should not add another stream of interruptions.

The product should act like a **calm household assistant** — surfacing important items at the right time, to the right person, with the right action.

Notifications should be **rare enough to be trusted**. If Nabbo sends too many alerts, parents will ignore them. Once ignored, the product loses one of its strongest execution tools.

---

## Notification Types

### 1. Review Needed

Nabbo found something that needs confirmation before entering the household plan.

> "School trip found. Review needed."

Use when: item is important, uncertain, or time-sensitive.

### 2. Change Detected

New information may update an existing plan. **One of the highest-value types** — parents often miss changes hidden in messages.

> "Football training changed from 17:00 to 18:30."

Show old and new values when possible. "Training changed: 17:00 → 18:30" is better than "Training updated."

### 3. Deadline Risk

A form, payment, reply, or task is due soon.

> "Permission form due tomorrow. Owner missing."

Use only when the deadline is near and action is still open.

### 4. Owner Gap

Something important has no assigned owner.

> "Pickup at 18:30 has no owner."

Central to Nabbo's value. A task without an owner is a risk.

**Tone must be neutral — no blame.**
- ❌ "You forgot to assign pickup."
- ✅ "Pickup still needs an owner."

### 5. Preparation Needed

Something must be packed, brought, signed, paid, or prepared before an event.

> "Pack Adam's blue jersey and size 4 ball before football."

Timed around useful preparation windows, not sent randomly. Group related items:
- ❌ "Bring towel." / "Bring goggles." / "Bring shampoo."
- ✅ "Swimming tomorrow: pack towel, goggles, and shampoo."

### 6. Daily Brief

Short view of the day or tomorrow.

> "Today: 4 events, 2 checklist items, 1 owner gap."

Opt-in or configurable. Not every parent wants a morning summary. Should answer: what's happening, what needs action, what must be brought, what has no owner, what changed, what's at risk.

---

## Priority Levels

### High Priority (interrupt immediately)

- Time change for today
- Location change for today
- Pickup owner missing
- Deadline due today
- Required item needed soon
- Conflicting events

### Medium Priority (useful but not urgent)

- Deadline due tomorrow
- Payment due tomorrow
- Form due in two days
- Checklist for tomorrow
- New review item with no immediate deadline

### Low Priority (should not interrupt)

- Future event added
- Routine suggestion
- Non-urgent checklist improvement
- General weekly planning item

Low-priority items live inside the app or daily brief — not as push notifications.

---

## Timing Strategy

Notifications should match family pressure points:

| Window | Focus | Examples |
|--------|-------|----------|
| **Morning** | Today's launch | School bags, forms due today, items to bring, drop-off/pickup ownership |
| **Midday** | Upcoming deadlines & after-school logistics | Activity changes, pickup assignments, payments due today |
| **After-school** | Movement and preparation | Leave time, sports gear, activity location, owner gaps |
| **Evening** | Tomorrow preparation | Pack for tomorrow, forms due, early departures, payments due |
| **Weekend** | Irregular plans | Tournaments, trips, family events, weekend checklists |

**Avoid late-night notifications** unless explicitly configured by the user.

---

## Default Configuration

### Enabled by default
- Urgent review items
- Same-day changes
- Deadline due today
- Owner missing for today
- Required items for today

### Optional (user enables)
- Morning brief
- Evening reset
- Weekly family brief
- Deadline due tomorrow
- Preparation reminders

### Disabled by default
- Routine suggestions
- Low-priority future events
- General product updates
- Non-actionable summaries

The default experience should feel useful, not loud.

---

## Notification Rules by Type

### Review Notifications

**Send when:**
- Captured input creates an important item
- Item has deadline today or tomorrow
- Item changes time, date, or location
- Item contains form, payment, pickup, drop-off, or required item
- Item has low-confidence fields needing review

**Do NOT send when:**
- Item is low priority and not time-sensitive
- Extraction found no clear action
- Input is a duplicate
- Item can wait for next daily brief

### Change Notifications

**Send immediately when detecting:**
- Time, date, or location changed
- Event cancelled
- Required item added for today/tomorrow
- Deadline changed
- Pickup/drop-off information changed

### Deadline Notifications

**Send when:**
- Form, payment, or reply due today/tomorrow
- Task is overdue
- Deadline has no owner

**Do NOT notify** about deadlines already completed.

### Preparation Notifications

**Send based on:**
- Event time
- Required items and checklist status
- Owner assignment
- User preference
- Typical family routine

**Group related items** — don't send one notification per item.

---

## Content Rules

Notifications must be **short, specific, and action-oriented**.

**Good structure:** Object + action.

| ✅ Good | ❌ Bad |
|---------|--------|
| "Yara needs €5 tomorrow." | "You have updates." |
| "Football pickup has no owner." | "Nabbo needs your attention." |
| "Training moved to 18:30." | "New family item processed." |
| "Pack blue jersey and size 4 ball." | "Reminder from Nabbo." |
| "Permission form due tomorrow." | "Check Nabbo for details." |

The parent should understand the value **before opening the app**.

---

## Deep Link Rules

Every notification must open the **relevant place** in the app:

| Notification Type | Opens |
|------------------|-------|
| Review needed | Review Card |
| Deadline | Deadline item |
| Checklist / preparation | Checklist view |
| Change detected | Change Card |
| Owner gap | Assignment action |
| Daily brief | Today Command Center |

**Never** open the generic home screen unless there is no specific object. Notifications must reduce navigation, not add it.

---

## Grouping Rules

Group low and medium-priority notifications. Don't send five separate alerts for the same event.

**Bad:**
- "Bring water."
- "Bring jersey."
- "Bring ball."
- "Football at 18:30."
- "Pickup owner missing."

**Better:**
- "Football at 18:30: pack 3 items. Pickup owner missing."

Group by: event, child, time window, checklist, deadline, urgency.

High-priority changes can still be sent separately when needed.

---

## Quiet Hours

Support quiet hours — default avoids late-night alerts.

During quiet hours, only critical same-day or next-morning risks are allowed (if user enables):
- Tomorrow morning event has no owner
- Required item for early morning event not ready
- Important deadline expires before next normal notification window

Late notifications damage trust quickly.

---

## Suppression Rules

Suppress notifications when no longer useful:

- Task completed
- Payment marked paid
- Form submitted
- Item packed
- Event cancelled
- Risk dismissed
- Item snoozed
- User already opened and acted on the item

**Notifications that continue after completion are a fast way to lose trust.**

---

## Notification Ownership (Future)

When multi-user households are supported:
- Hasan owns pickup → Hasan gets pickup reminder
- Sara owns payment → Sara gets payment reminder
- Yara owns packing → Yara gets simple checklist reminder

The primary parent should not receive every notification forever — that recreates the mental load Nabbo is meant to reduce.

**v1:** Owner labels shape the Today view, but notifications go to primary user only.

---

## Escalation (Future)

Light escalation for unresolved items:
1. First alert goes to owner
2. If no action taken → remind again near deadline
3. If still unhandled → show as risk in Today

Escalation should be conservative. The product must **not** become a nagging system.

---

## Personalization (v1)

Users can configure by category:
- Review alerts
- Change alerts
- Deadline alerts
- Owner gap alerts
- Preparation reminders
- Morning brief
- Evening reset
- Weekly brief
- Quiet hours
- Reminder timing

Per-child or per-activity configuration can come later. Keep settings simple for v1.

---

## Metrics

| Metric | What It Measures |
|--------|-----------------|
| Notification open rate | Relevance |
| Action rate after notification | Usefulness |
| Dismiss rate | Noise level |
| Mute rate | Trust damage |
| Category opt-out rate | Category quality |
| Time from notification to action | Efficiency |
| Repeated ignored notifications | Fatigue |
| Notifications per household per day | Volume control |

**High volume is not success. The strongest metric is action rate.**

A good notification leads to: review, assignment, completion, packing, payment, or risk resolution.

---

## Failure Modes

The notification strategy fails if:
- Nabbo becomes noisy
- Users mute notifications
- Notifications are vague
- Notifications open the wrong screen
- Completed items keep triggering alerts
- Everything feels urgent
- Owner gaps feel like blame
- System updates are sent instead of action prompts

> The worst version of Nabbo is another app demanding attention.
> The best version is a quiet system that interrupts only when it prevents a miss.

---

## Product Rules

1. No action, no notification
2. High urgency should be rare
3. Changes matter more than routine updates
4. Owner gaps matter when timing or responsibility matters
5. Group related items
6. Suppress completed items
7. Deep-link every notification
8. Avoid vague wording
9. Avoid blame
10. Default to quiet
11. Let users control notification categories
12. Measure action, not opens

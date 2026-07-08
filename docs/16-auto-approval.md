# Auto-Approval Design

## Purpose

Not every extracted item needs manual review. When the AI is highly confident about an extraction — clear date, matched child, known activity — the item can skip review and go directly to `confirmed` status.

This reduces friction for the parent. Fewer items to review = faster workflow. The parent still sees everything in the Feed and can edit or undo at any time.

---

## Core Principle

**Auto-approve when the AI is sure. Ask when it's not.**

- High confidence + familiar pattern → auto-confirm
- Low confidence or new/unusual content → needs review
- The parent always has visibility (item shows in Feed immediately)
- The parent can always undo (edit or cancel any auto-approved item)

---

## How It Works

### AI Returns Confidence

The AI already returns a `confidence` map per field. For auto-approval, we need an **overall extraction confidence** score:

```json
{
  "type": "event",
  "title": "Basketball training",
  "overallConfidence": "high",
  "confidence": {
    "date": "high",
    "childName": "high",
    "location": "high"
  },
  ...
}
```

### Auto-Approval Decision (in Cloud Function)

After extraction, before writing items:

```
For each extracted item:
  IF overallConfidence == "high"
     AND no uncertainFields
     AND action == "create" (not update/cancel — those always need review)
     AND household has autoApproval enabled
  THEN:
     status = "confirmed"  (skip pendingReview)
  ELSE:
     status = "pendingReview"  (needs review as usual)
```

### What Makes "High Confidence"

| Condition | Required for auto-approval |
|-----------|---------------------------|
| All key fields have confidence "high" | ✅ Yes |
| `uncertainFields` array is empty | ✅ Yes |
| `childName` matched a known family member | ✅ Yes |
| Item has a date | ✅ Yes |
| Action is "create" (not update/cancel) | ✅ Yes |
| Activity matches household intelligence | Bonus (not required) |

### What Forces Manual Review (never auto-approve)

| Condition | Why |
|-----------|-----|
| Any field has confidence "low" or "unknown" | Too risky |
| `uncertainFields` is not empty | Needs user verification |
| Action is "update" or "cancel" | Changes to existing items always need confirmation |
| No date detected | Parent needs to set when |
| No child detected | Parent needs to assign who |
| Item type is "deadline" | Deadlines are too important to auto-approve |
| Household has autoApproval disabled | User preference |

---

## User Setting

A toggle in Settings → Notifications/Preferences:

```
Auto-approve high-confidence items
When Nabbo is very sure about an extraction, it skips review
and adds the item directly to your feed.
[ Toggle: ON/OFF ]  Default: OFF
```

Stored on household document:

```json
{
  "autoApproval": true
}
```

**Default: OFF** — the parent must opt-in. Trust is built first by reviewing, then the parent chooses to trust the system.

---

## UI Behavior

### Feed Card for Auto-Approved Items

Auto-approved items appear in the Feed with a subtle "Auto" indicator:

```
┌────────────────────────────────────────────────────┐
│  🏀 Basketball training              Active  ✨   │
│     📍 Sports Hall  •  18:30                      │
│     [Adam]  [Hassan]                              │
└────────────────────────────────────────────────────┘
```

The ✨ sparkle (or small "Auto" label) indicates it was auto-approved. This disappears after 24 hours or after the user views the item.

### Notification for Auto-Approved Items

Instead of "3 items to review", the notification says:

> "Basketball training added to Friday" (auto-approved)

Or grouped:

> "2 items auto-confirmed, 1 needs review"

### Undo

If the parent disagrees with an auto-approved item:
- Tap the item → Item Detail → Edit or Cancel
- Swipe right → Cancel this occurrence
- No different from any other confirmed item

---

## Data Model Change

Add to item document:

| Field | Type | Description |
|-------|------|-------------|
| `autoApproved` | boolean | `true` if this item was auto-approved (for UI indicator) |

Add to household document:

| Field | Type | Description |
|-------|------|-------------|
| `autoApproval` | boolean | `true` if household has auto-approval enabled |

Add to AI output schema:

| Field | Type | Description |
|-------|------|-------------|
| `overallConfidence` | string | `high`, `medium`, `low` — overall extraction quality |

---

## Cloud Function Logic

```javascript
// After extraction, for each item:
const shouldAutoApprove = 
  householdData.autoApproval === true &&
  item.overallConfidence === 'high' &&
  (!item.uncertainFields || item.uncertainFields.length === 0) &&
  item.action === 'create' &&
  item.type !== 'deadline' &&
  item.childName != null &&
  item.date != null;

batch.set(itemRef, {
  ...itemData,
  status: shouldAutoApprove ? 'confirmed' : 'pendingReview',
  autoApproved: shouldAutoApprove || null,
});
```

### Notification Adjustment

When some items are auto-approved and some need review:

```javascript
const autoApproved = items.filter(i => i.autoApproved);
const needsReview = items.filter(i => !i.autoApproved);

if (needsReview.length > 0) {
  // "2 items auto-confirmed, 1 needs review"
  notify({ type: 'review_needed', ... });
} else {
  // "Basketball training added to Friday"
  notify({ type: 'auto_confirmed', title: autoApproved[0].title, ... });
}
```

---

## Household Intelligence Integration

Auto-approval becomes MORE confident when household intelligence supports it:

- Item matches a known activity for a known child → stronger confidence
- Email from a known sender associated with a child → stronger confidence
- Recurring item matches existing pattern → very high confidence

Over time, as associations grow, more items qualify for auto-approval.

---

## Safety Guards

1. **Deadlines never auto-approve** — too important, parents must acknowledge
2. **Changes/cancellations never auto-approve** — modifying existing plans needs confirmation
3. **Default OFF** — parent explicitly opts in
4. **Always visible in Feed** — auto-approved items aren't hidden
5. **Always editable** — parent can fix mistakes
6. **Notification still sent** — parent knows something was added
7. **"Auto" indicator** — transparency about what the system decided

---

## Implementation Phases

### Phase 1: AI + Cloud Function
- Add `overallConfidence` to AI prompt output schema
- Cloud Function checks confidence and sets status accordingly
- Add `autoApproved` field to item document
- Respect `household.autoApproval` setting

### Phase 2: Settings UI
- Add toggle in Settings: "Auto-approve high-confidence items"
- Store `autoApproval` on household document

### Phase 3: Feed UI
- Show subtle "Auto" indicator on auto-approved items (first 24h)
- Notification text adjusted for auto-approved vs needs-review

---

## Examples

### Auto-approved ✅

Input: "Adam has basketball Friday at 18:30 at Sports Hall"
- All fields high confidence
- Child matched: Adam ✓
- Date present: Friday 18:30 ✓
- Known activity (from associations) ✓
- Action: create ✓
- → **Auto-approved** → status: confirmed

### Needs review ⚠️

Input: "There's a school trip next week"
- Date: "next week" → medium confidence (which day?)
- Child: not specified → unknown
- → **Needs review** → status: pendingReview

### Needs review ⚠️

Input: "Basketball moved to Thursday"
- Action: update → always needs review
- → **Needs review** → status: pendingReview

---

## Metrics

| Metric | Target |
|--------|--------|
| Auto-approval accuracy (no user correction needed) | > 95% |
| Percentage of items auto-approved (after 2 weeks) | 40-60% |
| User corrections on auto-approved items | < 5% |
| Time saved per day (fewer reviews) | 2-5 minutes |

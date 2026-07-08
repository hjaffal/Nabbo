# Household Intelligence Layer

## Purpose

Nabbo should understand the household's patterns over time. When a new message arrives without explicitly naming a child, Nabbo should infer who it's about based on historical context — not guess randomly, but reason from evidence.

This is not prompt engineering. This is a **persistent knowledge layer** that grows as the household uses the app.

---

## Core Concept

The household builds a **context graph** — a set of associations between:
- Children ↔ Activities (Adam does basketball, Yara does swimming)
- Children ↔ Schools/Classes (Adam is in Class 4B, Yara is in S2)
- Children ↔ Contacts (Mrs. Schmidt emails about Adam, Coach Mike about Yara)
- Children ↔ Locations (Adam goes to Sports Hall A, Yara to the pool)
- Children ↔ Schedules (Adam has things on Tuesdays, Yara on Thursdays)

When a new message arrives, the AI uses this graph to resolve ambiguity.

---

## Architecture

```
Source Message arrives
        │
        ▼
┌─────────────────────────────┐
│  Load Household Intelligence │
│  (associations from DB)      │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│  Inject into AI Prompt       │
│  as structured context       │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│  Gemini extracts items       │
│  (uses associations to       │
│   resolve ambiguous child)   │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│  After approval: update      │
│  associations (learn)        │
└─────────────────────────────┘
```

---

## Data Model

### Associations Collection

```
households/{householdId}/associations/{id}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Auto-generated |
| `childId` | string | Family member ID |
| `childName` | string | For display |
| `type` | string | `activity`, `contact`, `school`, `location`, `schedule` |
| `value` | string | The associated value (e.g., "basketball", "Mrs. Schmidt", "Sports Hall A") |
| `confidence` | string | `confirmed` (user approved), `inferred` (system learned) |
| `sourceItemIds` | array | Item IDs that established this association |
| `lastSeen` | Timestamp | Last time this association was relevant |
| `count` | number | How many times this association appeared |

### Examples

| childName | type | value | confidence | count |
|-----------|------|-------|------------|-------|
| Adam | activity | basketball | confirmed | 12 |
| Adam | contact | mrs.schmidt@school.lu | confirmed | 3 |
| Adam | location | Sports Hall A | confirmed | 8 |
| Adam | school | Class 4B EIDE | confirmed | 5 |
| Yara | activity | swimming | confirmed | 9 |
| Yara | contact | coach.mike@pool.lu | inferred | 2 |
| Yara | schedule | tuesday 16:00 | confirmed | 9 |

---

## How Associations Are Built

### 1. On Item Approval (primary source)

When a user approves an item that has both a `childName` and relevant context, create/update associations:

```
Item approved:
  title: "Basketball training"
  childName: "Adam"
  location: "Sports Hall A"
  → Create/update: Adam ↔ activity:basketball
  → Create/update: Adam ↔ location:Sports Hall A

Item approved:
  title: "Discuss incident with Yara"
  source email from: mrs.mueller@school.lu
  childName: "Yara"
  → Create/update: Yara ↔ contact:mrs.mueller@school.lu
```

### 2. On Item Approval with Source Email (learn sender)

When an item comes from an email and is approved with a child assigned:
- Extract sender email from the source message
- Associate that sender with that child

### 3. Recurrence Strengthens Associations

When an item has recurrence (e.g., "basketball every Tuesday"):
- Immediately set confidence to `confirmed`
- Increase count

### 4. User Edits Correct Associations

If the user changes `childName` on an item:
- Weaken/remove old association
- Strengthen/create new association

---

## How Associations Are Used (Inference)

### Injected into AI Prompt

Before extraction, load associations and inject them:

```
HOUSEHOLD INTELLIGENCE (use this to resolve which child is affected):
- Adam: basketball, Sports Hall A, Class 4B, mrs.schmidt@school.lu, Tuesdays
- Yara: swimming, the pool, Class S2, coach.mike@pool.lu, Thursdays
```

### Resolution Logic

The AI uses this context for inference:

| Scenario | Input | Resolution |
|----------|-------|-----------|
| Activity match | "Basketball cancelled" | → Adam (he does basketball) |
| Contact match | Email from mrs.schmidt@ | → Adam (she emails about Adam) |
| Location match | "Meet at Sports Hall A" | → Adam (his location) |
| Schedule match | "Thursday session changed" | → Yara (her day) |
| Ambiguous | "Basketball cancelled" but both kids do basketball | → childName: null, uncertainFields: ["childName"], suggestedActions: ["Confirm which child"] |

### Ambiguity Rules

- If ONE child matches → assign with `confidence: high`
- If MULTIPLE children match → set `childName: null`, mark as uncertain, suggest user confirms
- If NO children match → set `childName: null`, mark as uncertain
- NEVER guess when ambiguous. Show the gap clearly.

---

## Conflict Resolution

When two children share an association (both do basketball):

1. Check for **stronger signals** in the message:
   - Sender email → check contact associations
   - Day of week → check schedule associations
   - Location → check location associations
   - Specific class/group mentioned → check school associations

2. If still ambiguous after all signals:
   - Create the item with `childName: null`
   - Add both children's names to `suggestedActions`: "Is this about Adam or Yara?"
   - When user assigns a child → update associations with this new data point

---

## Learning Over Time

### Association Strength

| count | confidence | Behavior |
|-------|-----------|----------|
| 1 | inferred | Low weight in resolution |
| 2-3 | inferred | Medium weight |
| 4+ | inferred → confirmed | High weight, auto-promoted |
| Any | confirmed (user-set) | Highest weight |

### Decay

- Associations not seen in 3+ months get `confidence` downgraded
- Associations contradicted by user edits get removed
- This prevents stale data (child changed activities)

---

## Implementation Phases

### Phase 1: Build Associations on Approval

- After item approval, scan for activity/location/contact patterns
- Write to `associations/` subcollection
- Simple keyword extraction (title → activity, location → location, source sender → contact)

### Phase 2: Inject into Prompt

- Before extraction, load all associations for the household
- Format as structured context in the prompt
- AI uses them for child resolution

### Phase 3: Learn from Emails

- Extract sender from forwarded emails
- Associate sender with child when item is approved
- Future emails from same sender auto-resolve to that child

### Phase 4: Schedule Patterns

- Track which days/times are associated with which child
- Use for resolution when a message mentions a day but no child

### Phase 5: Ambiguity UI ✅

- When AI can't resolve (multiple matches or no match), show a quick picker in the review card
- "Who is this about? [Adam] [Yara] [Both]"
- Selection feeds back into associations
- Picker appears inline in the `_ItemReviewCard` widget when `childName` is null and `uncertainFields` contains "childName"
- Selecting a child updates the item immediately and strengthens associations

---

## What This Does NOT Do

- Does NOT auto-approve items (still requires parent review)
- Does NOT create items without source messages
- Does NOT override explicit child mentions in messages
- Does NOT share associations between households
- Does NOT track the child's location or behavior (only family logistics patterns)

---

## Examples

### Example 1: Known Activity

**Existing associations:** Adam ↔ basketball (confirmed, count: 12)

**New message:** "Training cancelled this week"

**AI reasoning:** "Training" + household has Adam with basketball activity → childName: Adam, confidence: high

**Result:** Item created with childName: "Adam"

---

### Example 2: Known Contact

**Existing associations:** Adam ↔ contact:mrs.schmidt@school.lu (confirmed, count: 3)

**New message:** Email from mrs.schmidt@school.lu: "Dear parents, please prepare for the field trip next Friday."

**AI reasoning:** Sender matches Adam's contact → childName: Adam

**Result:** Item created with childName: "Adam"

---

### Example 3: Ambiguous

**Existing associations:**
- Adam ↔ basketball (confirmed)
- Yara ↔ basketball (confirmed)

**New message:** "Basketball cancelled tomorrow"

**AI reasoning:** Both children do basketball. No other signal (sender, location, day) to disambiguate.

**Result:** Item created with childName: null, uncertainFields: ["childName"], suggestedActions: ["Is this about Adam or Yara?"]

---

### Example 4: Day-Based Resolution

**Existing associations:**
- Adam ↔ basketball (confirmed)
- Adam ↔ schedule:tuesday (confirmed)
- Yara ↔ basketball (confirmed)
- Yara ↔ schedule:thursday (confirmed)

**New message:** "Thursday basketball cancelled"

**AI reasoning:** Both do basketball, but Thursday is Yara's day → childName: Yara

**Result:** Item created with childName: "Yara", confidence: medium

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Child correctly inferred (no edit needed) | > 80% after 2 weeks of use |
| False assignments (wrong child) | < 5% |
| Ambiguous correctly flagged | > 90% |
| Associations built per week (active household) | 5-15 |
| Time for household to reach "smart" state | 2-3 weeks |

---

## Privacy & Trust

- Associations are per-household, never shared
- User can view/edit/delete associations in Settings (future)
- Inferred associations are always low-weight until confirmed
- The app shows WHY it thinks something is about a child (transparency)
- Parent always has final say — inference is a suggestion, not a decision

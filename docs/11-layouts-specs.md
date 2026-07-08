# Layout Specifications

Visual layout specs for key components in the Nabbo app.

---

## Item Card (Feed)

The card that represents a single item in the Feed. Used for all statuses and types.

### Layout

```
┌────────────────────────────────────────────────────┐
│  ┌──────┐  Title                      [Status]    │
│  │ Icon │  📍 Location  •  10:30       badge      │
│  └──────┘  [Child photo+name] [Owner name]        │
└────────────────────────────────────────────────────┘
```

### Elements

| Element | Source | Visibility |
|---------|--------|------------|
| **Type icon** | Item type (event/task/deadline) | Always |
| **Title** | `item.title` | Always |
| **Status badge** | `item.status` → Analyzing / Review / Active / Done / Cancelled | Always |
| **Child** | `item.childName` + child photo (from family member) + member color | If childName not null |
| **Owner** | `item.ownerName` | If ownerName not null |
| **Location** | `item.location` | If not null |
| **Time** | `item.date` formatted as HH:MM | If date has a non-midnight time |
| **Recurrence indicator** | Repeat icon | If item has recurrence rule |

### Child Chip Color

The child chip uses the family member's assigned `color` field and photo:
- If the member has a `photoUrl` → show circular photo avatar (10px radius)
- If no photo → show colored initial circle (background: member color, text: white initial)
- Chip background: member color at 15% opacity
- Name text: member color at full opacity
- If no color set: falls back to primary purple

### Visual States

| Status | Card background | Badge | Opacity |
|--------|----------------|-------|---------|
| Analyzing (source) | Blue tint | "Analyzing" blue | 1.0 |
| `pendingReview` | Yellow tint | "Review" yellow | 1.0 |
| `confirmed` | White/default | "Active" green | 1.0 |
| `completed` | White/default | "Done" green | 0.6 |
| `cancelled` | White/default | "Cancelled" coral | 0.5, title strikethrough |

### Behavior

- Tap pending → opens Review Detail screen
- Tap confirmed/completed/cancelled → opens Item Detail screen
- **Swipe left** → hides the item from Feed (sets `status: hidden`). Works on confirmed, completed, cancelled items.

---

## Source Message Card (Feed — Analyzing state)

Shown while AI is processing. Disappears when items are created.

### Layout

```
┌────────────────────────────────────────────────────┐
│  ┌──────┐  "Adam has football Friday…"  [Analyzing]│
│  │Input │  Analyzing...                    badge   │
│  │ icon │                                          │
│  └──────┘                                          │
└────────────────────────────────────────────────────┘
```

### Elements

| Element | Source | Visibility |
|---------|--------|------------|
| **Input method icon** | `sourceMessage.inputMethod` (text/voice/email/image/share) | Always |
| **Content preview** | `sourceMessage.originalContent` truncated to 80 chars | Always |
| **Subtitle** | "Analyzing..." | Always |
| **Status badge** | "Analyzing" blue | Always |

### Visual

- Blue tinted background
- No child/owner chips (not yet extracted)

---

## Review Card (Review Tab + Review Detail)

Used in the Review tab list and inside the Review Detail screen.

### Layout (Review Tab — compact)

```
┌────────────────────────────────────────────────────┐
│  [Event chip] [Child chip]                    ›    │
│                                                    │
│  Title of the item                                 │
│  Summary text if available                         │
│  ⚠ 2 fields to check                              │
│                                                    │
│  [  Approve  ]  [ Edit ]                           │
└────────────────────────────────────────────────────┘
```

### Layout (Review Detail — expanded)

```
┌────────────────────────────────────────────────────┐
│  [Event chip] [Child chip]                         │
│                                                    │
│  Title of the item                                 │
│  Summary text if available                         │
│                                                    │
│  Date: 11/07/2026 at 18:30                         │
│  Location: Sports Hall                             │
│  Owner: —                                          │
│  ⚠ 1 field to check                               │
│                                                    │
│  [   Approve   ]  [ Edit ]  [ Delete ]             │
└────────────────────────────────────────────────────┘
```

### Elements

| Element | Source | Visibility |
|---------|--------|------------|
| **Type chip** | `item.type` with color (purple/yellow/coral) | Always |
| **Child chip** | `item.childName` | If not null |
| **Title** | `item.title` | Always |
| **Summary** | `item.summary` | If not null |
| **Date** | `item.date` formatted | If not null (expanded only) |
| **Location** | `item.location` | If not null (expanded only) |
| **Owner** | `item.ownerName` or "—" | Expanded only |
| **Uncertainty warning** | Count of `uncertainFields` | If uncertainFields not empty |
| **Approve button** | Primary action | Always |
| **Edit button** | Secondary action | Always |
| **Delete button** | Destructive action | Expanded only |

---

## Item Detail Screen

Full screen opened when tapping a confirmed/completed/cancelled item.

### Layout

```
┌────────────────────────────────────────────────────┐
│  ← Event                                  [Edit]   │
├────────────────────────────────────────────────────┤
│                                                    │
│  ┌──────┐  Title of the event                      │
│  │ Icon │  Summary text if available               │
│  └──────┘                                          │
│                                                    │
│  [Active badge]                                    │
│                                                    │
│  ┌──────────────────────────────────────────────┐  │
│  │  Type         Event                          │  │
│  │  Child        Adam                           │  │
│  │  Owner        Hassan                         │  │
│  │  Date         11/07/2026 at 18:30            │  │
│  │  End date     11/07/2026 at 19:30            │  │
│  │  Location     Sports Hall                    │  │
│  │  Recurrence   weekly on tuesday              │  │
│  └──────────────────────────────────────────────┘  │
│                                                    │
│  ⚠ 1 field may need checking: location             │
│                                                    │
│  [      Mark complete      ]                       │
│  [        Cancel           ]                       │
│                                                    │
└────────────────────────────────────────────────────┘
```

### Elements

| Element | Source | Visibility |
|---------|--------|------------|
| **App bar title** | Item type name | Always |
| **Edit button** | Opens Edit screen | Always (app bar) |
| **Type icon** | Based on `item.type` | Always |
| **Title** | `item.title` (large) | Always |
| **Summary** | `item.summary` | If not null |
| **Status badge** | Colored pill based on `item.status` | Always |
| **Fields card** | All non-null fields as label: value rows | Always |
| **Uncertainty warning** | Yellow card with uncertain field names | If uncertainFields not empty |
| **Mark complete button** | Sets status to completed | If status == confirmed |
| **Cancel button** | Sets status to cancelled | If status == confirmed |
| **Approve button** | Sets status to confirmed | If status == pendingReview |
| **Delete button** | Deletes item | If status == pendingReview |

### Field display rules

- Show all fields that have a value
- Null fields show as "— not set"
- Dates formatted as DD/MM/YYYY at HH:MM
- Recurrence shown as "weekly on tuesday" (human-readable)
- `notes` field shown below other fields (full text, may contain links/URLs)
- `extractedFields` map entries shown as additional key: value rows

---

## Edit Item Screen

Form screen for editing any item at any lifecycle stage.

### Layout

```
┌────────────────────────────────────────────────────┐
│  ← Edit                                  [Save]    │
├────────────────────────────────────────────────────┤
│                                                    │
│  Type                                              │
│  [ Event ] [ Task ] [ Deadline ]                   │
│                                                    │
│  Title                                             │
│  ┌──────────────────────────────────────────────┐  │
│  │ Football training                            │  │
│  └──────────────────────────────────────────────┘  │
│                                                    │
│  Summary                                           │
│  ┌──────────────────────────────────────────────┐  │
│  │ Optional details                             │  │
│  └──────────────────────────────────────────────┘  │
│                                                    │
│  Child (who is this about?)                        │
│  ┌──────────────────────────────────────────────┐  │
│  │ 🟣 Adam                                 ▼   │  │
│  └──────────────────────────────────────────────┘  │
│                                                    │
│  Owner (who is responsible?)                       │
│  ┌──────────────────────────────────────────────┐  │
│  │ 🟢 Hassan                               ▼   │  │
│  └──────────────────────────────────────────────┘  │
│                                                    │
│  Location                                          │
│  ┌──────────────────────────────────────────────┐  │
│  │ 📍 Sports Hall          (autocomplete)       │  │
│  └──────────────────────────────────────────────┘  │
│                                                    │
│  Date & Time                                       │
│  [ 📅 11/07/2026 ]  [ 🕐 18:30 ]                  │
│                                                    │
│  [ End date (optional) ]                           │
│                                                    │
└────────────────────────────────────────────────────┘
```

### Fields

| Field | Input type | Required |
|-------|-----------|----------|
| Type | Segmented button (event/task/deadline) | Yes |
| Title | Text field | Yes |
| Summary | Text field (multiline) | No |
| Child | **Dropdown** — lists children from family members, with color dot + name | No |
| Owner | **Dropdown** — lists adults only (parents/caregivers), with color dot + name | No |
| Location | **Autocomplete** — Google Places autocomplete with text fallback | No |
| Date | Date picker button | No |
| Time | Time picker button | No |
| End date | Date picker button | No |

### Dropdown behavior

- Child dropdown shows family members with role `child`
- Owner dropdown shows family members with role `primaryParent`, `secondaryParent`, `caregiver`, `grandparent`
- Each option shows the member's color dot + initial circle + name
- "— None" option available to clear the selection
- Owner is NEVER a child

### Behavior

- Save writes to Firestore via `ItemRepository.updateItem()`
- Works at any lifecycle stage
- Section labels shown above each field for clarity

---

## Feed Screen

### Layout

```
┌────────────────────────────────────────────────────┐
│  Good morning, Hassan             🔔(3)  🌤 22°   │
│  Your family feed                                  │
├────────────────────────────────────────────────────┤
│                                                    │
│  [Needs Review]                                    │
│  ┌─ Item Card (pendingReview) ─────────────────┐   │
│  └─────────────────────────────────────────────┘   │
│  ┌─ Item Card (pendingReview) ─────────────────┐   │
│  └─────────────────────────────────────────────┘   │
│                                                    │
│  [Today]                                           │
│  ┌─ Item Card (confirmed) ─────────────────────┐   │
│  └─────────────────────────────────────────────┘   │
│  ┌─ Item Card (confirmed) ─────────────────────┐   │
│  └─────────────────────────────────────────────┘   │
│                                                    │
│  [Tomorrow]                                        │
│  ┌─ Item Card (confirmed) ─────────────────────┐   │
│  └─────────────────────────────────────────────┘   │
│                                                    │
│  [Wed, 9 Jul]                                      │
│  ┌─ Item Card (confirmed) ─────────────────────┐   │
│  └─────────────────────────────────────────────┘   │
│                                                    │
└────────────────────────────────────────────────────┘
│  [Feed]  [Review]  [Settings]          [+ FAB]    │
└────────────────────────────────────────────────────┘
```

### Sorting

1. Analyzing source cards (newest first) — top
2. Pending review items — below analyzing
3. Confirmed items grouped by date (today → tomorrow → upcoming)

### Date headers

- Pill-shaped containers with text
- Yellow background for "Needs Review" group
- Grey background for date pills (Today, Tomorrow, Wed 9 Jul)

---

## FAB (Floating Action Button)

### Closed state
- Single "+" button, bottom-right
- Rotates 45° to "×" when open

### Open state (speed dial)

```
                          [Photo] 📷
                          [Voice] 🎤
                          [Text]  📝
                              [×]
```

- 3 mini FABs appear above main FAB with labels
- Text (closest), Voice (middle), Photo (top)
- Tap outside or × to close
- Each opens its respective capture sheet

---

## Review Detail Screen

### Layout

```
┌────────────────────────────────────────────────────┐
│  ← Review                              [Delete]    │
├────────────────────────────────────────────────────┤
│                                                    │
│  ┌─ Original message ──────────────────────────┐   │
│  │  "Adam has football Friday at Sports Hall.  │   │
│  │   Bring blue jersey and water bottle."      │   │
│  └─────────────────────────────────────────────┘   │
│                                                    │
│  2 items to review                                 │
│                                                    │
│  ┌─ Review Card (expanded) ────────────────────┐   │
│  │  [Event] [Adam]                             │   │
│  │  Football training                          │   │
│  │  Date: Friday at 18:30                      │   │
│  │  Location: Sports Hall                      │   │
│  │  [Approve] [Edit] [Delete]                  │   │
│  └─────────────────────────────────────────────┘   │
│                                                    │
│  ┌─ Review Card (expanded) ────────────────────┐   │
│  │  [Task] [Adam]                              │   │
│  │  Bring blue jersey and water bottle         │   │
│  │  [Approve] [Edit] [Delete]                  │   │
│  └─────────────────────────────────────────────┘   │
│                                                    │
└────────────────────────────────────────────────────┘
```

### States

| Source status | What shows |
|--------------|-----------|
| pending/processing | Original message + "Analyzing..." spinner |
| completed | Original message + extracted items with actions |
| failed | Original message + error + "Try again" button |
| noAction | Original message + "No clear action found" |

---

## Notifications Screen

Opened from bell icon in Feed header.

### Layout

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

### Elements

| Element | Description |
|---------|------------|
| **Unread dot (●)** | Blue dot for unread notifications |
| **Title** | Notification title (bold if unread) |
| **Body** | Secondary text with context |
| **Time** | Relative time ("2 min ago", "5 hrs ago") |
| **Mark all read** | Button in header, marks all visible as read |

### Behavior

- Tap notification → navigates to related item/review
- Swipe left → dismiss notification
- Opening the screen marks visible notifications as read (auto)
- Real-time updates via Firestore stream

### Empty State

```
        🔔
  No notifications yet.
  We'll let you know when something needs attention.
```

---

## Empty States

### Feed (no items)

```
        ┌───┐
        │ ✓ │  (green circle)
        └───┘
  Nothing in your feed yet.
  Capture something to get started.
```

### Review (no pending)

```
        ┌───┐
        │ ✓ │  (green circle)
        └───┘
       All caught up!
  Nothing to review right now.
  Capture something to get started.
```

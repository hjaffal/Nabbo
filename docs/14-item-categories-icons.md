# Item Categories & Icons

## Purpose

Every item should have a **category** that visually identifies what it's about at a glance. Instead of showing a generic event/task/deadline icon, the Feed card shows a contextual icon — a basketball for basketball, a swimmer for swimming, a school building for school, etc.

Categories are **not a fixed enum**. They are free-form strings chosen by the AI based on the content. The app maps known categories to icons, with a fallback for unknown ones.

---

## Architecture

```
Item
├── type: event | task | deadline (structural — how it behaves)
├── category: "basketball" | "swimming" | "school" | ... (visual — what it looks like)
└── (icon derived from category at render time)
```

- `type` determines behavior (recurrence, deadlines, completion)
- `category` determines visual (icon, color accent)
- AI chooses the category freely — no forced list
- App has a mapping table: known category → icon
- Unknown categories get a default icon based on `type`

---

## Data Model Change

Add to `ItemModel`:

| Field | Type | Description |
|-------|------|-------------|
| `category` | string? | Free-form category chosen by AI (e.g., "basketball", "dentist", "school trip") |

Stored in Firestore as a simple string field on the item document.

---

## AI Extraction

The prompt asks Gemini to choose a category:

```json
{
  "type": "event",
  "category": "basketball",
  "title": "Basketball training",
  ...
}
```

### Prompt instruction:

```
- For each item, choose a "category" that best describes what this is about. Use a single lowercase word or short phrase. Examples: "basketball", "swimming", "football", "dentist", "school", "school trip", "music", "dance", "birthday", "payment", "form", "homework", "pickup", "doctor", "vaccination", "theater", "cinema", "hiking", "camping", "travel", "meeting". Choose the most specific and natural category. If unsure, use "general".
```

---

## Icon Mapping

The app maps categories to Material Icons at render time:

| Category | Icon | Color |
|----------|------|-------|
| basketball | `sports_basketball` | Orange |
| football | `sports_soccer` | Green |
| swimming | `pool` | Blue |
| tennis | `sports_tennis` | Green |
| dance | `music_note` | Pink |
| music | `music_note` | Purple |
| school | `school` | Blue |
| school trip | `directions_bus` | Orange |
| homework | `menu_book` | Blue |
| dentist | `medical_services` | Teal |
| doctor | `local_hospital` | Red |
| vaccination | `vaccines` | Teal |
| birthday | `cake` | Pink |
| payment | `payment` | Green |
| form | `description` | Blue |
| pickup | `directions_car` | Grey |
| drop-off | `directions_car` | Grey |
| travel | `flight` | Blue |
| hiking | `hiking` | Green |
| camping | `camping` (or `nature`) | Green |
| cinema | `movie` | Purple |
| theater | `theater_comedy` | Purple |
| meeting | `groups` | Blue |
| shopping | `shopping_bag` | Orange |
| cooking | `restaurant` | Orange |
| cleaning | `cleaning_services` | Teal |
| laundry | `local_laundry_service` | Blue |
| general | (fallback based on type) | Grey |

### Fallback Logic

```dart
IconData getCategoryIcon(String? category, ItemType type) {
  // 1. Try exact match in mapping table
  // 2. Try partial match (e.g., "football training" contains "football")
  // 3. Fall back to type-based icon:
  //    - event → Icons.event_rounded
  //    - task → Icons.check_circle_outline_rounded
  //    - deadline → Icons.schedule_rounded
}
```

### Partial Matching

Since AI can return variations ("football training", "basketball game", "swim class"), the mapping should check if the category **contains** a known keyword:

```
"football training" → contains "football" → sports_soccer
"swim class" → contains "swim" → pool
"school trip to museum" → contains "school trip" → directions_bus
"doctor appointment" → contains "doctor" → local_hospital
```

---

## Color Mapping

Each category can optionally have a color accent used for the icon background:

| Color group | Categories |
|-------------|-----------|
| Orange | basketball, shopping, school trip, cooking |
| Green | football, tennis, hiking, camping, payment |
| Blue | swimming, school, homework, travel, meeting, form |
| Pink | dance, birthday |
| Purple | music, cinema, theater |
| Teal | dentist, doctor, vaccination, cleaning |
| Red | doctor, emergency |
| Grey | pickup, drop-off, general |

---

## UI Changes

### Feed Card

Replace the current type-based icon (event/task/deadline) with the category icon:

```
Before: [📅] Basketball training
After:  [🏀] Basketball training
```

The icon container uses the category's color as background tint.

### Item Detail Screen

Show the category icon large in the header (instead of type icon).

### Edit Item Screen

Add a category field (text input — user can change what AI chose).

---

## Where Category Is NOT Used

- Category does NOT affect sorting
- Category does NOT affect recurrence behavior
- Category does NOT affect approval flow
- Category does NOT determine item type (event/task/deadline)
- Category is purely visual

---

## Implementation Plan

### Phase 1: Data + AI
- Add `category` field to `ItemModel` (String?, nullable)
- Update AI prompt to return `category` for each item
- Update Cloud Function to write `category` to Firestore

### Phase 2: Icon Mapping
- Create `category_icons.dart` with the mapping table
- Create `getCategoryIcon(category, type)` function
- Create `getCategoryColor(category, type)` function

### Phase 3: UI
- Update Feed card to use category icon instead of type icon
- Update Item Detail header to use category icon
- Add category field to Edit Item screen

### Phase 4: Learning
- Over time, new categories will appear naturally from AI
- No maintenance needed — unknown categories get default icons
- Popular new categories can be added to the mapping table in app updates

---

## Examples

| Input | category chosen by AI |
|-------|----------------------|
| "Adam has basketball Friday at 18:30" | "basketball" |
| "Yara swimming every Tuesday" | "swimming" |
| "Dentist next Tuesday at 4pm" | "dentist" |
| "School trip to museum Friday" | "school trip" |
| "Pay €8 for school portal" | "payment" |
| "Sign permission form by Wednesday" | "form" |
| "Pick up Adam from school" | "pickup" |
| "Yara's birthday party Saturday" | "birthday" |
| "Family hike Sunday morning" | "hiking" |
| "Book cinema tickets for Friday" | "cinema" |

---

## Design Principles

- **AI decides** — no forcing users to pick from a list
- **Visual only** — category doesn't affect logic/behavior
- **Graceful degradation** — unknown categories still look fine (type-based fallback)
- **Natural language** — categories are lowercase, human-readable words
- **Grows organically** — new categories appear as families use the app differently

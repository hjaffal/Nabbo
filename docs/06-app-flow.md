# App Flow & Screen Map

## Core Navigation (v1)

```
┌─────────────────────────────────────────┐
│              Bottom Nav Bar              │
├─────────┬──────────────┬────────────────┤
│  Feed   │    Review    │   Settings     │
└─────────┴──────────────┴────────────────┘
        + FAB (expandable: text / voice / image)
```

Three tabs:
1. **Feed** — Chronological view of all items (pending + confirmed), grouped by date
2. **Review** — Items with `status: pendingReview` that need parent decision
3. **Settings** — Household details, family members, email alias, notifications, account

Plus: **Expandable FAB** (+) with capture options (text, voice, image).

---

## First-Time User Flow

### Step 1: Welcome

> "Don't remember it. Nabbo it."

Short explanation: "Send school emails, WhatsApp messages, screenshots, voice notes, or quick reminders into Nabbo. We turn them into actions, owners, and daily plans."

→ **Set up household**

### Step 2: Household Setup

- Household name (required)
- Primary parent name (required)
- Timezone (required)
- Default language (required)

On completion, the primary parent is **automatically added as a family member** with role `primaryParent` and a random color. This ensures they appear in the Owner dropdown when assigning items.

### Step 3: Add Children

- Child name (required)
- Age group (optional)
- School (optional)
- Common activities (optional)

Keep it light. Don't ask for too much upfront.

### Step 4: Add Other People (optional)

- Second parent
- Caregiver
- Grandparent

For v1, these are labels, not full user accounts.

### Step 5: Create Nabbo Email Alias

Show the family's unique forwarding email:
> `familyname@nabboapp.com`

Explain: "Forward school emails and activity updates here."

### Step 6: Enable Sharing

Explain how to use the mobile share sheet:
> "When you see a message, screenshot, PDF, or note you don't want to remember, share it to Nabbo."

### Step 7: First Capture Prompt

Three options:
- Share something now
- Forward an email
- Type a quick note

**Onboarding ends with action, not education.**

---

## Returning User Flow

The app always opens to the **Feed** tab. The Feed itself surfaces what needs attention:
- Pending items appear at the top with "Analyzing" or "Needs review" status
- Confirmed items appear chronologically grouped by date

---

## Capture Flows

All capture methods follow the same pattern:
1. User captures content
2. Source Message created in Firestore (`processingStatus: pending`)
3. Item appears **immediately** in the Feed as "Analyzing..."
4. Cloud Function processes → writes items to `items/` collection with `status: pendingReview`
5. Source Message updated to `processingStatus: completed`
6. Feed card changes from "Analyzing..." to "Needs review"

### Free Text

1. User taps **+** FAB → selects **Text**
2. Types a note (e.g., "Adam has basketball Tuesday at 17:30")
3. Taps send → Source Message created
4. Appears in Feed immediately as "Analyzing..."
5. AI processes in background (~20-30s)
6. Becomes "Needs review" when done

### Voice

1. User taps **+** FAB → selects **Voice**
2. Speaks a reminder
3. On-device transcription shows the text
4. Taps send → Source Message created with transcript
5. Same flow as text from here

### Image / Screenshot

1. User taps **+** FAB → selects **Photo**
2. Takes photo or picks from gallery
3. Uploads to Cloud Storage
4. Source Message created with attachment URL
5. Same flow continues

### Mobile Share

1. User shares content from another app (WhatsApp, email, etc.) into Nabbo
2. Source Message created automatically
3. Appears in Feed

### Email Forwarding

1. User forwards email to `alias@nabboapp.com`
2. Cloud Run receives and stores as Source Message
3. Same AI processing flow

---

## Feed Screen

The Feed is the main screen. It shows **all items** in chronological order, grouped by day.

### What appears in the Feed

| Source | Status shown | Badge |
|--------|-------------|-------|
| Source Message with `processingStatus: pending/processing` | "Analyzing..." | Blue |
| Source Message with `processingStatus: failed` | "Failed — tap to retry" | Coral |
| Source Message with `processingStatus: noAction` | "No action found" | Grey |
| Source Message with `processingStatus: completed` (items created) | Hidden (items shown instead) | — |
| Item with `status: pendingReview` | "Needs review" | Yellow |
| Item with `status: confirmed` | "Active" | Green |
| Item with `status: cancelled` | "Cancelled" | Coral (strikethrough) |
| Item with `status: completed` | Hidden from Feed | — |
| Item with `status: hidden` | Hidden from Feed | — |

### Feed layout

- Greeting: "Good evening, [user name]" (time-based + user's display name)
- Title: "Your family feed"
- **Notification bell** (top-right, before weather): bell icon with badge count of unread notifications. Tap opens Notifications screen.
- **Weather widget** (top-right): emoji + temperature from OpenWeatherMap (by GPS)
- Items grouped by day: "Needs Review", "Today", "Tomorrow", "Wed, 9 Jul", etc.
- Each card shows: icon, title, child chip (photo or colored initial), owner chip, location, time, status badge
- Tapping a pending item → opens **Review Detail** screen
- Tapping a confirmed item → opens **Item Detail** screen
- Recurring items expand into one card per occurrence (until endDate, or next 4 weeks if no end)
- **Swipe left** on confirmed/cancelled items → hides from Feed (status: hidden, with undo)

### Feed sorting

1. Pending items (analyzing/needs review) always at top
2. Then chronological by date (today first → tomorrow → next week)
3. Items without dates appear after pending, before dated items

---

## Review Detail Screen

Opens when user taps a pending item in the Feed (either a source message card or a pendingReview item).

### If AI is still processing:
- Shows original message content
- Shows "Analyzing..." spinner
- Updates in real-time when AI finishes

### If AI is done:
- Shows original message content
- Shows all extracted items linked to this source message
- Each extracted item shows:
  - Type chip (event / task / deadline)
  - Child name chip
  - Title and summary
  - Extracted fields with confidence labels
  - Suggested actions

### Actions per extracted item:
- **Approve** → changes `status` to `confirmed` (stays in same document, no copy)
- **Edit** → opens edit screen to modify any field before/after approving
- **Delete** → deletes the item document

### After all items reviewed:
- Source Message is no longer shown in Feed
- Confirmed items appear in Feed under their date

---

## Item Detail Screen

Opens when user taps a confirmed/completed/cancelled item in the Feed.

### Shows:
- Item type + status badge
- Title (large)
- Child name and Owner name
- All data fields (date, location, recurrence, extracted fields, etc.)
- Null fields shown as "— not set"
- Edit button in app bar

### Actions:
- **Edit** → opens edit screen with all editable fields
- **Mark done** → `status: completed`
- **Cancel** → `status: cancelled`

---

## Edit Screen

Opens from Item Detail or Review Detail. Shows all editable fields as form inputs.

### Editable fields:
- Title
- Location
- Child (affected member)
- Owner (responsible parent — adults only)
- Date / time
- Recurrence
- Description
- Any other extracted fields

### Save:
- Updates the item document directly in Firestore
- User can edit at ANY point in the lifecycle (pending, confirmed, completed, cancelled)

---

## Review Tab

A focused view showing ONLY items with `status: pendingReview`.

### Purpose:
- Quick access to everything that needs attention
- Same items that appear in the "Needs Review" section of the Feed
- But without the noise of confirmed/completed items

### Empty state:
- "All caught up!" with green checkmark
- Subtitle: "Nothing to review. Capture something to get started."

---

## Settings Screen

Sections:
- **Household** — name, timezone, language, location (zip code, city, country) — tap to edit
- **Email alias** — display + copy
- **Family members** — list (shows name + color dot), add, edit (name, role, photo, color), remove
- **Notifications** — category toggles, quiet hours
- **Account** — sign out, delete account

### Edit Family Member

Fields:
- Name (text)
- Role (dropdown)
- Photo (upload/camera)
- **Color** (color picker from palette — used for visual identification in cards throughout the app)

### Edit Household

Fields:
- Name (text)
- Timezone (dropdown or auto-detect)
- Language (dropdown)
- **Location** (Google Places autocomplete — search and select an address/city. Stored as `city` in Firestore, used for weather and AI context)

---

## Error States

| Error | Message | Actions |
|-------|---------|---------|
| Unsupported file | "This file type is not supported yet." | Dismiss |
| Extraction failed | "Nabbo could not read this clearly." | Try again, Dismiss |
| No action found | "No clear family action found." | Dismiss |
| Network error | "Check your connection." | Retry |

---

## Empty States

| Screen | Message |
|--------|---------|
| Feed (no items) | "Nothing in your feed yet. Capture something to get started." |
| Review (no pending) | "All caught up! Nothing to review." |
| Feed (no family members) | "Add a child in Settings so Nabbo knows who messages affect." |

---

## Primary Flow Map

```
Flow 1: Capture → Feed → Review → Confirmed
User captures → Source Message created → appears in Feed as "Analyzing"
→ AI processes → items created as pendingReview → Feed shows "Needs review"
→ User taps → Review Detail → Approves → item status: confirmed
→ appears in Feed under its date as "Active"

Flow 2: Edit
User taps any item → Item Detail → Edit → changes saved to Firestore

Flow 3: Complete
User taps confirmed item → Item Detail → Mark done → status: completed

Flow 4: Cancel
User taps confirmed item → Item Detail → Cancel → status: cancelled

Flow 5: Recurring
Item has recurrence rule → Feed expands into multiple cards (one per occurrence)
→ User cancels single occurrence → exception added, card disappears for that date
```

---

## Screen Map (v1)

- Welcome
- Household Setup
- Add Children
- Add People
- Email Alias
- Sharing Explanation
- First Capture
- **Feed** (main tab)
- **Review** (tab)
- Review Detail (per source message)
- **Item Detail** (per confirmed item)
- **Edit Item**
- **Settings** (tab)
- Edit Household
- Family Members
- Notification Settings
- Delete Account

**Not included in v1:** Calendar grid, chat, analytics, routine builder, monthly planner.

---

## Product Flow Rules

- Capture must be instant — item appears in Feed immediately
- AI runs in background — user never waits
- Approval is a status change, not a data copy
- Editing is always available regardless of status
- Do not ask users to classify inputs during capture
- Do not hide source messages
- Do not auto-commit items without review
- Do not make the Feed a calendar grid
- Do not show notifications without a clear action

# Nabbo — Visual Design Direction

## Design Philosophy

Nabbo uses a **soft modern utility** style. The design combines calm surfaces with strong contrast to feel friendly without looking childish. It uses dark teal for trust, pale blue-white backgrounds for calm, pastel cards for category separation, and bold rounded typography for clarity.

Nabbo should feel like a **modern family operations app** — not a calendar, not a task manager, and not a kids app.

### Target Feeling

- Calm
- Soft
- Clear
- Premium
- Action-first
- Friendly, but not playful

---

## Color Theme

The core palette uses a soft pastel system rather than pure white with bright accents.

### Primary Colors

| Role | Hex | Usage |
|------|-----|-------|
| **Deep Teal** | `#123F49` | Headers, primary surfaces, app icon background, key navigation, strong text blocks. This is the trust color — it gives the app authority. |
| **Ice Background** | `#EAF5F5` | Main app screen background. Provides a calm, light feeling without harsh white. |
| **Mist Blue** | `#A8C9CF` | Outer backgrounds, onboarding surfaces, large calm panels. |

### Card Colors

| Role | Hex | Usage |
|------|-----|-------|
| **Lavender Card** | `#D8C8F4` | Review items, child cards, non-urgent action groups. Adds warmth and softness. |
| **Soft Mint Card** | `#D6F4D2` | Completed, ready, packed, or low-risk states. Calmer than standard green. |
| **Sky Blue Card** | `#AEE3F0` | Summaries, daily brief, next-action information. Works well for Today status and brief cards. |
| **Blush Pink** | `#F1C4E8` | Gentle attention, snoozed items, review states. Use carefully — should not dominate. |

### Accent Colors

| Role | Hex | Usage |
|------|-----|-------|
| **Lime Accent** | `#C9F83F` | Tiny highlight only — selected date, active underline, progress signal. Do not overuse; it can look childish fast. |
| **Coral Alert** | `#FF6B6B` | Real attention only — changes, risks, owner missing, overdue items. Should remain rare. |

### Color Balance

| Element | Proportion |
|---------|-----------|
| Ice Background | 50% |
| Deep Teal | 25% |
| Pastel cards | 20% |
| Lime or Coral accents | 5% |

### Color Usage Rules

- Do not use all accent colors on one screen — it makes the app look noisy.
- A good Nabbo screen should feel calm first, then the important action stands out.
- **Deep Teal** → Onboarding hero, important headers, main navigation, primary text, app icon.
- **Sky Blue** → Today summary, next action card, daily brief.
- **Lavender** → Review cards, school or child-related cards.
- **Mint** → Completed items, packed items, clear states.
- **Blush Pink** → Snoozed items, soft reminders, review-needed states.
- **Coral** → Risk, owner missing, deadline overdue, change detected.
- **Lime** → Active selection, tiny progress underline, small confirmation detail.

---

## Typography

### Font Choice

Use **Nunito Sans** as the primary typeface. It has soft curves, strong readability, and a friendly household feel. Alternative options: Manrope (more premium modern), Plus Jakarta Sans, SF Pro Rounded (iOS-first).

### Typography Rules

- Bold headings
- Short labels
- Medium weight for card titles
- Regular weight for details
- Generous spacing
- Avoid thin text
- Avoid tiny metadata

Parents may use Nabbo while moving, packing, or leaving the house. The UI must scan fast.

---

## UI Shape Language

Nabbo uses rounded forms throughout:

- Large rounded screen containers
- Cards with **24–32px** radius
- Pill buttons
- Circular icon buttons
- Soft rounded chips
- Bottom sheets with rounded top corners

Rounded containers make the system feel less harsh — important because the product deals with messy household information.

**Avoid** sharp rectangular cards. They make the app feel like an admin dashboard.

---

## Card System

Cards are the core UI unit. Each Nabbo card should feel like a soft operational note.

### Card Types

| Card | Background |
|------|-----------|
| Review Card | Lavender or white |
| Next Action Card | Sky Blue |
| Checklist Card | Mint or white |
| Risk Card | White with coral marker |
| Change Card | White with coral changed value |
| Daily Brief Card | Sky Blue |
| Source Card | Light neutral surface |

Use pastel backgrounds to create category differences, but keep text dark and clear.

---

## UX Structure

The UX follows a **card-first** approach. Do not build dense lists — build stacked cards. Do not make Today look like a calendar — make it feel like a command feed.

### Recommended Screen Flow

1. Top greeting or status
2. Today summary
3. Next action
4. Urgent review items
5. Checklist cards
6. Risk and change cards
7. Timeline only lower on the screen

Status first → action cards next → details below.

---

## Screen Styles

### App Home

**Top section:**
- "Good morning, Hasan."
- Small date row
- Notification button
- Capture button

**Main status:**
- "Today is clear." or "Busy day. 1 owner gap."

**Then cards:** Next action → Review needed → Checklist → Changes → Risks.

The screen should feel calm even when there is work to do.

### Today Screen

Today should not look like a calendar grid. Use a lightweight day selector (small pills), not a full calendar.

**Structure:**
- Good morning + date selector pills
- Status card
- Next action card
- Family cards
- Checklist cards
- Risk cards

### Review Card

Soft surface with clear field rows:

- Source chip at top
- Operational summary
- Extracted fields
- Uncertain fields (coral for missing/uncertain)
- Primary action (teal/deep teal for approval)
- Secondary actions

**Example:**
> "Training changed" · Friday, 18:30 · Sports Hall · ⚠️ Owner missing
>
> **[Confirm change]** · Edit · Snooze · View source

### Onboarding

Dark teal hero style:

- Dark teal background
- Large abstract household-basket shapes (not family illustrations)
- Big headline
- Short explanation
- One clear CTA

**Example:**
> **"Don't remember it. Nabbo it."**
>
> Share school emails, WhatsApp messages, screenshots, and voice notes. Nabbo turns them into actions.
>
> **[Start with your household]**

---

## Icons

Simple icons inside rounded squares and circles.

### Icon Style

- Rounded line icons
- Minimal detail
- Dark teal lines
- Pastel icon containers
- No complex illustrations

### Core Icon Set

Basket · Message · Email · Camera · Microphone · Checklist · Clock · Location · Person · Alert dot · Source

### Avoid

- Calendar-heavy icon set
- Robot icons
- Sparkles
- Cartoon family icons

---

## Buttons

Large, rounded, and clear.

| Type | Style |
|------|-------|
| **Primary** | Deep teal background, white text |
| **Secondary** | White or pastel background, deep teal text |
| **Attention** | Coral background or coral text (used rarely) |
| **Capture** | Lime or teal floating action button |

### CTA Labels

**Use:** "Nabbo it" · "Review" · "Confirm" · "Assign" · "Mark handled"

**Avoid:** "Continue" · "Process" · "Update item"

---

## What Nabbo Should NOT Have

- Doctor profiles or ranking cards
- Activity scores or health-style charts
- Large human portrait hero cards
- Gamified score panels
- Sharp rectangular admin-style cards

---

## Brand Statement

Nabbo looks like a calm, modern household operations app. It uses dark teal for trust, soft blue-white for calm, pastel cards for family context, coral for attention, and lime only as a tiny active accent. The UX is card-based, rounded, and fast to scan.

The user should open Nabbo and feel:

- I know what needs attention.
- I know what changed.
- I know what to pack.
- I know who owns it.

That is the design goal.

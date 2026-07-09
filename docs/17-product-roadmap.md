# Product Roadmap

## Purpose

Take Nabbo from a useful tool to something parents open instinctively — a daily companion they'd feel lost without. Every feature below exists to answer one question: **"Why would a parent come back tomorrow?"**

---

## What's Already Shipped ✅

- Morning Brief card (daily summary at top of feed)
- Family Activity Feed (household timeline)
- Per-child Week View (tap child → see their week)
- Animated transitions (staggered card entrance, styled SnackBars)
- Contextual illustrations (warm empty states)
- Ambiguity picker ("Who is this about?" in review)
- Pull-to-refresh everywhere
- Cupertino date picker

---

## Phase 1: Daily Rituals (Habit Formation)

**Problem:** Parents open Nabbo when they remember, not automatically. No ritual.

**Goal:** Create a calm daily rhythm that feels rewarding.

| # | Feature | Effort | Description |
|---|---------|--------|-------------|
| 1.1 | Calm indicator | Small | "All handled ✓" pulse in feed header when nothing needs attention. Emotional reward for being on top of things. |
| 1.2 | Streak glow | Small | Subtle visual glow on feed header after 3+ consecutive days of opening. Not a number — a feeling. |

**Retention mechanism:** Parents feel good when they see "all clear" — builds daily check habit.

---

## Phase 2: Proactive Intelligence (AI Surprises)

**Problem:** App only reacts to input. Parents stop feeding it once novelty fades.

**Goal:** Nabbo reaches out first. It notices things before you do.

| # | Feature | Effort | Description |
|---|---------|--------|-------------|
| 2.1 | Conflict detection | Medium | "Adam has football AND dentist Thursday at 16:00." Catches real scheduling problems. |
| 2.2 | "What's missing?" nudges | Medium | "Football tomorrow — no one owns 'pick up Adam.' Assign?" Proactive gap alerts. |
| 2.3 | Prep time nudge | Small | "Football at 18:30. Leave by 17:50." Shows on item card morning of. |
| 2.4 | Smart suggestions | Small | "Last 3 times, you handled school payment. Assign to you?" Pattern-based ownership hints. |

**Retention mechanism:** Parents keep the app because it surprises them with useful insights they didn't ask for.

---

## Phase 3: Social & Sharing (Growth Loop)

**Problem:** Only one parent uses the app. No viral moment. No shared responsibility feeling.

**Goal:** Make Nabbo shareable. Create reasons for the second parent to engage.

| # | Feature | Effort | Description |
|---|---------|--------|-------------|
| 3.1 | Quick delegate | Small | "Send to [partner]" — generates a WhatsApp/SMS message with item summary. No account needed for recipient. |
| 3.2 | Shared link preview cards | Medium | Beautiful OG cards when sharing items externally. Recipients see value without installing. |
| 3.3 | "Assigned to you" notifications | Small | Push notification when item assigned: "Hassan assigned you: Pick up Adam at 15:30." |
| 3.4 | Multi-user households | Large | Second parent gets their own login + notifications. Full shared experience. |

**Retention mechanism:** Both parents engage. Social accountability keeps them coming back.

---

## Phase 4: Depth & Richness (Power User Value)

**Problem:** Power users hit a ceiling. The app feels "done" after 2 weeks.

**Goal:** Reward continued use with features that compound over time.

| # | Feature | Effort | Description |
|---|---------|--------|-------------|
| 4.1 | Calendar sync (ICS export) | Large | Confirmed events push to Google/Apple Calendar. Nabbo becomes the input layer. |
| 4.2 | Recurring checklists | Medium | "Every football → pack: jersey, water, ball." Templates that auto-attach. |
| 4.3 | Monthly family report | Small | "June: 47 items handled, 3 missed deadlines, most active day: Tuesday." |
| 4.4 | History & search | Medium | Search past items, filter by child/type/date. "When was Adam's last dentist?" |
| 4.5 | Item templates | Small | "Create football training" as a one-tap recurring template. Power user shortcut. |

**Retention mechanism:** The longer you use Nabbo, the smarter and more useful it becomes.

---

## Phase 5: Emotional Connection (Love, Not Just Use)

**Problem:** The app works but doesn't feel personal. No emotional attachment.

**Goal:** Make parents feel that Nabbo "gets" their family.

| # | Feature | Effort | Description |
|---|---------|--------|-------------|
| 5.1 | Celebratory moments | Small | "Week complete — 0 missed deadlines 🎉" Friday card. Micro-celebrations. |
| 5.2 | Family milestones | Small | "Adam's first school year: 142 events managed." Annual summaries. |
| 5.3 | Seasonal awareness | Small | "School starts in 2 weeks. Last year you had 12 items in the first week." Context-aware prompts. |
| 5.4 | Personalized tips | Small | "Tip: You usually forget swimming goggles. Nabbo will remind you morning before." |
| 5.5 | Custom themes | Small | Choose purple, teal, or coral as primary. Personalization creates ownership. |
| 5.6 | Child avatars & emoji | Small | Kids get fun emoji: "Adam 🏀" / "Yara 🎨". Personality in the UI. |

**Retention mechanism:** Emotional attachment. Deleting it would feel like losing a diary.

---

## Phase 6: Discovery Engine ("Get Me Something to Do")

**Problem:** Weekends and holidays are empty. Parents want ideas, not just logistics.

**Goal:** Nabbo proactively suggests family activities by crawling local events, nearby attractions, and seasonal opportunities.

| # | Feature | Effort | Description |
|---|---------|--------|-------------|
| 6.1 | "Get me something to do" button | Large | Parent taps → Nabbo recommends 3-5 local events/activities based on family ages, location, and interests. |
| 6.2 | Local event crawling | Large | Scrape/aggregate local event sites, community boards, and family activity platforms for the family's area. |
| 6.3 | Weekend suggestions card | Medium | Friday card: "This weekend near you: Science Museum free entry, Park festival Sat, Kids cinema €5." |
| 6.4 | Holiday planner | Medium | "School holiday in 3 weeks. Here are 5 ideas based on what your family enjoys." |
| 6.5 | Interest learning | Medium | Learn from approved activities what the family likes (outdoor, sports, arts, educational) → better suggestions over time. |
| 6.6 | One-tap add | Small | Tap a suggested event → instantly creates an item in Nabbo with date, location, details pre-filled. |

**Retention mechanism:** Nabbo isn't just a logistics tool — it's a family life assistant that gives you ideas. Parents open it on boring Saturdays.

*Scope TBD — will detail in a separate spec when ready to build.*

---

## Priority: What to Build Next

### Now (next 2 weeks)

| # | Feature | Rationale |
|---|---------|-----------|
| 1.1 | Calm indicator | Low effort emotional pull. Daily reward. |
| 2.1 | Conflict detection | High trust value. "It caught something I missed." |
| 5.1 | Celebratory moments | Low effort, high emotional value. |

### Next (2-6 weeks)

| # | Feature | Rationale |
|---|---------|-----------|
| 2.2 | "What's missing?" nudges | Proactive. Makes parents feel supported. |
| 3.1 | Quick delegate | Gateway to second parent. |
| 2.3 | Prep time nudge | Simple magic. Morning delight. |

### Then (1-3 months)

| # | Feature | Rationale |
|---|---------|-----------|
| 4.1 | Calendar sync | Lock-in. Can't live without it. |
| 4.2 | Recurring checklists | Compound value. |
| 3.4 | Multi-user | Full shared experience. |

### Future (3-6 months)

| # | Feature | Rationale |
|---|---------|-----------|
| 6.1-6.6 | Discovery Engine | Game-changer. Nabbo becomes a lifestyle app, not just logistics. |
| 4.4 | History & search | Power user depth. |
| 5.2 | Family milestones | Long-term emotional bond. |

---

## Anti-Boredom Strategy

| Problem | Solution | Feature |
|---------|----------|---------|
| App only speaks when spoken to | Proactively surface insights | Conflict detection, nudges, prep time |
| No reason to open when nothing's pending | Calm indicator rewards "all clear" | Calm indicator, streak glow |
| Same utility every day | Suggest new things to do | Discovery Engine |
| Only one parent engaged | Make sharing effortless | Quick delegate, assigned notifications |
| Novelty wears off | Features that improve with time | Checklists, suggestions, interest learning |
| No emotional connection | Celebrate progress, personalize | Milestones, celebrations, themes |
| Weekends/holidays are dead zones | Suggest activities near you | Weekend card, holiday planner |

---

## Principles

1. **Proactive > Reactive** — The best feature is one the parent didn't have to ask for
2. **Rituals > Features** — Create daily moments, not just tools
3. **Compound value** — Every week of use should make Nabbo slightly more useful
4. **Social by default** — Make it easy to show value to others
5. **Emotional, not transactional** — The app should feel like it cares about your family
6. **Discovery, not just logistics** — Help families live better, not just organize better
7. **Smart, not creepy** — Infer from patterns, never surveil

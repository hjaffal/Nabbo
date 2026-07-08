# Product Roadmap

## Purpose

This roadmap defines what comes after v1 launch. The goal is to take Nabbo from a useful utility to an indispensable daily habit — something parents feel uneasy without.

Each phase has a theme. Features are grouped by the feeling they create, not just technical category.

---

## Phase 1: Make It Alive (Daily Pull)

**Theme:** Give parents a reason to open Nabbo every morning without being asked.

| # | Feature | Effort | Description |
|---|---------|--------|-------------|
| 1.1 | Morning Brief card | Medium | Beautiful summary card at 7:30am in Feed: "Today: Adam has football (bring jersey). Yara's €5 due. No owner for pickup." Uses existing `dailyBrief` cloud function output. |
| 1.2 | Week Ahead preview | Medium | Sunday evening card: "This week: 3 events, 1 payment, 2 forms." Gives a sense of control. Shown in Feed as a special card type. |
| 1.3 | Calm indicator / streak | Small | Non-gamified pulse: "All handled this week ✓" or "2 things need attention." Subtle badge or card in Feed header. Not a score — a feeling. |
| 1.4 | Smart empty states | Small | Contextual prompts when Feed is empty: "Forward a school email," "Share a WhatsApp message," "Speak a reminder." Rotating, helpful, not annoying. |

**Success signal:** Parents open Nabbo in the morning before checking WhatsApp.

---

## Phase 2: Make It Smart (AI Wow Moments)

**Theme:** Nabbo remembers what you forget. It catches problems before they happen.

| # | Feature | Effort | Description |
|---|---------|--------|-------------|
| 2.1 | Packing assistant | Medium | Before an event, auto-generate a "Pack for football" checklist from learned associations (jersey, water, ball). The magic "it remembered" moment. |
| 2.2 | Conflict detection | Medium | "Adam has basketball AND dentist at the same time Thursday." Flag scheduling conflicts automatically. Alert in Feed + notification. |
| 2.3 | Prep time nudge | Small | "Football at 18:30. Leave by 17:50." Simple travel-time estimate per activity. Stored per location, not full Maps routing. Shown on item card. |
| 2.4 | "You usually..." suggestions | Small | "Last 3 times, you handled school payment. Assign to you?" Ownership suggestions based on historical patterns. Shown as gentle prompt on unassigned items. |
| 2.5 | "What's missing?" intelligence | Medium | "Football is tomorrow but no one owns 'pick up Adam.' Assign?" Proactive gap detection. Creates risk-like alerts but framed as helpful nudges. |

**Success signal:** Parent says "How did it know I needed that?" at least once per week.

---

## Phase 3: Make It Shared (Household Feel)

**Theme:** Both parents feel like they're operating together, even if only one uses the app heavily.

| # | Feature | Effort | Description |
|---|---------|--------|-------------|
| 3.1 | Family activity feed | Medium | Timeline showing: "Dad approved football" / "Mum forwarded newsletter" / "3 items from school email." Shared visibility without full multi-user auth. |
| 3.2 | Quick delegate | Small | From any item: "Send to [partner]" — sends a push/SMS/WhatsApp link with a quick summary. Lightweight nudge, no account required for recipient. |
| 3.3 | Per-child week view | Medium | Tap a child → see their week: football Tue, dentist Thu, trip Fri. Parents think in "what does Adam have this week?" — serve that directly. |
| 3.4 | Shared link preview | Medium | When sharing an item externally, generate a pretty card: "Adam: football Fri 18:30, bring jersey, no owner." Works over messaging apps without app install. |

**Success signal:** Second parent starts checking Nabbo or receiving useful delegations.

---

## Phase 4: Make It Delightful (Feel & Polish)

**Theme:** Small moments of delight that make the app feel premium and alive.

| # | Feature | Effort | Description |
|---|---------|--------|-------------|
| 4.1 | Animated transitions | Medium | Approved items animate "flying" from review to feed. Completions fade with a check. Deadlines pulse gently when approaching. Subtle motion = alive. |
| 4.2 | Celebratory moments | Small | "Week complete — 0 missed deadlines 🎉" Friday evening. Not over-the-top. A small reward for staying on top of things. |
| 4.3 | Quick-capture home widget | Large | iOS/Android home screen widget: one tap → voice capture. Removes friction entirely. Deep OS integration needed. |
| 4.4 | Contextual illustrations | Small | Custom empty state illustrations per section. Feed empty → family relaxing. Review empty → checkmark garden. Warm, branded, not generic. |

**Success signal:** Users screenshot and share the app with friends because it "feels nice."

---

## Phase 5: Make It Indispensable (Can't Live Without)

**Theme:** Nabbo becomes the operating system for the household — removing it would be unthinkable.

| # | Feature | Effort | Description |
|---|---------|--------|-------------|
| 5.1 | Calendar export (ICS sync) | Large | Auto-sync confirmed events to Google/Apple Calendar. Nabbo becomes the *input layer* — parents keep their calendar but Nabbo feeds it. |
| 5.2 | Per-child calendar view | Medium | Visual calendar grid showing one child's items by day/week. Full visual picture of a child's schedule. |
| 5.3 | Recurring checklists | Medium | "Every football → pack: jersey, water, ball." Templates that auto-attach to recurring events. Editable, learnable. |
| 5.4 | Multi-user households | Large | Second parent gets their own login, sees same household data, gets their own notifications. Full shared-state experience. |
| 5.5 | Notification deep-linking | Small | Every notification opens the exact item/review card. Already partially built — needs proper routing for all notification types. |
| 5.6 | Data export (PDF/CSV) | Small | Export items, events, schedules as PDF or CSV. Peace of mind that data isn't trapped. |
| 5.7 | AI conversation | Large | "What does Adam have tomorrow?" / "When is the school trip?" Natural language queries over household data. |

**Success signal:** Parent says "I can't imagine managing the family without Nabbo."

---

## Priority Matrix

### Immediate (next 2-4 weeks)

| Feature | Rationale |
|---------|-----------|
| Morning Brief card (1.1) | Highest impact on daily retention. Function already exists. |
| Per-child week view (3.3) | Matches natural parent thinking. High perceived value. |
| Smart empty states (1.4) | Low effort, improves first-time experience immediately. |
| Calm indicator (1.3) | Low effort, adds emotional pull. |

### Short-term (1-2 months)

| Feature | Rationale |
|---------|-----------|
| Packing assistant (2.1) | The "wow" moment. Differentiates from calendar apps. |
| Conflict detection (2.2) | Catches real problems. High trust-building value. |
| Week Ahead preview (1.2) | Creates weekly habit loop. |
| Quick delegate (3.2) | Low effort gateway to multi-user without building auth. |

### Medium-term (2-4 months)

| Feature | Rationale |
|---------|-----------|
| Calendar export (5.1) | Makes Nabbo the permanent input layer. Hard to leave. |
| Animated transitions (4.1) | Polish pass. Makes everything feel premium. |
| Shared link preview (3.4) | Organic growth — recipients see Nabbo's value. |
| Prep time nudge (2.3) | Simple but feels magical. |

### Long-term (4-6 months)

| Feature | Rationale |
|---------|-----------|
| Multi-user households (5.4) | Full shared experience. Retention multiplier. |
| Quick-capture widget (4.3) | Deep OS integration, high friction reduction. |
| AI conversation (5.7) | Natural language over family data. Moonshot value. |
| Recurring checklists (5.3) | Compound value — gets better every week. |

---

## Metrics Per Phase

| Phase | Key Metric | Target |
|-------|-----------|--------|
| 1. Alive | Daily opens (morning) | ≥ 60% of active users open before 9am |
| 2. Smart | "Surprised by AI" moments per week | ≥ 1 per active household |
| 3. Shared | Items delegated or viewed by second parent | ≥ 3 per week |
| 4. Delightful | NPS / app store rating | ≥ 4.7 stars |
| 5. Indispensable | Weekly retention at month 3 | ≥ 70% |

---

## Principles

1. **Every feature must reduce mental load** — if it adds work, it's wrong
2. **Smart, not creepy** — infer from patterns, never track or surveil
3. **Works for one parent first** — multi-user is a multiplier, not a prerequisite
4. **Delight is not decoration** — animations and celebrations reinforce the habit loop
5. **The calendar is not the goal** — Nabbo is action-first, not schedule-first
6. **Growth through sharing** — make it easy to show Nabbo's value to others

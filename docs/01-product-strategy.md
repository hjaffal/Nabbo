# Product Strategy

## Product Thesis

Nabbo turns messy family communication into clear actions, owners, reminders, checklists, and daily plans.

It is not a calendar, a task manager, or a family chat app. Those tools already exist. Nabbo sits before them. It captures the small signals that parents usually hold in their heads and turns them into something the household can act on.

- A school email becomes a deadline
- A WhatsApp message becomes a time change
- A screenshot becomes a checklist
- A voice note becomes a reminder
- A short message from a child becomes an action with an owner

## The Digital Basket Philosophy

Nabbo is built around the idea of a **digital household basket**.

In a busy home, families often have a place where important things are dropped before they are forgotten — a school letter, a key, a note, a form, a coin for tomorrow. That place doesn't run the home, but it protects the home from small misses.

Today, the household basket is scattered across WhatsApp, email, school apps, screenshots, voice notes, PDFs, and quick verbal reminders. The parent becomes the basket. They carry the system in their head.

To "Nabbo it" means to capture a family signal before it becomes mental load. The parent doesn't need to reread the message, remember the detail, repeat it to someone else, or hope it gets handled.

---

## The Core Problem

Modern family life runs on fragmented information.

Parents receive school updates, sports schedules, payment requests, activity changes, appointment reminders, forms, packing instructions, and last-minute messages across many channels. The information is often useful, but arrives in a messy shape.

The real problem is that **none of existing tools own the full operational loop**:

- A calendar stores time
- A task app stores work
- A messaging app creates noise
- A school portal stores institutional updates

None of them reliably answers the parent's real question:

> What needs to happen next, who owns it, and what might be missed?

That gap creates invisible work. Nabbo exists to remove that hidden operational load.

---

## Target User

The primary user is the **operating parent**.

This is the parent who absorbs most of the household logistics. In practice, they are the person who remembers the forms, school trips, activity changes, items to bring, payment deadlines, pickups, appointments, and reminders.

They are often working parents with multiple responsibilities — managing more than one child, multiple schools or activities, and constant small changes.

They do not want another productivity system. They want **fewer things to remember**.

Nabbo serves this user first. Other users matter later (spouses, children, caregivers, grandparents, babysitters), but the first product must work for the person currently carrying the family operations load.

---

## Product Positioning

| Positioning Level | Description |
|-------------------|-------------|
| Weak | "AI calendar for families" |
| Stronger | "Family logistics assistant" |
| **Best** | **"The command center for running family life"** |

Nabbo is the household operations layer that turns messy family messages into clear next steps. It doesn't replace calendars, messages, or school apps — it captures what comes from them and converts it into actions, owners, checklists, reminders, and risks.

> Calendars store commitments. Nabbo helps families do what is needed for those commitments to succeed.

---

## Product Promise

One simple behavior:

> When something matters, Nabbo it.

The promise is not "better organization." The promise is **less mental load**.

---

## Input Strategy

Nabbo will **not** depend on external integrations. This is a strategic choice:

- External integrations create complexity, dependency, privacy concerns, and long implementation cycles
- They make the product fragile because every school, club, calendar, and messaging platform behaves differently

### Three Ingestion Paths

1. **Mobile Share (iOS/Android)** — Share content from WhatsApp, messages, school apps, PDFs, screenshots, images, copied text, voice notes, and other apps that support sharing
2. **Email Forwarding** — Each family gets a unique Nabbo email alias for forwarding school emails, club messages, activity updates, newsletters, forms, payment reminders, and booking confirmations
3. **Free Text / Voice Inside App** — Type or speak a quick prompt like "Yara has basketball Friday at 6, bring water and blue jersey"

The goal is not to connect every external system. The goal is to make capture easier than remembering.

---

## Intelligence Model

Nabbo's intelligence layer extracts **operational meaning**, not just text.

It should identify:
- Who the message affects
- What needs to happen
- When it matters
- Where it happens
- What needs to be brought
- What must be paid
- What needs to be signed
- Who should own it
- Whether anything has changed

### Fact vs. Suggestion vs. Uncertainty

| Type | Definition | Example |
|------|-----------|---------|
| **Fact** | Clearly present in the source | "Football training is Friday at 18:00" |
| **Suggestion** | Inferred from household memory or patterns | "Add water bottle and football boots to the checklist" |
| **Uncertain** | Cannot be fully trusted | "The location may be Main Hall" |

This distinction is central to user trust.

---

## Trust Model

Trust is not a feature. Trust is the **foundation** of Nabbo.

Rules:
- Source message should always be visible
- Uncertain fields should be highlighted
- Corrections should be fast
- Low-confidence items should not be auto-committed
- Inferred suggestions should be labeled as suggestions
- The parent should always have control over approval

> False certainty is dangerous. A good product says "I am not sure." A bad product guesses and hides the risk.

---

## Household Memory

Nabbo becomes more valuable when it learns the household:

- Family members, schools, clubs, common locations
- Recurring activities and usual required items
- Repeated routines and responsibility patterns

Examples:
- Swimming usually requires goggles, towel, shampoo, and snack
- One child has music every Thursday
- One parent usually handles football pickup, another handles school forms

This memory appears as useful suggestions at the right time. It should not feel intrusive or overactive.

---

## Coordination Model

Family life is multi-player. Different users need different levels of detail:

| Role | Needs |
|------|-------|
| **Primary parent** | Full command center |
| **Spouse** | What changed, what they own, what is unassigned |
| **Child** | "What I need to do" |
| **Caregiver** | Relevant handoff only (pickup time, location, short instructions) |

Nabbo should reduce repeated coordination, not create more conversation.

---

## Risk Detection

Nabbo should detect household risk before it becomes stress:

- Two children needing transport at the same time
- A deadline due tomorrow
- A missing owner for pickup
- A changed location
- An unpaid fee or unsigned form
- A required item not checked off
- Travel time that requires leaving earlier

> A calendar shows events. Nabbo shows failure points.

---

## Product Architecture (5 Layers)

1. **Input Layer** — Captures shared content, forwarded emails, images, documents, voice notes, screenshots, free text
2. **Intelligence Layer** — Extracts meaning, detects uncertainty, identifies changes, links to the right person/routine
3. **Household Graph** — Stores family members, schools, clubs, locations, routines, common items, responsibility patterns, recurring commitments
4. **Execution Layer** — Turns extracted information into actions, checklists, reminders, ownership, preparation plans, risk alerts
5. **Coordination Layer** — Allows the household to share plans, assign actions, confirm completion, keep relevant people aligned

---

## Strategic Differentiation

Nabbo's differentiation is **not** AI alone. AI is not defensible.

The differentiation comes from applying AI to a specific operational domain with the right workflow, memory, trust model, and family context.

Strongest differentiators:
- Messy input capture
- Action extraction
- Household memory
- Responsibility assignment
- Change detection
- Preparation checklists
- Risk alerts
- Daily execution views

The product becomes stronger as it understands the family. That context creates value over time.

---

## Non-Goals

Nabbo should avoid becoming too broad:

- ❌ Direct school portal integrations
- ❌ Automatic WhatsApp monitoring
- ❌ Google Calendar / Outlook integration as a core requirement
- ❌ Family chat product
- ❌ Generic task manager
- ❌ AI chatbot as the main interface
- ❌ Calendar-first design (monthly grid is not the core experience)

---

## Business Model

**Subscription-based.**

| Tier | Includes |
|------|----------|
| **Free** | Limited monthly captures, basic inbox review, simple Today view, manual text input |
| **Premium Family** | Unlimited captures, shared household access, advanced extraction, household memory, prep modes, change detection, weekly brief, child views, responsibility assignment |
| **Higher Tier** | Caregivers, multiple households, advanced routines, document history, travel planning, school-year planning |

---

## Growth Model

Natural growth loops through coordination:
- Share today's plan with a spouse
- Send a checklist to a child
- Share pickup instructions with a caregiver
- Share a weekly brief with the household
- Invite a second parent when they receive assigned actions

Growth comes from usefulness, not spam.

---

## Key Risks

1. **Input friction** — If sharing/forwarding into Nabbo feels harder than remembering, the product fails
2. **AI trust** — If extraction is wrong too often, users stop relying on the product
3. **Becoming another inbox** — If parents feel they have one more place to clean, Nabbo adds work
4. **Overbuilding** — Family life touches everything; Nabbo can easily become too broad
5. **Weak habit formation** — The app must become useful during real pressure moments
6. **Coordination sensitivity** — Household responsibility can be emotionally loaded; Nabbo should create clarity, not blame

# Discovery Engine — "Get Me Something to Do"

## Purpose

Help parents find real local family events and activities for weekends and holidays. Not generic "visit a museum" suggestions — actual events happening nearby: the village fête, the farm open day, the kids workshop at the community centre.

---

## Core Concept

Nabbo crawls and aggregates local event sources per country, stores them in a shared events database, and serves personalized suggestions to each household based on location, children's ages, and interests.

Events are stored centrally — not fetched per-request. A background job regularly updates the database. The app shows a dedicated "Explore" tab with a feed of upcoming activities near the family.

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│  Scheduled Cloud Function (daily/twice daily)    │
│                                                  │
│  For each supported country:                     │
│    1. Fetch all configured RSS/iCal/JSON feeds   │
│    2. Query Gemini with Search Grounding for     │
│       additional local events                    │
│    3. Parse, deduplicate, geocode                │
│    4. Store in centralEvents/ collection         │
└──────────────────────┬──────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────┐
│  Firestore: centralEvents/{eventId}              │
│                                                  │
│  Shared across all households in that country    │
│  TTL: auto-delete events older than 7 days       │
│  Updated daily by the crawler                    │
└──────────────────────┬──────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────┐
│  App: "Explore" tab (new nav tab)                │
│                                                  │
│  Queries centralEvents/ filtered by:             │
│    - Distance from household (≤30km)             │
│    - Date (upcoming 7 days)                      │
│    - Age appropriateness                         │
│    - Excludes already-done items                 │
│  Ranks by: distance, interests, novelty          │
│  Shows as a scrollable feed of event cards       │
└─────────────────────────────────────────────────┘
```

---

## Data Model

### Central Events Collection (shared, not per-household)

```
centralEvents/{eventId}
```

| Field | Type | Description |
|-------|------|-------------|
| id | string | Auto-generated |
| title | string | Event name |
| description | string | Short description (max 500 chars) |
| date | timestamp | Event date + time |
| endDate | timestamp? | End date if multi-day or has duration |
| location | map | `{ name, address, lat, lng }` |
| country | string | ISO 3166-1 alpha-2 (e.g., "LU", "DE", "FR") |
| region | string? | State/province/canton for sub-filtering |
| cost | string? | "Free", "€5", "€15 family", etc. |
| ageRange | string? | "All ages", "3+", "6-12", etc. |
| category | string | outdoor, indoor, cultural, sports, creative, nature, market, festival, workshop |
| sourceUrl | string? | Link to original event page |
| sourceName | string | Feed display name or web domain |
| sourceType | string | "feed" or "search" |
| imageUrl | string? | Event image if available |
| fetchedAt | timestamp | When this event was last fetched/refreshed |
| expiresAt | timestamp | Auto-delete after this date (event date + 1 day) |

### Source Registry (admin config)

```
eventSources/{sourceId}
```

| Field | Type | Description |
|-------|------|-------------|
| id | string | Auto-generated |
| country | string | ISO country code |
| name | string | Display name (e.g., "Events.lu", "Ville de Luxembourg") |
| url | string | Feed URL |
| feedType | string | "rss", "ical", "json" |
| language | string | "en", "fr", "de", "lb" |
| active | boolean | Enable/disable without deleting |
| lastFetched | timestamp? | Last successful fetch |
| lastError | string? | Last error message (for monitoring) |

### Household Suggestions (personalized cache per household)

```
households/{householdId}/exploreFeed/{eventId}
```

Not stored separately — the Explore tab queries `centralEvents/` directly with filters. No per-household duplication needed.

---

## Navigation: New "Explore" Tab

The current navigation is: **Feed** | **FAB** | **Settings**

Updated navigation: **Feed** | **Explore** | **FAB** | **Settings**

### Explore Tab Layout

```
┌──────────────────────────────────────────┐
│  Explore                                  │
│  Activities near you this week            │
├──────────────────────────────────────────┤
│                                          │
│  This weekend                            │
│  ┌────────────────────────────────────┐  │
│  │ 🎪 Village Summer Fête             │  │
│  │ Saturday 14:00–22:00               │  │
│  │ 📍 Hesperange · 2.3km             │  │
│  │ Free · All ages                    │  │
│  │ Source: hesperange.lu              │  │
│  │                    [Add to plan]   │  │
│  └────────────────────────────────────┘  │
│  ┌────────────────────────────────────┐  │
│  │ 🍓 Strawberry Picking              │  │
│  │ Saturday–Sunday, 9:00–17:00        │  │
│  │ 📍 Bettembourg Farm · 8.1km       │  │
│  │ €4/person · Ages 3+               │  │
│  │ Source: visitluxembourg.com        │  │
│  │                    [Add to plan]   │  │
│  └────────────────────────────────────┘  │
│                                          │
│  Next week                               │
│  ┌────────────────────────────────────┐  │
│  │ 🎨 Kids Art Workshop               │  │
│  │ Wednesday 14:00–16:00              │  │
│  │ 📍 Maison Relais · 1.2km          │  │
│  │ €8/child · Ages 5-12              │  │
│  │ Source: hesperange.lu              │  │
│  │                    [Add to plan]   │  │
│  └────────────────────────────────────┘  │
│                                          │
│  ─── Nothing more this week ───          │
│                                          │
└──────────────────────────────────────────┘
```

### Explore Card Design

- White card with subtle border (same style as feed cards)
- Category emoji top-left
- Title: bold, 16px
- Date/time: secondary color, 13px
- Location + distance: with 📍, muted, 13px
- Cost + age range: chips or inline text
- Source: small link at bottom, tappable
- "Add to plan" button: right-aligned, primary color pill

### Grouping

- "This weekend" — events on Saturday/Sunday
- "Next week" — events Mon–Fri of next week
- "Coming up" — events beyond next week (if any)

### Empty State

If no events found for the area:
> "No events found near you this week. We're always looking — check back soon!"

### Pull-to-Refresh

Pull down to trigger a fresh fetch for the household's area (queries `centralEvents/` with updated filters, doesn't re-crawl sources — that's the background job's responsibility).

---

## Background Crawler

### Scheduled Cloud Function: `fetchLocalEvents`

**Schedule:** Runs twice daily (06:00 and 18:00 UTC)

**Logic:**
1. Load all active sources from `eventSources/` collection
2. Group by country
3. For each country:
   a. Fetch all configured feeds (RSS/iCal/JSON) — 5s timeout per source
   b. Parse events from feeds
   c. Query Gemini with Search Grounding for additional events in that country's major cities
   d. Geocode any events with text addresses but no coordinates
   e. Merge + deduplicate (70% title match + same date + within 1km = duplicate)
   f. Write/update to `centralEvents/` collection
4. Delete expired events (expiresAt < now)

### Gemini Search Grounding Prompt

```
Search the web for family-friendly events happening between {startDate} and {endDate} 
near {city}, {country}.

Look specifically for:
- Local festivals, fêtes, and community events
- Markets (Christmas, farmers, flea)
- Kids workshops and activities
- Open days (fire station, farm, factory)
- Outdoor family events (hikes, bike tours, nature walks with guides)
- Cultural events suitable for families (theatre, cinema, exhibitions)
- Sports events for kids (tournaments, open try-outs)

DO NOT suggest:
- Permanent attractions (museums, parks, zoos) unless they have a SPECIFIC event this week
- Generic activities ("go for a walk", "visit a castle")
- Events requiring annual membership
- Adult-only events

For each event found, provide:
- title
- date and time
- location (name + address)
- description (1-2 sentences)
- source URL (the web page you found it on)
- cost (if mentioned)
- age range (if mentioned)
- category (outdoor/indoor/cultural/sports/creative/nature/market/festival/workshop)

Return as JSON array. Maximum 15 events.
```

---

## Personalization (client-side filtering)

The Explore tab queries `centralEvents/` and applies these filters:

| Filter | Logic |
|--------|-------|
| **Distance** | Only show events within 30km of household lat/lng |
| **Date** | Only show events in the next 7 days |
| **Age** | Exclude events where minimum age > oldest child OR maximum age < youngest child |
| **Already done** | Exclude events with 70%+ title match to confirmed/completed items of type "event" in past 90 days |
| **Interests** | Boost ranking for events matching household associations (sports → sports events score higher) |
| **Weather** | On rainy days, rank indoor events higher (use existing weather data from feed) |

---

## Entry Points

| Entry Point | Behavior |
|------------|----------|
| **Explore tab** (new nav item) | Shows full scrollable feed of nearby events |
| **Empty day in Child Week View** | "Find something to do" → opens Explore filtered to that date |
| **Weekend card in Feed** (proactive) | Friday 17:00, if Saturday empty → show top 3 from Explore as a compact card |
| **FAB menu option** | "🎯 Explore" alongside Text/Photo |

---

## Country Expansion

### Initial: Luxembourg 🇱🇺

Research and configure these sources:
- `events.lu` / `agenda.lu`
- Ville de Luxembourg event calendar
- `visitluxembourg.com/en/agenda`
- Individual commune sites (Hesperange, Esch, Differdange, Dudelange)

### Phase 2: Belgium 🇧🇪, Germany 🇩🇪, France 🇫🇷

For each country:
1. Identify 3-5 best regional event sources
2. Add to `eventSources/` collection
3. Gemini Search Grounding automatically covers any country

### Adding a new country:
1. Research local event sources (RSS/iCal feeds)
2. Add entries to `eventSources/` in Firestore (no deploy needed)
3. Next crawler run picks them up automatically
4. Gemini Search Grounding already works for any location

---

## Household Location Requirement

The household model needs **latitude and longitude** stored (not just city name string). 

Options:
- Use Google Places autocomplete (already in settings) — it returns lat/lng
- Geocode the city field on first Explore tab open
- Add a location picker during onboarding

Current state: household has `city` field from Places autocomplete. We should store `lat`/`lng` alongside it (may already be available from the Places result — check implementation).

---

## Rate Limiting & Costs

| Mechanism | Limit |
|-----------|-------|
| Crawler runs | 2x daily per country |
| Gemini Search calls per country per run | Max 5 (one per major city/region) |
| Events stored per country | Max 200 active |
| Explore tab refresh | Client queries Firestore, no cost beyond reads |
| "Add to plan" | Single Firestore write |

Estimated cost: ~$5-10/month per supported country (Gemini calls + Firestore storage).

---

## What This Is NOT

- Not a social network (no user-generated content in v1)
- Not a booking platform (we link to source, don't handle payments)
- Not a full event aggregator (curated sources per country, not "all events everywhere")
- Not real-time (events updated twice daily, not per-minute)

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Explore tab opened per active household per week | ≥ 2x |
| Events added to plan from Explore per household per month | ≥ 2 |
| Explore tab used on weekends | ≥ 40% of opens on Sat/Sun |
| Households that return to Explore after first use | ≥ 60% |

---

## Build Order

| Phase | What | Effort |
|-------|------|--------|
| 1 | Central events collection + Source Registry data model | Small |
| 2 | Background crawler Cloud Function (feeds + Gemini Search) | Large |
| 3 | Explore tab UI (event cards, grouping, filters) | Medium |
| 4 | "Add to plan" flow | Small |
| 5 | Luxembourg source research + configuration | Small |
| 6 | Weekend proactive card in Feed | Small |
| 7 | Empty day prompt in Child Week View | Small |
| 8 | Country expansion (Belgium, Germany, France) | Medium per country |

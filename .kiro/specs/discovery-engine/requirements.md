# Requirements Document

## Introduction

The Discovery Engine is a "Get me something to do" feature for Nabbo that helps parents find real, specific local family events and activities for weekends and holidays. Unlike generic AI suggestions, it sources actual events from local commune websites, tourism boards, and community calendars — things like village fêtes, fire station open days, farm picking days, and kids workshops that only exist on scattered local web pages.

The feature combines two data strategies: country-specific structured feeds (RSS/iCal) managed in backend configuration, and Gemini with Google Search grounding for real-time web discovery. Results are personalized by family location, children's ages, household interests, past activities, weather, and season. Any suggested event can be added to the family plan with one tap.

## Glossary

- **Discovery_Engine**: The backend Cloud Function and associated logic that fetches, merges, filters, ranks, and returns local event suggestions for a household
- **Event_Source**: A configured URL providing structured event data (RSS feed, iCal calendar, or JSON endpoint) for a specific country
- **Source_Registry**: The backend configuration store holding all Event_Sources grouped by country, including URL, feed type, and metadata
- **Suggestion_Card**: A UI card in the Flutter app displaying a single discovered event/activity with title, date, location, description, distance, and an "Add to plan" action
- **Search_Grounding**: Gemini's capability to perform real-time Google Search to find current information from the web, used here to discover local events not covered by structured feeds
- **Household_Context**: The combination of household location (city/coordinates), children's ages, family interests (from Associations collection), and completed item history used for personalization
- **Country_Configuration**: The set of Event_Sources and search parameters configured for a specific supported country
- **Suggestion_Request**: A Cloud Function invocation carrying householdId, location, date range, and optional filters to produce event suggestions
- **Deduplication**: The process of identifying and merging duplicate events found across multiple sources (feeds + web search) into a single suggestion
- **Relevance_Score**: A numeric ranking assigned to each suggestion based on distance, age-appropriateness, interest match, novelty, and timing

## Requirements

### Requirement 1: Trigger Discovery

**User Story:** As a parent, I want to tap a button to get local activity suggestions, so that I can find something fun to do with my family without manually searching the web.

#### Acceptance Criteria

1. WHEN the parent taps the "Get me something to do" button, THE Discovery_Engine SHALL create a Suggestion_Request with the household's location, children's ages, date range (next 7 days), and family interests
2. WHEN the Suggestion_Request is created, THE Discovery_Engine SHALL return results within 10 seconds
3. WHILE the Discovery_Engine is processing a Suggestion_Request, THE App SHALL display a loading state with a contextual message
4. WHEN the Discovery_Engine returns results, THE App SHALL display up to 5 Suggestion_Cards ranked by Relevance_Score
5. IF the Discovery_Engine fails to return results, THEN THE App SHALL display an error state with a retry option

### Requirement 2: Fetch Events from Structured Feeds

**User Story:** As a parent, I want Nabbo to check local event calendars and community feeds, so that I see real upcoming events happening near me.

#### Acceptance Criteria

1. WHEN a Suggestion_Request is received, THE Discovery_Engine SHALL fetch events from all Event_Sources in the Source_Registry matching the household's country
2. WHEN an Event_Source returns valid event data, THE Discovery_Engine SHALL parse the feed (RSS, iCal, or JSON) and extract title, date, location, and description for each event
3. IF an Event_Source fails to respond within 5 seconds, THEN THE Discovery_Engine SHALL skip that source and continue processing remaining sources
4. IF an Event_Source returns malformed data, THEN THE Discovery_Engine SHALL log the error and skip that source without failing the entire request
5. THE Discovery_Engine SHALL only include events whose date falls within the requested date range

### Requirement 3: Fetch Events via Search Grounding

**User Story:** As a parent, I want Nabbo to search the web for local family events beyond what's in configured feeds, so that I discover things I wouldn't find on my own.

#### Acceptance Criteria

1. WHEN a Suggestion_Request is received, THE Discovery_Engine SHALL query Gemini with Search_Grounding for family events near the household's location within the requested date range
2. THE Discovery_Engine SHALL include household context (children's ages, city name, country) in the search query to Gemini
3. WHEN Gemini returns search-grounded results, THE Discovery_Engine SHALL extract structured event data: title, date, location, description, and source URL for each event
4. IF Gemini fails to return search-grounded results, THEN THE Discovery_Engine SHALL continue with feed-only results without failing the request
5. THE Discovery_Engine SHALL instruct Gemini to prioritize specific local events (markets, festivals, open days, workshops) over generic suggestions (visit a museum, go hiking)

### Requirement 4: Merge and Deduplicate Events

**User Story:** As a parent, I want to see a clean list of unique suggestions without duplicates, so that I can quickly browse my options.

#### Acceptance Criteria

1. WHEN events are collected from both feeds and Search_Grounding, THE Discovery_Engine SHALL merge all events into a single list
2. THE Discovery_Engine SHALL identify duplicate events by comparing title similarity, date, and location proximity
3. WHEN duplicates are detected, THE Discovery_Engine SHALL keep the version with the most complete information (longest description, has location coordinates, has source URL)
4. THE Discovery_Engine SHALL assign a source attribution to each merged event indicating whether it came from a structured feed, web search, or both

### Requirement 5: Personalization Filtering

**User Story:** As a parent, I want suggestions tailored to my family's ages, interests, and location, so that results are relevant and not generic.

#### Acceptance Criteria

1. THE Discovery_Engine SHALL exclude events located more than 30 kilometers from the household's configured location
2. THE Discovery_Engine SHALL exclude events that are age-inappropriate based on the youngest and oldest child in the household
3. THE Discovery_Engine SHALL exclude events matching items in the household's Items collection with status "confirmed" or "completed" in the past 90 days (already done)
4. WHEN the household has Associations with activity categories (sports, arts, outdoor, educational), THE Discovery_Engine SHALL boost the Relevance_Score of events matching those categories
5. THE Discovery_Engine SHALL consider current weather conditions when ranking outdoor versus indoor activities

### Requirement 6: Ranking and Scoring

**User Story:** As a parent, I want the most relevant suggestions shown first, so that I can quickly find something that fits my family.

#### Acceptance Criteria

1. THE Discovery_Engine SHALL assign a Relevance_Score to each event based on: distance (closer is better), age-appropriateness, interest match, novelty, and timing proximity
2. THE Discovery_Engine SHALL rank events by Relevance_Score in descending order
3. THE Discovery_Engine SHALL prioritize events happening sooner (this weekend) over events happening later in the date range
4. THE Discovery_Engine SHALL boost events the family has not done before (novelty factor)
5. THE Discovery_Engine SHALL return the top 5 events after filtering and ranking

### Requirement 7: Suggestion Card Display

**User Story:** As a parent, I want each suggestion to show me the key details at a glance, so that I can decide quickly whether it's interesting.

#### Acceptance Criteria

1. THE Suggestion_Card SHALL display: event title, date and time, location name, distance from home, a short description (max 3 lines), and source attribution
2. WHEN an event has an age range specified, THE Suggestion_Card SHALL display the age range
3. WHEN an event has a cost specified, THE Suggestion_Card SHALL display the price or "Free"
4. THE Suggestion_Card SHALL display an "Add to plan" button
5. THE Suggestion_Card SHALL be dismissible via swipe, removing it from the current suggestion list

### Requirement 8: One-Tap Add to Plan

**User Story:** As a parent, I want to add a suggested event to my Nabbo plan with one tap, so that I can commit to it without re-typing details.

#### Acceptance Criteria

1. WHEN the parent taps "Add to plan" on a Suggestion_Card, THE App SHALL create an Item in the household's Items collection with status "confirmed"
2. THE App SHALL pre-fill the created Item with: title from the event, date from the event, location from the event, and description in the notes field
3. THE App SHALL set the Item type to "event"
4. WHEN the event has a specific time, THE App SHALL set the Item date field to include the time in the household's timezone
5. WHEN the Item is created, THE App SHALL show a confirmation and remove the Suggestion_Card from the list

### Requirement 9: Proactive Weekend Suggestion

**User Story:** As a parent, I want Nabbo to suggest weekend activities on Friday evening if Saturday is empty, so that I get ideas without having to ask.

#### Acceptance Criteria

1. WHEN it is Friday after 17:00 in the household's timezone AND the household has no confirmed Items for Saturday, THE Discovery_Engine SHALL generate a proactive Suggestion_Request for the weekend (Saturday and Sunday)
2. WHEN proactive suggestions are ready, THE App SHALL display a weekend suggestion card at the top of the Feed
3. THE weekend suggestion card SHALL show up to 3 event suggestions in a compact format
4. WHEN the parent taps the weekend suggestion card, THE App SHALL navigate to the full suggestion list with all results
5. IF the parent dismisses the weekend suggestion card, THEN THE App SHALL not show another proactive suggestion until the following week

### Requirement 10: Country-by-Country Source Configuration

**User Story:** As a product owner, I want to manage event sources per country in backend configuration, so that I can expand to new countries over time without app updates.

#### Acceptance Criteria

1. THE Source_Registry SHALL store Event_Sources grouped by country code
2. Each Event_Source in the Source_Registry SHALL include: URL, feed type (rss, ical, json), display name, language, and active status
3. THE Discovery_Engine SHALL only query Event_Sources where the active status is true
4. WHEN no Event_Sources are configured for the household's country, THE Discovery_Engine SHALL rely solely on Search_Grounding for event discovery
5. THE Source_Registry SHALL be stored in Firestore and be modifiable without redeploying Cloud Functions

### Requirement 11: Empty Day Prompt in Child Week View

**User Story:** As a parent viewing my child's week, I want to see a prompt on empty days offering to find activities, so that I can fill gaps in my child's schedule.

#### Acceptance Criteria

1. WHILE viewing the Child Week View AND a day has no confirmed Items for that child, THE App SHALL display a "Find something to do" prompt on that empty day
2. WHEN the parent taps the "Find something to do" prompt, THE App SHALL trigger a Suggestion_Request for that specific date
3. THE Suggestion_Request triggered from Child Week View SHALL additionally filter results by the specific child's age

### Requirement 12: Source URL Attribution

**User Story:** As a parent, I want to see where a suggested event came from, so that I can verify details or get more information.

#### Acceptance Criteria

1. WHEN a suggestion has a source URL, THE Suggestion_Card SHALL display a tappable link to the original event page
2. WHEN the parent taps the source link, THE App SHALL open the URL in the device's default browser
3. WHEN a suggestion came from a structured feed, THE Suggestion_Card SHALL display the feed's display name as the source
4. WHEN a suggestion came from Search_Grounding, THE Suggestion_Card SHALL display the web domain as the source

# Requirements Document

## Introduction

The Family Activity Feed gives parents a chronological timeline of household actions — captures, approvals, edits, completions, and delegations. It makes the household feel "alive" by surfacing what has happened recently, providing shared visibility into family logistics activity. The feature works with the current single-user authentication model but is designed to scale naturally when multi-user households are introduced later.

This is distinct from the existing Feed (which shows items grouped by date for forward-looking planning). The Activity Feed is a backward-looking timeline answering: "What has happened in our household recently?"

## Glossary

- **Activity_Feed**: A chronological timeline view displaying recent household actions performed by family members
- **Activity_Event**: A single recorded action in the household (e.g., an approval, a capture, an edit, a completion)
- **Actor**: The family member who performed an action (resolved from authenticated user or inferred from context)
- **Activity_Card**: A UI component rendering a single Activity_Event in the timeline
- **Activity_Collection**: The Firestore subcollection `households/{householdId}/activityEvents/` storing Activity_Event documents
- **Household**: The top-level Firestore document representing a family unit
- **Family_Member**: A person stored in `households/{householdId}/members/` with name, role, color, and photoUrl
- **Item**: A household action item stored in `households/{householdId}/items/`
- **Source_Message**: A raw captured input stored in `households/{householdId}/sourceMessages/`
- **Activity_Type**: The category of action recorded (capture, approval, autoApproval, edit, completion, cancellation)

## Requirements

### Requirement 1: Record Household Activity Events

**User Story:** As a parent, I want household actions to be automatically recorded as activity events, so that I can see what has happened in our family logistics without manually logging anything.

#### Acceptance Criteria

1. WHEN a parent approves an item, THE Activity_Feed SHALL create an Activity_Event recording the approval with the actor, item title, child name (if assigned), and timestamp
2. WHEN a source message is successfully processed and items are extracted, THE Activity_Feed SHALL create an Activity_Event recording the capture with the actor, number of extracted items, input method, and timestamp
3. WHEN a parent marks an item as completed, THE Activity_Feed SHALL create an Activity_Event recording the completion with the actor, item title, child name (if assigned), and timestamp
4. WHEN a parent cancels an item, THE Activity_Feed SHALL create an Activity_Event recording the cancellation with the actor, item title, child name (if assigned), and timestamp
5. WHEN a parent edits a confirmed item, THE Activity_Feed SHALL create an Activity_Event recording the edit with the actor, item title, list of changed field names, and timestamp
6. WHEN auto-approval confirms a high-confidence item without user review, THE Activity_Feed SHALL create an Activity_Event recording the auto-approval with actorId set to "system", the item title, child name (if assigned), and timestamp
7. THE Activity_Feed SHALL store each Activity_Event in the Activity_Collection as a Firestore document
8. IF the Activity_Event Firestore write fails, THEN THE Activity_Feed SHALL allow the originating action (approval, completion, cancellation, edit) to complete successfully and discard the failed Activity_Event without retrying

### Requirement 2: Activity Event Data Structure

**User Story:** As a developer, I want activity events to follow a consistent data structure, so that the UI can render them uniformly and queries remain efficient.

#### Acceptance Criteria

1. THE Activity_Event SHALL contain the fields: id, householdId, activityType, actorId, actorName, title, subtitle, childId, childName, relatedItemId, sourceMessageId (optional, for capture events), metadata, createdAt
2. THE Activity_Event activityType field SHALL be one of: capture, approval, autoApproval, edit, completion, cancellation
3. WHEN an Activity_Event references a family member as actor, THE Activity_Feed SHALL store both actorId and actorName for display without additional lookups
4. WHEN an Activity_Event references a child, THE Activity_Feed SHALL store both childId and childName for display without additional lookups
5. THE Activity_Event metadata field SHALL store activity-type-specific details as a map (e.g., changed fields for edits, item count for captures, input method for captures)
6. IN single-user mode, actorName SHALL be resolved from the family member with role primaryParent in the household's members subcollection, falling back to the authenticated user's displayName if no primaryParent member is found

### Requirement 3: Display Activity Timeline

**User Story:** As a parent, I want to see a chronological timeline of recent household activity, so that I can quickly understand what has been happening in our family logistics.

#### Acceptance Criteria

1. THE Activity_Feed SHALL display Activity_Events in reverse chronological order (newest first)
2. THE Activity_Feed SHALL group Activity_Events by relative date headers: "Today" for the current calendar day, "Yesterday" for the previous calendar day, and the formatted date (e.g., "Wed, 9 Jul") for all older entries
3. THE Activity_Feed SHALL display each Activity_Event as an Activity_Card showing: actor name or avatar, action description, related child name as a chip (if childName is set), and a relative timestamp (e.g., "2 min ago" for events less than 60 minutes old, "3:45 PM" for events older than 60 minutes on the same day, and the time for events on previous days)
4. WHEN an Activity_Card references a family member, THE Activity_Feed SHALL display the member's photoUrl as the avatar indicator, falling back to a circle filled with the member's assigned hex color containing their first initial in white if photoUrl is not available
5. THE Activity_Feed SHALL load a maximum of 50 Activity_Events on initial display, and WHEN the user scrolls to the bottom of the loaded list, THE Activity_Feed SHALL load the next batch of up to 50 Activity_Events ordered by createdAt descending
6. IF the Activity_Feed fails to load the next batch of Activity_Events, THEN THE Activity_Feed SHALL display an inline error message with a retry action, preserving all previously loaded events
7. WHEN the Activity_Feed has no events to display, THE Activity_Feed SHALL show an empty state with the message "No activity yet. Capture something to get started." and a prompt icon

### Requirement 4: Activity Card Content Formatting

**User Story:** As a parent, I want activity descriptions to read naturally like a family story, so that the feed feels warm and alive rather than like a system log.

#### Acceptance Criteria

1. WHEN the activityType is approval, THE Activity_Card SHALL display the description in the format "[Actor] approved [item title]" with the child name shown as a colored chip if childName is set, or omitted entirely if childName is null
2. WHEN the activityType is capture, THE Activity_Card SHALL display the description in the format "[Actor] captured [N] item(s) from [input method]"
3. WHEN the activityType is completion, THE Activity_Card SHALL display the description in the format "[Actor] completed [item title]" with the child name shown as a colored chip if childName is set, or omitted entirely if childName is null
4. WHEN the activityType is cancellation, THE Activity_Card SHALL display the description in the format "[Actor] cancelled [item title]" with the child name shown as a colored chip if childName is set, or omitted entirely if childName is null
5. WHEN the activityType is edit, THE Activity_Card SHALL display the description in the format "[Actor] updated [item title]" showing up to 2 changed field names (e.g., "date, location") and "+ N more" if additional fields were changed
6. WHEN the activityType is autoApproval, THE Activity_Card SHALL display the description in the format "Auto-approved [item title]" with the child name shown as a colored chip (if set) and a sparkle indicator
7. THE Activity_Feed SHALL NOT create duplicate Activity_Events for the same activityType on the same relatedItemId within a 5-second window

### Requirement 5: Activity Feed Navigation and Placement

**User Story:** As a parent, I want to access the activity feed easily from the main app, so that I can check household activity without disrupting my workflow.

#### Acceptance Criteria

1. THE Activity_Feed SHALL be accessible from the Feed screen as a toggle or tab at the top (switching between "Feed" and "Activity" views within the same screen)
2. WHEN the parent switches to the Activity view, THE Activity_Feed SHALL load and display the activity timeline within 2 seconds without a full page navigation (the view renders inline within the Feed screen)
3. WHEN the parent switches back to the Feed view, THE Activity_Feed SHALL preserve its scroll position until the app is removed from memory or the user signs out
4. WHEN the parent opens the Activity view, THE Activity_Feed SHALL reset the unread badge count to zero
5. THE Activity_Feed SHALL display an unread activity count badge on the Activity toggle when new events have occurred since the parent last viewed the Activity tab, showing the numeric count up to 99 and displaying "99+" for counts exceeding 99
6. THE last-viewed timestamp for the unread badge SHALL be stored locally on-device using SharedPreferences and resets on app reinstall
7. IF the Activity_Feed fails to load activity data, THEN THE Activity_Feed SHALL display an error message indicating the failure with a retry option, without affecting the Feed view

### Requirement 6: Activity Event Tap Navigation

**User Story:** As a parent, I want to tap on an activity event to see the related item, so that I can quickly get details about what happened.

#### Acceptance Criteria

1. WHEN a parent taps an Activity_Card that references an existing item with status confirmed, completed, or cancelled, THE Activity_Feed SHALL navigate to the Item Detail screen for that item
2. WHEN a parent taps an Activity_Card that references an item with status pendingReview, THE Activity_Feed SHALL navigate to the Review Detail screen for the source message linked to that item
3. IF a parent taps an Activity_Card whose referenced item has been deleted or fails to load, THEN THE Activity_Feed SHALL display an inline message "This item is no longer available" for 3 seconds without navigating away
4. WHEN a parent taps a capture Activity_Card where linked items are still pending review, THE Activity_Feed SHALL navigate to the Review Detail screen for that source message
5. WHILE a source message has processingStatus of pending or processing, THE Activity_Feed SHALL disable tap interaction on capture Activity_Cards for that source

### Requirement 7: Real-Time Activity Updates

**User Story:** As a parent, I want the activity feed to update in real time, so that I see new household activity as it happens without manually refreshing.

#### Acceptance Criteria

1. THE Activity_Feed SHALL use a Firestore real-time listener on the Activity_Collection to receive new events within 3 seconds of the document being written to Firestore
2. WHEN a new Activity_Event is created while the parent is viewing the Activity_Feed, THE Activity_Feed SHALL prepend the new event at the top of the timeline with a fade-in entrance animation lasting between 200 and 400 milliseconds
3. WHEN a new Activity_Event is created while the parent is NOT viewing the Activity_Feed, THE Activity_Feed SHALL increment the unread badge count on the Activity toggle by 1 for each new event, up to a maximum displayed count of 99
4. IF the Firestore real-time listener disconnects due to network loss, THEN THE Activity_Feed SHALL display an offline indicator and automatically re-subscribe when connectivity is restored without requiring user action
5. WHEN the parent navigates to the Activity_Feed while the unread badge count is greater than 0, THE Activity_Feed SHALL reset the unread badge count to 0 and display all previously unread events in their correct chronological position

### Requirement 8: Activity Feed Performance

**User Story:** As a parent, I want the activity feed to load quickly and not slow down the app, so that checking activity feels instant and lightweight.

#### Acceptance Criteria

1. THE Activity_Feed SHALL query Activity_Events using a Firestore composite index on householdId and createdAt (descending)
2. THE Activity_Feed SHALL limit the initial query to a maximum of 50 documents and render the initial batch within 2 seconds of the view becoming visible
3. WHEN the user scrolls to the end of the currently loaded results, THE Activity_Feed SHALL load the next batch of up to 50 documents using cursor-based pagination (startAfter) without blocking the visible content
4. WHILE the Activity_Feed is loading additional results, THE Activity_Feed SHALL display a loading indicator below the existing content
5. IF the Firestore query fails or does not return a response within 10 seconds, THEN THE Activity_Feed SHALL display a retry prompt with the message "Couldn't load activity. Tap to retry."

### Requirement 9: Multi-User Readiness

**User Story:** As a developer, I want the activity feed data model to support multiple authenticated users per household, so that when multi-user auth is implemented, both parents see a combined activity timeline without migration.

#### Acceptance Criteria

1. THE Activity_Event SHALL store actorId as the Firebase Auth UID of the user who performed the action (or the literal string "system" for auto-approval events)
2. THE Activity_Event SHALL store actorName resolved at write-time from the family members collection so that display does not require additional lookups or auth-level user profiles
3. THE Activity_Event SHALL include householdId as a top-level field so that all events for a household are queryable without joining across users or requiring schema changes when additional users are added
4. THE Activity_Collection SHALL use Firestore security rules scoped to householdId so that any authenticated user whose UID is listed in the household's memberIds array can read all activity events for that household
5. THE Activity_Collection Firestore security rules SHALL permit write access only to authenticated users whose UID matches the actorId field of the event being created, or to Cloud Functions for system-generated events
6. IF an Activity_Event references an actorId that no longer matches an active household member, THEN THE Activity_Feed SHALL still display the event using the stored actorName without error

### Requirement 10: Activity Event Retention

**User Story:** As a parent, I want to see recent activity without the feed becoming overwhelming over time, so that the timeline stays relevant and manageable.

#### Acceptance Criteria

1. THE Activity_Feed SHALL display events from the last 30 days by default
2. WHEN the user scrolls to the bottom of the Activity_Feed, THE Activity_Feed SHALL provide a mechanism to load events older than 30 days up to a maximum of 90 days in the past
3. WHEN a scheduled Cloud Function runs, THE Activity_Feed SHALL delete all Activity_Events that are older than 90 days regardless of referenced item status
4. THE Activity_Feed SHALL NOT delete any Activity_Event that is less than 90 days old under any automated process

# Tasks

## Task 1: Create ActivityEvent data model

- [ ] Create `lib/features/activity/data/models/activity_event_model.dart`
- [ ] Define `ActivityType` enum: capture, approval, autoApproval, edit, completion, cancellation
- [ ] Define `ActivityEventModel` as a Freezed class with fields: id, householdId, activityType, actorId, actorName, title, subtitle, childId, childName, relatedItemId, sourceMessageId, metadata, createdAt
- [ ] Add `fromFirestore` factory and `TimestampConverter` for createdAt
- [ ] Run `dart run build_runner build` to generate freezed/json files

## Task 2: Create Activity repository

- [ ] Create `lib/features/activity/data/repositories/activity_repository.dart`
- [ ] Add `activityRepositoryProvider` (Riverpod Provider)
- [ ] Implement `recordEvent(String householdId, ActivityEventModel event)` — writes to `activityEvents/` subcollection, fire-and-forget (catches and ignores errors)
- [ ] Implement `watchEvents(String householdId, {int limit = 50})` — returns Stream<List<ActivityEventModel>> ordered by createdAt descending
- [ ] Implement `loadMore(String householdId, DateTime lastCreatedAt, {int limit = 50})` — cursor-based pagination using startAfter
- [ ] Implement deduplication check: skip write if same activityType + relatedItemId exists within last 5 seconds
- [ ] Add helper `resolveActorName(String householdId)` — gets primaryParent member name, falls back to auth displayName

## Task 3: Integrate activity recording into existing item flows

- [ ] In `item_repository.dart` `approve()` method: add fire-and-forget call to `activityRepository.recordEvent()` with activityType: approval
- [ ] In `item_repository.dart` `approveUpdate()` method: add activity event with activityType: approval (for confirmed updates)
- [ ] In `item_repository.dart` `approveCancel()` method: add activity event with activityType: cancellation
- [ ] In item completion flow (swipe-to-done in feed): add activity event with activityType: completion
- [ ] In `item_repository.dart` `updateItem()` method: if item status is confirmed, add activity event with activityType: edit and changed field names in metadata
- [ ] In `item_repository.dart` `deleteItem()` method: add activity event with activityType: cancellation
- [ ] Ensure all activity writes are wrapped in try/catch so failures don't block the originating action

## Task 4: Integrate activity recording into Cloud Functions

- [ ] In `extractSourceMessage` Cloud Function: after successful extraction, write capture Activity_Event with actorId from sourceMessage.userId, itemCount, inputMethod
- [ ] In auto-approval logic within `extractSourceMessage`: write autoApproval Activity_Event with actorId "system"
- [ ] Ensure Cloud Function writes use the same `activityEvents/` subcollection path

## Task 5: Create Activity Feed UI — ActivityFeedView widget

- [ ] Create `lib/features/activity/presentation/activity_feed_view.dart`
- [ ] Build a StreamBuilder listening to `activityRepository.watchEvents()`
- [ ] Group events by relative date: "Today", "Yesterday", formatted date (e.g., "Wed, 9 Jul")
- [ ] Show date headers as section separators
- [ ] Implement infinite scroll: detect scroll-to-bottom, call `loadMore()`, append results
- [ ] Show loading indicator at bottom while fetching more
- [ ] Show error state with retry button if query fails
- [ ] Show empty state: "No activity yet. Capture something to get started." with icon

## Task 6: Create ActivityCard widget

- [ ] Create `lib/features/activity/presentation/widgets/activity_card.dart`
- [ ] Display actor avatar: photoUrl as CircleAvatar, or colored circle with first initial (resolve color from members)
- [ ] Display action text formatted per activityType (see spec formats)
- [ ] Display item title in semi-bold
- [ ] Display child chip (colored background + name) if childName is set, omit if null
- [ ] Display relative timestamp: "2 min ago" (<60 min), "3:45 PM" (same day >60 min), time for older
- [ ] For autoApproval: show sparkle icon (Icons.auto_awesome) in warmYellow
- [ ] For edit events: show up to 2 changed field names from metadata, "+ N more" if >2
- [ ] Add fade-in animation support for new events prepended in real-time

## Task 7: Add Feed/Activity toggle to Feed screen

- [ ] Modify the existing Feed screen to add a segmented toggle at the top: "Feed" | "Activity"
- [ ] Use a TabBar or custom toggle widget matching the app's design system
- [ ] When "Activity" is selected, show ActivityFeedView instead of the current feed content
- [ ] When "Feed" is selected, show the existing feed (default)
- [ ] Preserve Activity scroll position when switching back and forth (use PageView or IndexedStack)

## Task 8: Implement unread badge on Activity toggle

- [ ] Store last-viewed timestamp in SharedPreferences (key: `activity_last_viewed`)
- [ ] On Activity tab open: save current timestamp to SharedPreferences, reset badge to 0
- [ ] Count unread events: query activityEvents where createdAt > last-viewed timestamp
- [ ] Display badge on the "Activity" toggle: numeric count up to 99, "99+" beyond
- [ ] Use a StreamBuilder or listener to update badge count in real-time when new events arrive while on Feed tab

## Task 9: Implement tap navigation from Activity cards

- [ ] On tap: check if relatedItemId exists and fetch the item
- [ ] If item status is confirmed/completed/cancelled → navigate to Item Detail screen
- [ ] If item status is pendingReview → navigate to Review Detail screen using sourceMessageId
- [ ] If item is deleted/unavailable → show inline SnackBar "This item is no longer available" for 3s
- [ ] For capture cards: navigate to Review Detail using sourceMessageId
- [ ] Disable tap on capture cards where source processingStatus is pending/processing

## Task 10: Add Firestore index and security rules

- [ ] Add composite index to `firestore.indexes.json`: collection `activityEvents`, fields: householdId ASC, createdAt DESC
- [ ] Update `firestore.rules` to allow read/write on `activityEvents` subcollection scoped to household members
- [ ] Deploy indexes: `firebase deploy --only firestore:indexes`
- [ ] Deploy rules: `firebase deploy --only firestore:rules`

## Task 11: Add retention cleanup Cloud Function

- [ ] Create `cleanupActivityEvents` scheduled Cloud Function (runs daily)
- [ ] Query all activityEvents where createdAt < 90 days ago
- [ ] Delete in batches (max 500 per batch to stay within Firestore limits)
- [ ] Deploy function: `firebase deploy --only functions:cleanupActivityEvents`

## Task 12: Final integration and testing

- [ ] Verify activity events are created on: approve, complete, cancel, edit, capture, auto-approve
- [ ] Verify Activity Feed displays events grouped by date with correct formatting
- [ ] Verify tap navigation works for all activity types
- [ ] Verify unread badge increments and resets correctly
- [ ] Verify real-time updates prepend new events with animation
- [ ] Verify empty state shows when no events exist
- [ ] Verify pagination loads older events on scroll
- [ ] Build iOS release and install on device

# Feature List

## Implemented ✅

### Core App

| Feature | Description |
|---------|-------------|
| Auth (email/password) | Login, register, password reset, delete account |
| Auth persistence | Stays signed in until manual sign out |
| Onboarding (7 screens) | Welcome, household setup, add children, add people, email alias, sharing explanation, first capture |
| Auto-add primary parent as family member | Created during onboarding with random color |
| Navigation | Feed + FAB (centered) + Settings |
| App icon | Custom icon for iOS, Android, Web |

### Feed

| Feature | Description |
|---------|-------------|
| Chronological feed | Items grouped by date (today-first, past at bottom) |
| Greeting with user name | "Good evening, Hassan" |
| Weather widget | GPS-based, shows temperature + city name (OpenWeatherMap) |
| Notification bell with badge | Real-time unread count, opens Notifications screen |
| Source message cards | Shows "Analyzing..." while AI processes |
| Failed/noAction visibility | Shows with proper badges, tap to retry |
| Item cards with category icons | AI-chosen icons (basketball, swimming, school, etc.) |
| Child chips with photo/color | Shows member photo or colored initial |
| Child chip → week view | Tapping child chip navigates to per-child week view (Mon–Sun) |
| Location + time on cards | Inline with pin icon + time display |
| Recurrence indicator | Repeat icon on recurring items |
| Cancelled items visible | Shown with badge + strikethrough |
| Swipe left = done + hide | Marks complete and removes from feed |
| Swipe right = options menu | Hide / Cancel / Cancel series |
| Single occurrence cancel/hide | Via exceptions array, not full item |
| Recurrence expansion | Weekly, daily, biweekly, monthly (first weekday of month) |
| Recurrence respects endDate | Expands until end date (max 52 weeks) |

### Capture

| Feature | Description |
|---------|-------------|
| Free text capture | Type a note → source message created |
| Image capture | Take photo or pick from gallery → upload to Storage → AI reads it |
| Email forwarding | SendGrid Inbound Parse → Cloud Run → source message |
| Mobile share (Android) | receive_sharing_intent plugin |
| Animated FAB | Centered in nav bar, expands to Text/Photo options |

### AI Extraction

| Feature | Description |
|---------|-------------|
| Gemini 2.5 Flash | Text + multimodal image extraction |
| Generous extraction | Deadlines, soft actions, opportunities all create items |
| Change detection | AI compares against existing items (action: create/update/cancel) |
| Owner matching | Maps "Dad", "Mum", "I" to family members (adults only) |
| Time preservation | Proper timezone handling (store real UTC, display local) |
| Recurrence extraction | "Every Tuesday" → weekly rule with endDate |
| Notes field | Captures links, contacts, instructions, extra context |
| Category assignment | AI picks a category for contextual icons |
| Overall confidence | AI returns overallConfidence per item (high/medium/low) |
| HTML stripping | Cleans email HTML before sending to Gemini |
| School email handling | Prompt explicitly handles institutional emails |
| Household intelligence | Associations injected into prompt for child inference |
| Auto-approval | High-confidence items skip review, go directly to confirmed |

### Review

| Feature | Description |
|---------|-------------|
| Review Detail screen | Shows source message + extracted items |
| Approve/Edit/Delete actions | Per-item actions in review |
| Change proposals UI | Blue for updates, coral for cancellations, shows field diffs |
| Date required on approval | If item has no date, picker appears (defaults tomorrow 9:00) |

### Per-Child Week View

| Feature | Description |
|---------|-------------|
| Week view screen | Shows Mon–Sun for a specific child with all their items |
| Recurrence expansion | Expands daily/weekly/biweekly/monthly rules for the week |
| Respects exceptions | Skips cancelled/hidden occurrences |
| Today indicator | Purple dot next to today's date header |
| Entry from feed | Tap child chip on any feed card to navigate |
| Tap to detail | Each item row navigates to ItemDetailScreen |

### Item Detail

| Feature | Description |
|---------|-------------|
| Full item detail | All fields displayed with labels |
| Category icon in header | Based on AI-assigned category |
| Location opens Maps | Tappable link → Google Maps |
| View original message | Source traceability button |
| Mark complete | Status → completed |
| Cancel (single/series) | Single occurrence or entire series |
| Edit button | Opens Edit Item screen |

### Edit Item

| Feature | Description |
|---------|-------------|
| Type selector | Event / Task / Deadline |
| Title, summary fields | Text inputs |
| Child dropdown | Lists family members with role=child + color dot |
| Owner dropdown | Lists adults only + color dot |
| Location autocomplete | Google Places API |
| Date + time pickers | Separate date/time buttons |
| End date picker | Optional |
| Recurrence editing | Toggle, frequency, day of week, end date |
| Works at any status | Editable regardless of lifecycle stage |

### Settings

| Feature | Description |
|---------|-------------|
| Edit household | Name, timezone, language, location (Places autocomplete) |
| Family members | List with color dots, add/edit/delete, photo upload, color picker |
| Email alias | Display + copy |
| Auto-approval toggle | Enable/disable auto-confirm for high-confidence items |
| Notification preferences | Toggles per type, quiet hours (SharedPreferences) |
| History screen | See hidden/completed items, restore or delete permanently |
| Sign out / Delete account | Account management |

### Notifications (in-app)

| Feature | Description |
|---------|-------------|
| Notifications collection | Firestore subcollection per household |
| Bell icon with badge | Real-time unread count in Feed header |
| Notifications screen | Chronological list, mark as read, swipe to dismiss, tap to navigate |
| After extraction trigger | Writes notification when items are created |
| Deadline check (hourly) | Per-item dedup'd notifications for deadlines in 24h |
| Upcoming events check (30 min) | Notifications for events in next 2 hours |
| Deep linking | Tap notification → navigates to item/review |

### Household Intelligence

| Feature | Description |
|---------|-------------|
| Associations collection | child ↔ activity/contact/location/schedule |
| Built on approval | Extracts patterns when items are confirmed |
| Auto-confidence promotion | After 4+ occurrences → confirmed |
| Injected into AI prompt | Used for child inference when name not mentioned |
| Email sender learning | Associates sender email with child |
| Ambiguity picker UI | "Who is this about?" quick picker in review when childName is uncertain |

### Infrastructure

| Feature | Description |
|---------|-------------|
| Firebase project (nabbo-app-4d98a) | europe-west1 |
| Cloud Functions (5) | extractSourceMessage, checkDeadlines, checkUpcomingEvents, dailyBrief, buildAssociations |
| Cloud Run (email ingestion) | SendGrid webhook endpoint |
| Firestore indexes | Optimized for feed/review/notification queries |
| API keys in .gitignore | Places + Weather keys not in git |
| Multi-language strings | EN/FR/DE/ES translations ready (40+ keys) |
| Proper timezone handling | Store real UTC, display in local timezone |

---


## Remaining 🔲

### High Priority

| # | Feature | Effort | Description |
|---|---------|--------|-------------|
| 1 | Wire multi-language into all screens | Medium | Replace remaining hardcoded strings with `AppStrings.get()` |
| 2 | Push notifications on device | Blocked | Needs Apple Developer account ($99/year) for APNs key |
| 3 | iOS native share extension | Blocked | Needs Apple Developer account for App Groups |

### Medium Priority (polish & intelligence)

| # | Feature | Effort | Description |
|---|---------|--------|-------------|
| 4 | Household intelligence — email sender learning | Small | Phase 3: associate email senders with children on approval |
| 5 | Onboarding improvement | Small | Prompt in Feed if no children added yet |
| 6 | Item category editable by user | Small | Add category text field to Edit Item screen |
| 7 | Auto-approval ✨ indicator on feed cards | Small | Show subtle indicator for first 24h |



### Future (v2)

| # | Feature | Description |
|---|---------|-------------|
| 1 | Calendar grid view | Visual calendar showing items by day/week |
| 2 | Risk detection | Auto-generate risks (no owner, deadline near, conflict) |
| 3 | Per-owner notifications | Each parent gets their own alerts |
| 4 | Smart notification timing | Learn user patterns |
| 5 | Evening reset / tomorrow prep | "Tomorrow: pack X, deadline Y" |
| 6 | Routine suggestions | Detect repeated patterns |
| 7 | Multi-user households | Second parent account with shared data |
| 8 | Offline support | Firestore offline persistence |
| 9 | Data export | Export as PDF/CSV |
| 10 | Widget (iOS/Android) | Home screen widget |
| 11 | Apple Watch / Wear OS | Quick view of upcoming items |
| 12 | Web app (production) | Deploy to custom domain |
| 13 | AI conversation | "What does Adam have tomorrow?" |

---

## Architecture Summary

```
Flutter App (iOS + Android + Web)
    ↕ Firestore (sourceMessages, items, associations, notifications)
    ↕ Cloud Storage (images, attachments)
    ↕ Firebase Auth (email/password)

Cloud Functions (5):
    extractSourceMessage → Gemini 2.5 Flash → items/ (with auto-approval)
    checkDeadlines → notifications/ (hourly)
    checkUpcomingEvents → notifications/ (every 30 min)
    dailyBrief → notifications/ (7:30 AM daily, opt-in)
    buildAssociations → associations/ (on item approval)

Cloud Run:
    email-ingestion → SendGrid → sourceMessages/

External APIs:
    Gemini 2.5 Flash (extraction + confidence scoring)
    OpenWeatherMap (weather)
    Google Places (location autocomplete)
```

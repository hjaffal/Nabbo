# Technical Architecture

## Stack Overview

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Mobile App** | Flutter (iOS + Android + Web) | Cross-platform UI, share extension, notifications |
| **Backend Services** | Firebase | Auth, database, storage, messaging, serverless functions |
| **Cloud Platform** | Google Cloud | AI extraction, email ingestion, scheduled tasks |

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│                   Flutter App                         │
│  (iOS + Android + Web, share extension, notifications)│
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│                    Firebase                           │
│  • Auth (household accounts)                         │
│  • Firestore (2 collections per household)           │
│  • Cloud Storage (images, attachments)               │
│  • Cloud Messaging (push notifications)              │
│  • Cloud Functions (AI extraction trigger)            │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│                  Google Cloud                         │
│  • Gemini 2.5 Flash (extraction engine)              │
│  • Cloud Run (email ingestion via SendGrid)          │
│  • Cloud Tasks (scheduled deadline checks)           │
└─────────────────────────────────────────────────────┘
```

---

## Firebase Services

### Authentication
- Email/password for primary parent account
- Household-level access (single user in v1, multi-user later)

### Firestore
- **2 collections per household** (see Data Model doc):
  - `sourceMessages/` — raw captured inputs
  - `items/` — everything extracted, reviewed, and confirmed
- Real-time listeners for Feed and Review screens
- Offline persistence for Feed
- Security rules scoped to household ID

### Cloud Storage
- Uploaded images (from image capture)
- Email attachments (via Cloud Run ingestion)
- Retention policies for source traceability

### Cloud Messaging (FCM)
- Push notifications (review needed, deadlines due)
- Token management per device
- Sent after extraction and on hourly deadline check

### Cloud Functions
- **`extractSourceMessage`** — Triggered on new sourceMessage creation:
  1. Gathers household context (family members + existing items)
  2. Calls Gemini 2.5 Flash for extraction (text-only or multimodal with image)
  3. For image captures: downloads image, sends as base64 inlineData to Gemini
  4. Detects changes to existing items (action: create/update/cancel)
  5. Writes items directly to `items/` with `status: pendingReview`
  6. Updates sourceMessage `processingStatus`
  7. Sends push notification
- **`checkDeadlines`** — Scheduled hourly:
  1. Finds deadlines due within 24 hours
  2. Sends push notification reminders

---

## Google Cloud Services

### Gemini 2.5 Flash
- Core extraction engine (via `@google/genai` SDK)
- **Multimodal**: handles both text and image inputs
- API key stored as Firebase Secret (`GEMINI_API_KEY`)
- Receives: raw text + household context (family members + existing items)
- For images: receives base64-encoded image data alongside extraction prompt
- Returns: JSON array of extracted items with type, fields, confidence, uncertainty
- Prompt includes household context for accurate child matching and change detection
- Detects updates/cancellations of existing items (action field)

### Cloud Run
- Email ingestion service
- Receives forwarded emails at `*@nabboapp.com` via SendGrid Inbound Parse
- Deployed at: `https://email-ingestion-946615442462.europe-west1.run.app`
- Parses email (sender, subject, body)
- Creates sourceMessage in Firestore → triggers extraction

### Cloud Tasks (via Scheduled Functions)
- Hourly deadline check
- Sends reminders for confirmed deadlines due within 24 hours

---

## Data Flow

### Capture → Extraction → Review → Confirmed

```
1. User captures input (text/voice/image/share/email)
        │
2. sourceMessage created in Firestore
   processingStatus: 'pending'
   → Appears immediately in Feed as "Analyzing..."
        │
3. Cloud Function triggered (extractSourceMessage)
   processingStatus → 'processing'
        │
4. Function gathers context:
   - Family members (names, roles)
   - Existing confirmed items (for deduplication context)
        │
5. Calls Gemini 2.5 Flash with extraction prompt
        │
6. Gemini returns JSON array of extracted items
        │
7. Items written directly to items/ collection
   status: 'pendingReview'
   sourceMessageId set for traceability
        │
8. sourceMessage processingStatus → 'completed'
   Push notification sent: "X items need review"
        │
9. User sees items in Feed with "Review" badge
   Taps → Review detail screen
        │
10. User approves → status: 'confirmed' (same document)
    Item now shows as active in Feed under its date
```

### Key Principle: No Data Copying

- AI writes directly to `items/` — there is no intermediate `extractedItems/` collection
- Approval = status field change on the same document
- No data is copied between collections at any point
- Source traceability via `sourceMessageId` reference

---

## Firestore Structure

```
households/
  {householdId}/
    - name, timezone, language, emailAlias, primaryUserId, createdAt

    members/
      {memberId}/
        - name, role, ageGroup, photoUrl

    sourceMessages/
      {sourceId}/
        - householdId, submittedBy, inputMethod
        - originalContent, attachmentUrl, attachmentType
        - sourceApp, processingStatus, receivedAt, processedAt

    items/
      {itemId}/
        - householdId, type (event|task|deadline)
        - status (pendingReview|confirmed|completed|cancelled)
        - title, summary
        - childId, childName, ownerId, ownerName
        - date, endDate, location
        - recurrence { frequency, dayOfWeek, startDate, endDate }
        - exceptions [{ date, status?, overrides? }]
        - sourceMessageId
        - extractedFields {}, confidence {}, uncertainFields []
        - suggestedActions []
        - createdAt, updatedAt

userTokens/
  {userId}/
    - fcmToken, updatedAt
```

---

## Key Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| State management | Riverpod | Type-safe, scalable, good Firestore stream integration |
| App architecture | Feature-first + Riverpod | Separation of concerns, scales with features |
| Data model | 2 collections (sourceMessages + items) | Simple, fast queries, no data copying |
| AI model | Gemini 2.5 Flash | Fast, accurate structured extraction, cost-effective |
| AI SDK | `@google/genai` (Cloud Functions) | Direct API access, Firebase Secrets for key |
| Email ingestion | Cloud Run + SendGrid Inbound Parse | Scalable, handles attachments, domain: nabboapp.com |
| Share extension | `receive_sharing_intent` plugin | Cross-platform mobile share support |
| Offline support | Firestore offline persistence | Feed works without network |
| Notifications | FCM + Cloud Functions | Event-driven (post-extraction) + scheduled (deadlines) |
| Voice transcription | On-device `speech_to_text` plugin | No server round-trip, instant feedback |
| Code generation | Freezed + json_serializable | Type-safe models, Firestore serialization |
| Routing | GoRouter | Declarative, deep-link ready |
| Weather | OpenWeatherMap API (free tier) | Simple, reliable, city or GPS-based |
| Location autocomplete | Google Places API | Accurate address search for household + item locations |
| Change detection | Gemini context comparison | AI compares new input against existing items |

---

## Security Considerations

- Firestore security rules enforce household-level isolation
- All data encrypted at rest (Firebase default)
- Cloud Functions run with least-privilege IAM
- Gemini API key stored as Firebase Secret (not in code, not in git)
- No cross-household data leakage via query structure
- User can delete all data (account deletion flow in Settings)
- Email ingestion validates via SendGrid webhook signature

---

## Scalability Notes

- Firestore scales automatically per household
- Cloud Functions scale to zero when idle (cost-efficient)
- Cloud Run handles email spikes without provisioning
- Gemini API pay-per-use pricing
- FCM handles millions of notifications
- 2-collection architecture keeps queries simple at any scale
- No N+1 query problems — Feed reads single collection with status filter

---

## Current Deployment

| Service | Status | Region |
|---------|--------|--------|
| Flutter App | Running (iOS + Web) | N/A |
| Firebase Project | `nabbo-app-4d98a` | europe-west1 |
| Cloud Function (extractSourceMessage) | Deployed | europe-west1 |
| Cloud Function (checkDeadlines) | Deployed | europe-west1 |
| Cloud Run (email-ingestion) | Deployed | europe-west1 |
| SendGrid Inbound Parse | Configured | nabboapp.com |
| Domain | `nabboapp.com` | N/A |

# Technical Architecture

## Stack Overview

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Mobile App** | Flutter (iOS + Android) | Cross-platform UI, share extension, notifications |
| **Backend Services** | Firebase | Auth, database, storage, messaging, serverless functions |
| **Cloud Platform** | Google Cloud | AI extraction, email ingestion, scheduled tasks, speech/vision |

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│                   Flutter App                         │
│  (iOS + Android, share extension, notifications)     │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│                    Firebase                           │
│  • Auth (household accounts)                         │
│  • Firestore (data model — all 20 objects)           │
│  • Cloud Storage (source messages, images, PDFs)     │
│  • Cloud Messaging (push notifications)              │
│  • Cloud Functions (triggers, background logic)      │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│                  Google Cloud                         │
│  • Vertex AI / Gemini (extraction engine)            │
│  • Cloud Run (email ingestion service)               │
│  • Cloud Tasks (scheduled reminders, daily briefs)   │
│  • Speech-to-Text (voice input transcription)        │
│  • Vision AI (screenshot/image text extraction)      │
└─────────────────────────────────────────────────────┘
```

---

## Firebase Services

### Authentication
- Email/password for primary parent account
- Household-level access (single user in v1, multi-user later)
- Anonymous auth for onboarding preview (optional)

### Firestore
- Primary database for all 20 core data objects
- Real-time listeners for Review Inbox and Today view
- Offline persistence for Today Command Center
- Security rules scoped to household ID

### Cloud Storage
- Original source messages (images, PDFs, screenshots, voice recordings)
- Processed attachments from forwarded emails
- Retention policies for source traceability

### Cloud Messaging (FCM)
- Push notifications (review needed, changes, deadlines, owner gaps, prep reminders)
- Topic-based for household-level alerts
- Token management per device

### Cloud Functions
- Triggered on new Source Message creation → kicks off extraction pipeline
- Triggered on extraction completion → creates Review Cards
- Triggered on approval → commits objects, evaluates risks
- Scheduled functions for daily brief generation, deadline checks, notification scheduling

---

## Google Cloud Services

### Vertex AI / Gemini
- Core extraction engine
- Receives: raw text, extracted OCR text, email body, transcript
- Returns: structured JSON with detected objects, confidence per field, uncertainty markers
- Model: Gemini 1.5 Pro (strong at structured extraction from messy multilingual text)
- Prompt includes: household context (family members, routines, existing events) for change detection

### Cloud Run
- Email ingestion service
- Receives forwarded emails at `*@nabbo.app`
- Parses email (sender, subject, body, attachments)
- Stores as Source Message in Firestore + attachments in Cloud Storage
- Triggers extraction pipeline

### Cloud Tasks
- Scheduled notification delivery (morning brief, evening reset, deadline reminders)
- Preparation reminder scheduling (based on event time minus prep window)
- Deadline escalation (remind again if no action taken)
- Daily brief generation

### Speech-to-Text
- Voice input transcription
- Called from Cloud Function when voice Source Message is created
- Transcript stored alongside original audio

### Vision AI / Document AI
- OCR for screenshots, photos of paper forms, school letters
- Text extraction from images before sending to Gemini for semantic extraction
- PDF text extraction for forwarded documents

---

## Data Flow

### Capture → Extraction → Review → Commit

```
1. User captures input (share, email, text, voice)
        │
2. Source Message created in Firestore
   Attachments stored in Cloud Storage
        │
3. Cloud Function triggered
   - Voice? → Speech-to-Text → transcript
   - Image/PDF? → Vision AI → extracted text
   - Email? → parsed by Cloud Run
        │
4. Extracted text + household context sent to Gemini
        │
5. Gemini returns structured extraction (JSON)
        │
6. Extracted Items created in Firestore
   Processing status updated
   Push notification sent if urgent
        │
7. User reviews in Review Inbox
        │
8. On approval → committed objects created
   (Events, Tasks, Deadlines, Checklists, etc.)
   Risk detection runs
   Today view updates in real-time
```

### Change Detection Flow

```
1. New extraction arrives
2. Cloud Function queries existing approved objects for same household
3. Compares: date, time, location, required items against new data
4. If match found with different values → creates Change object
5. Review Card shows previous vs. new values
6. User confirms or rejects change
```

### Notification Flow

```
1. Cloud Tasks runs scheduled checks (every 15 min or event-driven)
2. Evaluates: deadlines due, owner gaps, prep needed, changes unconfirmed
3. Generates notification payload with deep-link
4. Sends via FCM to relevant device(s)
5. Suppresses if item already completed or dismissed
```

---

## Firestore Structure

```
households/
  {householdId}/
    - name, timezone, language, emailAlias, createdAt
    
    members/
      {memberId}/
        - name, role, ageGroup, color, defaultResponsibilities

    sourceMessages/
      {sourceId}/
        - inputMethod, originalContent, attachmentType, sourceApp
        - receivedAt, processedAt, processingStatus
        - extractedText, confidenceSummary

    extractedItems/
      {itemId}/
        - sourceMessageId, affectedMember, itemType
        - extractedSummary, detectedFields{}
        - confidenceLevel, uncertainFields[]
        - reviewStatus, suggestedNextStep

    events/
      {eventId}/
        - title, affectedMember, startDateTime, endDateTime
        - location, owner, status, relatedSourceId
        - changeHistory[], reminderSettings

    tasks/
      {taskId}/
        - title, affectedMember, owner, dueDate
        - priority, status, relatedEventId, relatedSourceId

    deadlines/
      {deadlineId}/
        - title, dueDate, owner, urgency, status
        - relatedTaskId, relatedFormId, relatedPaymentId

    requiredItems/
      {itemId}/
        - name, quantity, affectedMember, neededBy
        - category, packedStatus, owner, relatedEventId

    checklists/
      {checklistId}/
        - title, type, affectedMember, relatedEventId
        - items[], owner, completionStatus

    forms/
      {formId}/
        - title, affectedMember, requiredAction, dueDate
        - owner, submissionMethod, status, attachmentRef

    payments/
      {paymentId}/
        - title, amount, currency, affectedMember
        - dueDate, paymentMethod, owner, status

    locations/
      {locationId}/
        - name, address, type, linkedMembers[], defaultTravelTime

    changes/
      {changeId}/
        - relatedObjectType, relatedObjectId
        - previousValue, newValue, changeType
        - sourceMessageId, impactLevel, reviewStatus

    risks/
      {riskId}/
        - title, description, type, affectedMember
        - severity, suggestedAction, owner, status

    routines/
      {routineId}/
        - name, affectedMember, type, frequency
        - commonLocation, commonItems[], defaultOwner

    reminders/
      {reminderId}/
        - relatedObjectType, relatedObjectId
        - recipient, reminderTime, type, status
```

---

## Key Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| State management | Riverpod | Type-safe, scalable, good Firestore stream integration |
| App architecture | Clean Architecture (feature-first) | Separation of concerns, testable, scales with features |
| Firestore structure | Subcollections under household | Natural security boundary, efficient queries per household |
| AI model | Gemini 1.5 Pro (Vertex AI) | Best for structured extraction from messy multilingual text |
| Email ingestion | Cloud Run + custom domain | Scalable, stateless, handles attachments |
| Share extension | Native (Swift/Kotlin) bridged to Flutter | Required for iOS/Android share sheets |
| Offline support | Firestore offline persistence | Today view works without network |
| Notifications | FCM + Cloud Tasks | Scheduled + event-driven, deep-link support |
| Voice transcription | Google Speech-to-Text | Same ecosystem, good multilingual support |
| Image/PDF processing | Vision AI + Document AI | Handles screenshots, photos, scanned forms |

---

## Security Considerations

- Firestore security rules enforce household-level isolation
- All source messages encrypted at rest (Firebase default)
- Cloud Functions run in secure environment with least-privilege IAM
- Email ingestion validates sender domain (optional, for spam prevention)
- No cross-household data leakage possible via query structure
- User can delete all data (source messages + extracted items + committed objects)
- API keys restricted to app bundle IDs
- Gemini API calls do not retain user data for training (Vertex AI data governance)

---

## Scalability Notes

- Firestore scales automatically per household
- Cloud Functions scale to zero when idle (cost-efficient for early stage)
- Cloud Run handles email spikes without provisioning
- Gemini API has quota management (can start with pay-per-use)
- FCM handles millions of notifications without infrastructure management
- Cloud Tasks handles scheduled work without cron servers

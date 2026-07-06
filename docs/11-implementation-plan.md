# Implementation Plan (Comprehensive)

## Overview

This plan breaks the Nabbo v1 build into **8 phases** with fully detailed tasks, sub-tasks, acceptance criteria, and technical specifications for every feature described in the product requirements, extraction schema, review card spec, today command center spec, and notification strategy.

Each phase builds on the previous. The goal is to reach a testable core loop (capture → extract → review → today) by Phase 5, then layer on notifications, polish, and production readiness.

---

## Phase 1 — Foundation & Data Layer

**Goal:** Working app shell with auth, household setup, complete data model, and repository layer.

**Duration:** 2–3 weeks

---

### 1.1 Project Infrastructure

- [x] Flutter project structure (clean architecture, feature-first)
  - `lib/core/` — constants, extensions, l10n, routing, theme, utils, widgets
  - `lib/features/` — auth, onboarding, capture, review, today, settings, household
  - Each feature: `data/`, `domain/`, `presentation/`
- [x] Riverpod setup with code generation (riverpod_generator + riverpod_annotation)
- [ ] Freezed models with JSON serialization for all 20 data objects
- [x] Go Router navigation with auth guards and redirect logic
- [x] Environment configuration (dev, staging, production)
- [x] Error handling infrastructure (global error boundary, crash reporting setup)
- [x] Logging infrastructure (structured logs for debugging)

### 1.2 Firebase Setup

- [x] Firebase project creation (iOS + Android + web console)
- [x] Firebase Auth integration
  - Email/password authentication
  - Auth state persistence
  - Auth state provider (Riverpod)
  - Auth guard for protected routes
  - Password reset flow
  - Account deletion flow
- [x] Firestore configuration
  - Security rules (household-level isolation)
  - Offline persistence enabled
  - Composite indexes for common queries
- [x] Cloud Storage configuration
  - Bucket structure: `sources/{householdId}/{sourceMessageId}/`
  - Upload/download helpers
  - File size limits and validation
- [x] FCM initial setup (token registration, background handler stub)

### 1.3 Data Models (All 20 Core Objects)

Each model uses Freezed + JSON serialization + Firestore converters.

- [x] **Household** — id, name, primaryUserId, members[], timezone, defaultLanguage, notificationPreferences, emailAlias, status, createdAt, updatedAt
- [x] **FamilyMember** — id, householdId, name, role (enum), ageGroup, relationship, contactMethod, permissions, defaultResponsibilities[], linkedRoutines[], color, status
- [x] **SourceMessage** — id, householdId, submittedBy, inputMethod (enum), originalContent, attachmentUrls[], attachmentType, sourceApp, receivedAt, processedAt, processingStatus (enum), extractedText, confidenceSummary, linkedExtractedItems[], privacyStatus
- [x] **ExtractedItem** — id, householdId, sourceMessageId, affectedMemberId, itemType (enum), extractedSummary, detectedFields (map), confidenceLevel (enum), uncertainFields[], suggestedNextStep, reviewStatus (enum), createdAt
- [ ] **DecisionStatus** — id, extractedItemId, status (enum), decidedBy, decidedAt, editedFields[], dismissalReason, snoozeUntil, notes
- [ ] **Event** — id, householdId, title, affectedMemberId, startDateTime, endDateTime, location (LocationRef), owner (OwnerRef), relatedSourceId, relatedTasks[], relatedChecklist, relatedRequiredItems[], relatedPayment, relatedForm, recurrence, confidenceLevel, changeHistory[], reminderSettings, status (enum), createdAt, updatedAt
- [ ] **Task** — id, householdId, title, description, affectedMemberId, ownerId, dueDate, dueTime, priority (enum), relatedEventId, relatedSourceId, relatedFormId, relatedPaymentId, completionStatus, reminderSettings, status (enum), createdAt, updatedAt
- [ ] **Deadline** — id, householdId, title, dueDateTime, affectedMemberId, ownerId, relatedTaskId, relatedFormId, relatedPaymentId, relatedEventId, relatedSourceId, urgencyLevel (enum), reminderSchedule, status (enum), createdAt
- [ ] **RequiredItem** — id, householdId, name, quantity, affectedMemberId, relatedEventId, relatedChecklistId, relatedSourceId, ownerId, neededByDateTime, packedStatus (enum), category (enum), isRecurring, suggestedBySystem, confidence, createdAt
- [ ] **Checklist** — id, householdId, title, type (enum), affectedMemberId, relatedEventId, relatedRoutineId, items[] (embedded), ownerId, date, completionStatus, createdManually, createdAt, updatedAt
- [ ] **Form** — id, householdId, title, affectedMemberId, sourceMessageId, relatedEventId, relatedDeadlineId, ownerId, requiredAction (enum), submissionMethod, dueDate, status (enum), attachmentUrl, reminderSettings, createdAt, updatedAt
- [ ] **Payment** — id, householdId, title, amount, currency, affectedMemberId, relatedEventId, relatedSourceId, relatedDeadlineId, ownerId, paymentMethod, paymentLink, dueDate, status (enum), createdAt, updatedAt
- [ ] **Location** — id, householdId, name, address, type (enum), linkedMembers[], linkedRoutines[], linkedEvents[], travelNotes, defaultTravelTime, confidence, createdAt
- [ ] **Owner** — id, householdId, personId, assignedObjectType, assignedObjectId, assignedBy, assignedAt, status (enum), completionConfirmation, escalationStatus
- [ ] **Reminder** — id, householdId, relatedObjectType, relatedObjectId, recipientId, reminderTime, type (enum), message, status (enum), channel, createdAt
- [ ] **Change** — id, householdId, relatedObjectType, relatedObjectId, sourceMessageId, previousValue, newValue, changeType (enum), detectedAt, confidenceLevel, impactLevel (enum), reviewStatus (enum)
- [ ] **Risk** — id, householdId, title, description, affectedMemberId, relatedObjects[], type (enum), severity (enum), suggestedAction, ownerId, status (enum), createdAt, resolvedAt
- [ ] **Routine** — id, householdId, name, affectedMemberId, type (enum), frequency, commonLocation, commonItems[], defaultOwnerId, defaultChecklist, linkedEvents[], confidence, lastUsedDate, createdAt
- [ ] **HouseholdPlan** — id, householdId, planDate, type (enum), events[], tasks[], deadlines[], checklists[], risks[], unassignedItems[], changes[], completedItems[], openItems[], generatedSummary, createdAt
- [ ] **Completion** — id, householdId, relatedObjectType, relatedObjectId, completedBy, completedAt, method, notes, evidenceAttachment, confirmationStatus

### 1.4 Repository Layer

- [ ] Base repository abstract class with CRUD operations
- [x] **HouseholdRepository** — create, get, update, delete, getByUserId, updateEmailAlias, updateNotificationPrefs
- [x] **FamilyMemberRepository** — create, getAll (by household), get, update, delete, getByRole
- [x] **SourceMessageRepository** — create, getAll (by household, paginated), get, updateStatus, getByProcessingStatus, getRecent
- [x] **ExtractedItemRepository** — create, getAll (by household), get, update, getPendingReview, getBySourceMessage, getByUrgency
- [ ] **EventRepository** — create, getAll, get, update, delete, getByDate, getByMember, getUpcoming, getToday
- [ ] **TaskRepository** — create, getAll, get, update, delete, getByDueDate, getByOwner, getByStatus, getOverdue
- [ ] **DeadlineRepository** — create, getAll, get, update, getDueSoon, getOverdue, getByOwner
- [ ] **RequiredItemRepository** — create, getAll, get, update, getByEvent, getByChecklist, getUnpacked, getNeededToday
- [ ] **ChecklistRepository** — create, getAll, get, update, getByEvent, getByMember, getIncomplete
- [ ] **FormRepository** — create, getAll, get, update, getDueSoon, getByStatus, getByOwner
- [ ] **PaymentRepository** — create, getAll, get, update, getDueSoon, getByStatus, getByOwner
- [ ] **LocationRepository** — create, getAll, get, update, delete, getByType, search
- [ ] **ChangeRepository** — create, getAll, get, update, getPendingReview, getByObject
- [ ] **RiskRepository** — create, getAll, get, update, getOpen, getByMember, getBySeverity, getForToday
- [ ] **ReminderRepository** — create, getAll, get, update, delete, getScheduled, getByObject
- [ ] **RoutineRepository** — create, getAll, get, update, getByMember, getActive
- [ ] **CompletionRepository** — create, get, getByObject

### 1.5 Enums & Constants

- [ ] InputMethod: mobileShare, emailForwarding, freeText, voice, image, screenshot, pdf
- [ ] ProcessingStatus: received, processing, extracting, completed, failed, noAction
- [ ] ItemType: event, task, deadline, requiredItem, checklist, form, payment, location, change, risk, routineSuggestion
- [ ] ReviewStatus: pendingReview, approved, editedAndApproved, dismissed, snoozed, assigned, alreadyHandled, needsClarification
- [ ] ConfidenceLevel: high, medium, low, unknown
- [ ] ConfidenceLabel: clear, checkThis, missing, suggested
- [ ] EventStatus: pending, confirmed, changed, cancelled, completed, missed
- [ ] TaskStatus: open, assigned, inProgress, completed, dismissed, overdue, blocked
- [ ] DeadlineStatus: upcoming, dueToday, overdue, completed, dismissed
- [ ] PackedStatus: notReady, ready, notNeeded, alreadyHandled, ownerMissing
- [ ] FormStatus: notStarted, inProgress, completed, submitted, overdue, dismissed
- [ ] PaymentStatus: pending, paid, overdue, dismissed, unknown
- [ ] OwnerStatus: assigned, accepted, declined, completed, unassigned, needsReassignment
- [ ] ReminderStatus: scheduled, sent, dismissed, completed, failed
- [ ] RiskType: noOwner, deadlineNear, deadlineOverdue, conflictingEvents, locationChanged, itemNotPacked, paymentUnpaid, formIncomplete, travelTimeRisk, missingInfo
- [ ] RiskSeverity: low, medium, high, critical
- [ ] ChangeType: time, date, location, requiredItemAdded, requiredItemRemoved, deadline, eventCancelled, owner, payment, formRequirementAdded
- [ ] MemberRole: primaryParent, secondaryParent, child, caregiver, grandparent, babysitter, other
- [ ] Priority: low, medium, high, urgent
- [ ] ChecklistType: morningLaunch, eveningReset, schoolTrip, sportsActivity, medical, travel, weekend, eventPrep
- [ ] RequiredItemCategory: clothing, sportsGear, schoolMaterial, food, drink, document, money, medicine, device, other
- [ ] FormAction: read, sign, print, complete, upload, submitOnline, returnPhysically, bringOnDay
- [ ] LocationType: home, school, sportsClub, activityVenue, doctor, caregiverLocation, pickupPoint, dropoffPoint, other
- [ ] ReminderType: task, deadline, departure, checklist, payment, form, change, ownerReminder
- [ ] DismissalReason: notRelevant, duplicate, alreadyHandled, wrongExtraction, noActionNeeded, spamNoise
- [ ] SnoozeOption: laterToday, tomorrow, thisWeekend, nextWeek, custom

### 1.6 Authentication Flow

- [x] Login screen (email + password)
- [x] Registration screen (email + password + name)
- [x] Password reset screen
- [x] Auth state listener provider
- [x] Auto-redirect: unauthenticated → login, authenticated + no household → onboarding, authenticated + household → home
- [x] Logout functionality
- [x] Account deletion with data cleanup confirmation

### 1.7 Onboarding Flow (7 screens)

- [x] **Welcome screen** — "Don't remember it. Nabbo it." + value prop + CTA to set up household
- [x] **Household setup** — household name (required), timezone (auto-detect + manual), default language (required)
- [x] **Add children** — child name (required), age group (optional), school (optional), common activities (optional); add multiple; skip allowed
- [x] **Add other people** — second parent, caregiver, grandparent labels; optional; these are labels not accounts in v1
- [x] **Email alias screen** — show generated alias (`familyname@nabbo.app`), copy button, explain forwarding
- [x] **Sharing explanation** — explain how to use mobile share sheet with visual guidance
- [x] **First capture prompt** — 3 options: share something now, forward an email, type a quick note → onboarding ends with action

Acceptance criteria:
- User can complete onboarding in under 2 minutes
- Household is created in Firestore with all members
- Email alias is generated and displayed
- Navigation redirects to main app after completion

### 1.8 Navigation Shell & Settings

- [x] Bottom navigation: Today, Review, Settings (3 tabs)
- [x] App shell with StatefulShellRoute (preserves state between tabs)
- [x] Settings screen sections:
  - Household details (name, timezone, language)
  - Family members (list, add, edit, remove)
  - Email alias (display, copy)
  - Notifications (category toggles, quiet hours, brief timing)
  - Privacy (data deletion, source message management)
  - Account (logout, delete account)
- [x] Family member detail/edit screen
- [x] Notification preferences screen

### Phase 1 Deliverable

App launches. User can sign up, complete onboarding, create household with members, and see the main navigation shell with Today, Review, and Settings tabs. All 20 data models exist with full Firestore integration.

---

## Phase 2 — Capture Layer

**Goal:** All 4 input methods working — content enters Nabbo as Source Messages with proper status tracking and UI feedback.

**Duration:** 3–4 weeks

---

### 2.1 Free Text Capture

- [x] Capture FAB (floating action button) on Today and Review screens
- [x] Free text input screen:
  - Text field with multi-line support
  - Optional: select affected family member
  - Optional: add a note/context
  - Submit button → "Send to Nabbo"
- [x] Create SourceMessage in Firestore on submit (inputMethod: freeText, processingStatus: received)
- [x] Show confirmation: "Captured. Nabbo will review this."
- [x] Processing state indicator in recent captures list

### 2.2 Voice Capture

- [x] Voice input button (from capture FAB menu)
- [x] Audio recording UI:
  - Record/stop button with visual waveform/timer
  - Playback before submit
  - Re-record option
- [ ] Upload audio to Cloud Storage (`sources/{householdId}/{sourceId}/audio.m4a`)
- [x] Create SourceMessage (inputMethod: voice, processingStatus: received, attachmentUrls: [audioUrl])
- [ ] Cloud Function trigger: detect voice source → call Google Speech-to-Text API
- [ ] Store transcript back on SourceMessage.extractedText
- [ ] Update processingStatus to "extracting" after transcription
- [x] Show transcript in app (editable before final submit, or review after)
- [x] Error handling: transcription failure → allow manual text entry fallback

### 2.3 Mobile Share Extension

#### iOS Share Extension
- [ ] Create iOS Share Extension target (Swift)
- [ ] Configure App Groups for data passing between extension and main app
- [ ] Handle shared content types:
  - Plain text (UTType.plainText)
  - URLs (UTType.url)
  - Images (UTType.image) — save to shared container
  - PDFs (UTType.pdf) — save to shared container
  - Files (UTType.fileURL) — save to shared container
- [ ] Minimal share UI:
  - Source preview (text snippet, image thumbnail, file name)
  - Optional: select affected child dropdown
  - Optional: add note
  - "Send to Nabbo" primary action
- [ ] Write shared data to App Group UserDefaults or shared file
- [ ] Main app reads shared data on launch/resume → creates SourceMessage
- [ ] Upload attachments to Cloud Storage
- [ ] Handle extension lifecycle (completion, cancellation, errors)

#### Android Share Target
- [x] Configure intent-filter in AndroidManifest.xml for:
  - text/plain
  - image/* (jpeg, png, gif, webp)
  - application/pdf
  - */* (general file sharing)
- [x] Handle incoming intents in Kotlin/Flutter bridge
- [x] receive_sharing_intent plugin integration
- [x] Same UI flow as iOS: preview → optional child → optional note → send
- [x] Create SourceMessage and upload attachments

#### Shared Logic
- [ ] Capture confirmation screen (shared between all methods):
  - Source preview (text, image thumbnail, PDF icon, URL preview)
  - Household selector (for future multi-household)
  - Optional affected child
  - Optional note
  - Primary action: "Send to Nabbo"
  - Processing state after send
- [ ] Support detection: identify source app from share metadata when available (WhatsApp, Messages, Mail, school apps, browser)

### 2.4 Email Forwarding Service

- [x] Custom domain setup (`nabbo.app` or subdomain for inbound email)
- [x] Cloud Run email ingestion service:
  - Receive inbound emails (via SendGrid Inbound Parse, Mailgun, or Cloud Functions for Firebase email trigger)
  - Parse email: sender, subject, body (HTML → plain text), date, attachments
  - Extract relevant text from HTML email body
  - Identify household by recipient alias (e.g., `smith-family@nabbo.app`)
  - Store email body + metadata as SourceMessage (inputMethod: emailForwarding)
  - Upload attachments to Cloud Storage (PDFs, images, documents)
  - Set processingStatus: received
- [x] Unique email alias generation per household:
  - Generate from household name (slug) + random suffix
  - Store alias on Household document
  - Validate uniqueness
  - Display in settings with copy-to-clipboard
- [ ] Email validation:
  - Reject spam (basic checks: SPF, DKIM if available)
  - Reject oversized emails (>25MB)
  - Reject unsupported attachment types
  - Rate limiting per household
- [x] Error handling:
  - Invalid alias → bounce or silent discard
  - Processing failure → store raw email, mark as failed, allow retry
  - No household found → log and discard

### 2.5 Image & PDF Processing

- [ ] Cloud Function: triggered on SourceMessage creation where attachmentType is image or PDF
- [ ] Image processing pipeline:
  - Call Google Vision AI (TEXT_DETECTION) for screenshots, photos
  - Call Document AI for structured documents (forms, letters)
  - Store extracted text on SourceMessage.extractedText
  - Handle multi-page documents
  - Handle rotated or low-quality images gracefully
- [ ] PDF processing pipeline:
  - Extract text directly if text-based PDF
  - Use Document AI for scanned/image PDFs
  - Handle multi-page PDFs
  - Store extracted text
- [ ] Update processingStatus: received → processing → extracting (or failed)
- [ ] Error handling:
  - OCR failure → mark as failed, allow manual text entry
  - Unsupported format → notify user ("This file type is not supported yet.")
  - Partial extraction → store what was found, mark confidence as low

### 2.6 Processing Status UI

- [x] Recent captures list (accessible from Today or dedicated section):
  - Show last N captured items with status
  - Status indicators: processing (spinner), found (badge count), no action, error
- [x] Status messages per state:
  - Received: "Nabbo is reading this."
  - Processing: "Processing your content..."
  - Extracting: "Looking for family actions..."
  - Completed: "X items need review." (with badge)
  - No action: "No clear family action found."
  - Failed: "We could not process this. Try again or add manually."
- [ ] Tap on completed → navigate to Review Card(s)
- [ ] Tap on failed → options: retry, add manually, dismiss
- [x] Real-time status updates via Firestore listener

### 2.7 Capture Analytics & Tracking

- [ ] Track capture method distribution (share vs email vs text vs voice)
- [ ] Track capture-to-extraction time
- [ ] Track capture completion rate (started vs submitted)
- [ ] Track source app distribution (when detectable)

### Phase 2 Deliverable

Parent can send content to Nabbo via all 4 methods: free text, voice, mobile share (iOS + Android), and email forwarding. Source Messages appear in Firestore with status tracking. Images and PDFs are OCR-processed. Voice is transcribed. The app shows real-time processing status.

---

## Phase 3 — AI Extraction Engine

**Goal:** Nabbo automatically understands captured content and produces structured, confidence-scored Extracted Items with change detection and risk identification.

**Duration:** 3–4 weeks

---

### 3.1 Extraction Prompt Engineering

- [x] System prompt design:
  - Role: "You are a family household operations assistant..."
  - Input context: source text, input method, language detected
  - Household context injection: family member names + ages, existing approved events (next 14 days), known locations, known routines
  - Output schema: strict JSON matching ExtractedItem structure
  - Instructions: extract actions not summaries, separate facts from suggestions, mark confidence per field, never silently guess important fields
- [ ] Output JSON schema definition:
  ```json
  {
    "operationalSummary": "string",
    "affectedMember": { "id": "string|null", "name": "string", "confidence": "high|medium|low|unknown" },
    "detectedObjects": [
      {
        "type": "event|task|deadline|requiredItem|checklist|form|payment|location|change|risk",
        "fields": { ... },
        "confidence": "high|medium|low",
        "uncertainFields": ["field1", "field2"],
        "factOrSuggestion": "fact|suggestion|inference"
      }
    ],
    "suggestedActions": ["string"],
    "reviewRequired": true,
    "changeDetected": { ... } | null,
    "risksIdentified": [{ ... }]
  }
  ```
- [ ] Prompt variants for different input types:
  - Email (longer, multi-topic, formal language)
  - WhatsApp/message (short, informal, abbreviations)
  - Voice transcript (spoken language, filler words, corrections)
  - Image/screenshot OCR text (may have formatting artifacts)
  - Free text (direct, usually clear intent)
- [ ] Multi-language support (English, Dutch, Arabic, French, German minimum)
- [ ] Prompt testing & evaluation harness:
  - 50+ test cases covering all object types
  - Accuracy scoring per field
  - Confidence calibration testing
  - Edge case handling (empty content, gibberish, non-family content)

### 3.2 Extraction Pipeline (Cloud Function)

- [ ] Trigger: Firestore `onUpdate` on SourceMessage when processingStatus becomes "extracting"
- [ ] Pipeline steps:
  1. Read SourceMessage from Firestore
  2. Gather household context (members, recent events, known locations, active routines)
  3. Build extraction prompt with source text + household context
  4. Call Vertex AI (Gemini 1.5 Pro) with structured output mode
  5. Parse and validate AI response against expected schema
  6. Create ExtractedItem(s) in Firestore
  7. Update SourceMessage: processingStatus → "completed", link extractedItemIds
  8. If urgent items detected → trigger notification (see Phase 7)
- [ ] Retry logic: up to 3 retries on AI API failure with exponential backoff
- [ ] Timeout handling: 60-second max per extraction call
- [ ] Cost tracking: log token usage per extraction for billing visibility
- [ ] Rate limiting: queue extractions if too many concurrent requests

### 3.3 Extraction Validation & Post-Processing

- [ ] Schema validation: ensure AI output matches expected JSON structure
- [ ] Field normalization:
  - Date parsing (relative: "tomorrow", "next Tuesday", "Friday" → absolute dates)
  - Time parsing (12h/24h, "at four" → 16:00, timezone-aware)
  - Amount parsing (€5, 5 euros, EUR 5.00 → { amount: 5, currency: "EUR" })
  - Member matching: fuzzy match extracted name against household members
- [ ] Confidence recalibration:
  - If member name matches exactly → confidence: high
  - If date is relative and could be ambiguous → confidence: medium
  - If amount is mentioned without currency → confidence: medium
  - If owner is not mentioned → mark as "missing"
- [ ] Deduplication check: compare against items extracted in last 24h for same household
- [ ] Multi-item splitting: one source message → multiple ExtractedItems (e.g., school trip email with event + form + payment + required items)

### 3.4 Change Detection Logic

- [ ] Cloud Function module: runs after extraction, before creating ExtractedItem
- [ ] Detection algorithm:
  1. For each extracted event/task/deadline → query existing approved objects for same household
  2. Match criteria: same affected member + similar title/activity + overlapping date range
  3. Field comparison: date, time, location, required items, amount, deadline
  4. If match found with differing values → create Change object
  5. Link Change to ExtractedItem (set changeDetected flag)
  6. Set impactLevel based on what changed:
     - Time/date change for today/tomorrow → high
     - Location change → high
     - Required item added → medium
     - Event cancelled → high
     - Payment amount changed → medium
- [ ] Previous value storage: capture the current state of the matched object
- [ ] Change Review Card trigger: flag ExtractedItem as requiring change confirmation
- [ ] Edge cases:
  - Same event mentioned in different words (fuzzy title matching)
  - Recurring events with one instance changed
  - Complete cancellation detection ("cancelled", "no longer", "will not")
  - Partial updates (only time changed, everything else same)

### 3.5 Risk Detection Logic

- [ ] Cloud Function module: runs after extraction and after approval
- [ ] Risk generation rules (create Risk objects when detected):
  - **No owner:** Event/task/payment/form has no assigned owner and is due within 48h
  - **Deadline near:** Deadline within 24h with status not completed
  - **Deadline overdue:** Deadline past due, status still open
  - **Conflicting events:** Two events for same member at overlapping times
  - **Location changed:** Location differs from previously approved event
  - **Item not packed:** Required item for today/tomorrow with packedStatus: notReady
  - **Payment unpaid:** Payment due within 48h with status: pending
  - **Form incomplete:** Form due within 48h with status: notStarted or inProgress
  - **Travel time risk:** Event requires travel but departure time is tight
  - **Missing info:** Important field (date, time, member) has low confidence
  - **Contradictory info:** Two sources provide conflicting information
- [ ] Risk severity calculation:
  - Critical: affects today, no owner, conflicting events
  - High: affects tomorrow, overdue, changed location/time
  - Medium: due in 2-3 days, missing info
  - Low: future risk, suggestion
- [ ] Risk deduplication: don't create duplicate risks for same issue
- [ ] Risk resolution: auto-resolve risks when:
  - Owner is assigned
  - Item is marked complete/packed/paid/submitted
  - Deadline passes (mark as missed if unresolved)
  - Change is confirmed

### 3.6 Household Context Builder

- [ ] Context gathering function (called before each extraction):
  - Active family members (names, ages, roles)
  - Approved events in next 14 days (title, date, time, location, member)
  - Active tasks (title, due date, member)
  - Known locations (name, type, linked members)
  - Active routines (name, member, frequency, common items)
  - Recent changes (last 7 days)
  - Open risks (for context on existing issues)
- [ ] Context size management: limit to most relevant 20 items to stay within token budget
- [ ] Context caching: cache household context for 5 minutes to reduce Firestore reads during burst extractions

### 3.7 Extraction Error Handling

- [ ] Error states and user messages:
  - API failure → "We could not process this. Try again or add manually."
  - Invalid response → retry once, then fail gracefully
  - No action found → processingStatus: "noAction", message: "No clear family action found."
  - Partial extraction → create items for what was found, mark others as uncertain
- [ ] Manual fallback: user can always "Add manually" from a failed extraction
- [ ] Re-extraction: user can tap "Try again" to resubmit for processing
- [ ] Admin visibility: log all extraction failures with source content for debugging

### Phase 3 Deliverable

Source Messages are automatically processed by AI. Extracted Items appear in Firestore with structured fields, field-level confidence scores, fact/suggestion/inference labels, change detection results, and auto-generated risks. The extraction handles all input types, multiple languages, and produces multiple objects from a single source.

---

## Phase 4 — Review Inbox & Review Cards

**Goal:** Parent can review, verify, edit, and approve extracted items into the household plan with full trust-layer interactions.

**Duration:** 3–4 weeks

---

### 4.1 Review Inbox Screen

- [ ] Query: all ExtractedItems for household where reviewStatus == "pendingReview"
- [ ] Real-time Firestore listener (updates live as new items arrive)
- [ ] Priority sorting:
  1. Due today / tomorrow
  2. Time or location change detected
  3. Payment / form due soon
  4. Missing owner for pickup/deadline
  5. Required item for today
  6. Standard items (by received date, newest first)
- [ ] Card preview in list:
  - Source type icon (email, WhatsApp, voice, text, image, PDF)
  - Affected family member name + color indicator
  - Object type badge (Event, Task, Payment, Form, Change, Risk)
  - Operational summary (1 line)
  - Urgency marker (if due soon)
  - Confidence indicator (if low-confidence fields present)
  - Time since received
- [ ] Pull-to-refresh
- [ ] Empty state: "Nothing to review. All caught up." with subtle prompt to capture
- [ ] Badge count on Review tab (unreviewed item count)
- [ ] Grouped view option: group by source message (when one source produced multiple items)
- [ ] Bulk actions (v1 minimal): "Approve all" only when all items are high-confidence — warn if used

### 4.2 Review Card UI (6 Zones)

- [ ] **Zone 1: Source Indicator**
  - Icon + label for source type (Forwarded email, Shared WhatsApp, Voice note, Typed note, Screenshot, PDF)
  - Source app name if detected
  - Timestamp of original message

- [ ] **Zone 2: Operational Summary**
  - 1-2 sentence plain-language summary
  - Action-focused, not a recap ("Adam has a school trip Friday. He needs packed lunch and signed form." not "An email was received about a trip.")
  - Affected family member highlighted with their color

- [ ] **Zone 3: Extracted Fields**
  - Structured field display per object type:
    - Event: title, member, date, time, location, required items, owner
    - Task: title, member, due date, owner, related event
    - Deadline: title, due date/time, owner, urgency
    - Form: title, action, due date, submission method, owner
    - Payment: title, amount + currency, due date, method, owner
    - Checklist: title, items list, member, related event
    - Required items: item names, quantities, needed by, category
  - Each field shows confidence label: Clear ✓, Check this ⚠, Missing ✗, Suggested 💡
  - Low-confidence fields are visually distinct (highlighted, editable inline)

- [ ] **Zone 4: Uncertainty & Confidence**
  - Dedicated section if any fields have low confidence
  - Plain language: "Location may be Sports Hall", "Time unclear", "Child not detected"
  - Each uncertain field has inline edit affordance
  - Missing required fields prompted: "Owner is missing. Assign?"

- [ ] **Zone 5: Suggested Actions**
  - Nabbo's recommendations based on extraction:
    - "Add event to Friday"
    - "Create packing checklist"
    - "Set payment reminder"
    - "Assign pickup owner"
  - Each suggestion is tappable (quick-apply)
  - Fact/suggestion/inference labeling visible

- [ ] **Zone 6: Source Preview**
  - Collapsed by default (first 3 lines or thumbnail)
  - Expandable to full source view
  - For emails: sender, subject, date, body excerpt, attachment indicators
  - For images: image preview + OCR text
  - For voice: transcript text + audio playback button
  - For text: full original text
  - "View full source" link → dedicated source view screen

### 4.3 Review Actions Implementation

#### Approve
- [ ] Single tap "Approve" → commit extracted item to household plan
- [ ] Approval Cloud Function:
  1. Read ExtractedItem and its detected objects
  2. Create committed objects in relevant collections:
     - Event → `events/` collection
     - Task → `tasks/` collection
     - Deadline → `deadlines/` collection
     - Required items → `requiredItems/` collection
     - Checklist → `checklists/` collection
     - Form → `forms/` collection
     - Payment → `payments/` collection
     - Location → `locations/` (if new)
  3. Create Owner records (if assigned)
  4. Create Reminder records (if suggested)
  5. Run risk detection on newly committed objects
  6. Update ExtractedItem: reviewStatus → "approved"
  7. Create DecisionStatus record
  8. Return confirmation payload
- [ ] Approval confirmation UI:
  - "Added to Friday. Checklist created. Owner still missing."
  - Show remaining issues (owner gaps, uncertain fields left as-is)
  - Quick-assign owner from confirmation if gap exists
- [ ] "Approve all" for multi-item source (only when all items are high-confidence)

#### Edit
- [ ] Inline field editing — tap any field to edit
- [ ] Editable fields:
  - Family member (dropdown of household members)
  - Event title (text)
  - Date (date picker)
  - Time (time picker)
  - Location (text + location search)
  - Owner (dropdown of household members + "unassigned")
  - Due date (date picker)
  - Required items (add/remove list)
  - Payment amount (number + currency selector)
  - Payment method (text)
  - Form action (dropdown of FormAction enum)
  - Checklist items (add/remove/reorder)
  - Reminder time (time picker)
- [ ] Edit should NOT feel like a full form — only show the field being edited
- [ ] Save edit → update ExtractedItem fields → re-evaluate risks
- [ ] Track edited fields in DecisionStatus.editedFields[]

#### Dismiss
- [ ] Tap dismiss → show reason picker:
  - Not relevant
  - Duplicate
  - Already handled
  - Wrong extraction
  - No action needed
  - Spam / noise
- [ ] Optional: add note
- [ ] Update ExtractedItem: reviewStatus → "dismissed"
- [ ] Create DecisionStatus with reason
- [ ] Remove from Review Inbox
- [ ] Recoverable for 7 days (accessible from settings > recent activity)
- [ ] "Undo" snackbar shown for 5 seconds after dismiss

#### Snooze
- [ ] Tap snooze → show time picker:
  - Later today (configurable, default: 4 hours)
  - Tomorrow morning (configurable, default: 08:00)
  - This weekend (Saturday morning)
  - Next week (Monday morning)
  - Custom date/time picker
- [ ] Update ExtractedItem: reviewStatus → "snoozed", snoozeUntil → selected time
- [ ] Create DecisionStatus with snooze date
- [ ] Remove from active Review Inbox
- [ ] Cloud Task scheduled to return item at snooze time
- [ ] When snooze expires: reviewStatus → "pendingReview" again, notification sent
- [ ] Snoozed items visible in a "Snoozed" filter in Review Inbox

#### Assign Owner
- [ ] Tap "Assign" → show member picker
- [ ] Member list: all household members with role labels
- [ ] Assign → create/update Owner record
- [ ] If assigning before approval: field is updated on ExtractedItem for when approval commits
- [ ] If assigning after approval: Owner record updated on committed object
- [ ] Owner gap risk auto-resolves when assigned

#### Mark Handled
- [ ] For items that are real but already done
- [ ] Examples: "Payment already made", "Form already returned", "Item already packed"
- [ ] Update reviewStatus → "alreadyHandled"
- [ ] Create Completion record (method: "manually marked")
- [ ] Do NOT create committed objects (already done externally)
- [ ] Remove from Review Inbox

#### Split
- [ ] Available when one ExtractedItem contains multiple action types
- [ ] UI: show list of detected objects within the item
- [ ] User selects which objects to split into separate cards
- [ ] Creates new ExtractedItem records for split objects
- [ ] Original item's detectedObjects reduced to remaining
- [ ] Each new card is independently reviewable
- [ ] Example: School trip email → split into: Event card, Payment card, Form card, Checklist card

#### Merge
- [ ] Available when change detection finds a match with existing object
- [ ] UI shows: "This may update Adam's football training"
  - Previous values
  - New values
  - Impact description
- [ ] Actions:
  - "Confirm change" → update existing committed object with new values, create Change record
  - "Keep original" → dismiss the new extraction, keep existing object unchanged
  - "Create separate" → approve as a new standalone object
  - "Dismiss" → discard entirely
- [ ] Change confirmation updates:
  - Committed object fields
  - Change history on the object
  - Today view (real-time)
  - Risks re-evaluated

### 4.4 Special Card Types

#### Change Review Card
- [ ] Distinct visual treatment (different from standard review card)
- [ ] Shows clearly:
  - What changed (field name)
  - Previous value (struck through or labeled "was")
  - New value (highlighted)
  - Source of new information
  - Impact statement ("Departure time and checklist may need updating")
- [ ] Primary actions: Confirm change / Keep original / Create separate / Dismiss
- [ ] If confirmed: existing objects updated, Today refreshed, related reminders adjusted

#### Risk Review Card
- [ ] Calm, neutral tone (no panic language)
- [ ] Shows:
  - Risk title
  - Why it matters (context)
  - Affected person
  - Related object(s)
  - Suggested action
  - Severity indicator
- [ ] Primary actions: Resolve (assign/complete) / Snooze / Dismiss
- [ ] Resolve flow depends on risk type:
  - No owner → assign owner picker
  - Item not packed → mark as packed
  - Payment unpaid → mark as paid
  - Form incomplete → mark as submitted
  - Deadline near → set reminder

### 4.5 Source View Screen

- [ ] Full original source message display
- [ ] Metadata: input method, source app, received date, processing time
- [ ] For email: full sender, subject, date, body, attachments (downloadable)
- [ ] For image: full image view with pinch-to-zoom + OCR text below
- [ ] For voice: audio player + full transcript
- [ ] For text: original text
- [ ] For PDF: PDF viewer or extracted text
- [ ] Linked extracted items listed at bottom
- [ ] Delete source option (with confirmation — permanent)

### 4.6 Review Filters & Search

- [ ] Filter by:
  - Object type (events, tasks, payments, forms, changes, risks)
  - Affected family member
  - Urgency (due today, due tomorrow, due this week)
  - Confidence (low-confidence items only)
  - Status (pending, snoozed, dismissed — last 7 days)
- [ ] Sort by: urgency (default), newest first, oldest first
- [ ] Count indicators per filter

### Phase 4 Deliverable

Complete Review Inbox with prioritized cards. Full Review Card UI with 6 zones. All actions working: approve, edit, dismiss, snooze, assign, mark handled, split, merge. Change and Risk review cards with specialized UI. Source traceability. Approval creates committed objects in Firestore and triggers risk re-evaluation.

---

## Phase 5 — Today Command Center

**Goal:** Parent sees a clear daily execution view that answers "what needs to happen today?" across all committed objects.

**Duration:** 3–4 weeks

---

### 5.1 Today Data Aggregation

- [ ] Today provider (Riverpod): aggregates all household objects for current date
- [ ] Data sources:
  - Events where date == today (from `events/` collection)
  - Tasks where dueDate == today or overdue (from `tasks/`)
  - Deadlines where dueDate == today or overdue (from `deadlines/`)
  - Required items where neededBy == today (from `requiredItems/`)
  - Checklists linked to today's events (from `checklists/`)
  - Forms due today/tomorrow (from `forms/`)
  - Payments due today/tomorrow (from `payments/`)
  - Open risks (from `risks/` where status == open)
  - Unconfirmed changes (from `changes/` where reviewStatus != confirmed)
  - Owner gaps (objects due today/tomorrow with no owner)
- [ ] Real-time Firestore listeners on all relevant collections
- [ ] Offline persistence (Today view works without network using Firestore cache)
- [ ] Refresh on app resume (background → foreground)

### 5.2 Zone 1: Today Status

- [ ] Dynamic summary generated from object counts + risk assessment
- [ ] Status labels: Clear, Normal, Busy, Needs attention, At risk
- [ ] Logic:
  - Clear: 0-1 events, no risks, no owner gaps, no overdue items
  - Normal: 2-3 events, no high risks
  - Busy: 4+ events, or multiple deadlines/checklists
  - Needs attention: 1+ high-priority risk or owner gap
  - At risk: multiple risks, conflicting events, or critical deadlines
- [ ] Summary text examples:
  - "Light day. 2 events, no risks."
  - "Busy day. 5 events, 2 deadlines, 1 missing owner."
  - "Needs attention. Pickup conflict at 17:00."
- [ ] Tap → scroll to most relevant section

### 5.3 Zone 2: Next Action

- [ ] Algorithm: select highest-priority actionable item
- [ ] Priority hierarchy:
  1. Time/location change needing confirmation (today)
  2. Pickup/drop-off owner missing (next 4 hours)
  3. Departure needed (leave time approaching)
  4. Required item not packed (event within 2 hours)
  5. Deadline due today (form/payment/task)
  6. Task due today with no owner
  7. Risk needing resolution
- [ ] Display: single card with action statement + primary button
- [ ] Action buttons context-dependent:
  - "Assign pickup owner" → member picker
  - "Pack items" → open checklist
  - "Confirm change" → change card
  - "Pay €8" → mark as paid
  - "Sign form" → mark as submitted
  - "Leave by 18:00" → mark as done / set departure reminder
- [ ] Auto-advances when current action is resolved
- [ ] "All done for now" state when no pending actions

### 5.4 Zone 3: Departure & Movement

- [ ] List of events requiring physical movement today
- [ ] Each item shows:
  - Event title
  - Family member (with color)
  - Location name
  - Start time
  - Suggested departure time (start time - defaultTravelTime, or "Travel time not set")
  - Pickup/drop-off owner (name or "Owner missing ⚠")
  - Required items count ("3 items to pack")
  - Travel risk indicator (if departure time is tight or location changed)
- [ ] Sorted by departure time (earliest first)
- [ ] Tap → expand to show required items, full location, owner details
- [ ] Action: assign owner, view checklist, set departure reminder
- [ ] Faded/collapsed after event start time passes

### 5.5 Zone 4: Today Timeline

- [ ] Vertical chronological list of today's events
- [ ] Each event shows: time, title, family member, location, owner, status indicators
- [ ] Visual states:
  - Past events: faded/collapsed
  - Current event: highlighted/prominent
  - Next upcoming: slightly emphasized
  - Future events: normal
- [ ] Status indicators per event:
  - ✓ All items packed / owner assigned / ready
  - ⚠ Items missing / owner gap / change unconfirmed
- [ ] Tap event → expand detail: full info, checklist, tasks, owner, source link
- [ ] Quick actions from expanded: mark done, assign owner, open checklist

### 5.6 Zone 5: Checklist

- [ ] Aggregate all required items due today, grouped by:
  - Family member → Event/activity
- [ ] Display format:
  ```
  Adam — Football Training:
  ☐ Water
  ☐ Blue jersey
  ☐ Size 4 ball
  ☐ Football boots

  Yara — School Trip:
  ☐ Packed lunch
  ☐ Raincoat
  ☐ Signed form
  ```
- [ ] Item states (visual): Not ready (empty checkbox), Ready (checked), Not needed (struck), Already handled (dimmed check), Owner missing (⚠)
- [ ] Quick-mark: tap to toggle ready/not ready
- [ ] Swipe actions: mark not needed, assign owner
- [ ] "All packed" summary when all items in a group are ready
- [ ] Owner display per item or per group
- [ ] Link to source (why this item is needed)

### 5.7 Zone 6: Risks & Changes

- [ ] Split into two subsections: Changes and Risks

#### Changes section
- [ ] Show unconfirmed changes affecting today/tomorrow
- [ ] Each change shows: what changed, previous → new value, affected event/task
- [ ] Actions: confirm change, keep original, view source
- [ ] Auto-dismiss changes older than 7 days unconfirmed

#### Risks section
- [ ] Show open risks affecting today/tomorrow
- [ ] Each risk shows: title, why it matters, severity, suggested action
- [ ] Risk types shown:
  - Owner missing for upcoming event
  - Deadline due today/overdue
  - Unpaid payment due today
  - Form incomplete and due today
  - Required item not ready for upcoming event
  - Conflicting events
  - Location/time changed and unconfirmed
- [ ] Actions per risk: resolve (context-dependent), assign, snooze, dismiss
- [ ] Severity color coding: critical (red), high (orange), medium (yellow)
- [ ] Limit display: max 5 risks visible, "View all" link if more

### 5.8 Zone 7: Evening Reset

- [ ] Appears more prominently after 17:00 (or configurable time)
- [ ] Shows preparation needed for tomorrow:
  - Tomorrow's first event (title, time, items needed)
  - Items to pack tonight
  - Forms due tomorrow
  - Payments due tomorrow
  - Early departures requiring advance prep
  - Owner gaps for tomorrow
- [ ] Each item actionable: mark packed, assign owner, set reminder, mark done
- [ ] Summary: "Tomorrow starts with swimming. Pack towel, goggles, shampoo, and snack tonight."
- [ ] Collapsed during morning/daytime, expanded in evening

### 5.9 Daily View Mode Adaptation

- [ ] Time-based priority shifting:
  - **Morning (06:00–09:00):** Emphasize school readiness, bags, lunch, forms, departure times, drop-offs
  - **Daytime (09:00–15:00):** Emphasize deadlines, payments, appointments, after-school prep
  - **After-school (15:00–18:00):** Emphasize activity logistics, transport, snacks, sports gear, pickup owners
  - **Evening (18:00–22:00):** Emphasize tomorrow prep, packing, forms, payment deadlines, unresolved risks
  - **Weekend:** Different priority (activities, travel, family plans, irregular schedules)
- [ ] Same 7 zones, different sort/emphasis within each zone
- [ ] User can override time mode manually (e.g., view evening reset early)

### 5.10 Today Item Actions

- [ ] Mark done / packed / paid / submitted / handled:
  - Creates Completion record
  - Updates object status
  - Related risks auto-resolve
  - Visual: item collapses with ✓
- [ ] Assign owner:
  - Member picker
  - Creates/updates Owner record
  - Owner gap risk resolves
- [ ] View source:
  - Navigate to Source View screen
  - Links back to original capture
- [ ] Edit:
  - Inline field editing (same as Review Card edit)
  - Time, date, location, items, owner
- [ ] Dismiss risk:
  - Remove risk from view
  - Optional reason
  - Does not dismiss the underlying object
- [ ] Open checklist:
  - Navigate to full checklist view
  - All items with pack/mark actions
- [ ] Confirm change:
  - Shows change card inline or modal
  - Confirm → update object, dismiss change
- [ ] Set reminder:
  - Quick reminder time picker
  - Creates Reminder record
  - Notification scheduled via Cloud Tasks

### 5.11 Manual Add from Today

- [ ] "Add" FAB or button in Today view
- [ ] Quick add options:
  - Free text (same as capture) → goes through extraction → review → commit
  - Quick task (title + due date + optional owner — bypasses AI for simple items)
  - Quick reminder (title + time)
  - Quick required item (item name + event link + needed by)
- [ ] Quick add creates objects directly (no AI extraction needed for structured manual input)
- [ ] Free text goes through normal pipeline (capture → extract → review)

### 5.12 Today Empty & Edge States

- [ ] Empty state: "Today is clear. Nothing needs attention." + subtle capture prompt
- [ ] Weekend state: adjusted messaging and priority (less urgent, more planning)
- [ ] All-done state: "All tasks complete. Enjoy the rest of the day."
- [ ] Heavy day state: surface most important 3 items prominently, collapse the rest
- [ ] Tomorrow preview: always show a brief "tomorrow starts with..." at bottom

### 5.13 Today Offline Support

- [ ] Firestore offline persistence ensures Today loads from cache
- [ ] Mark-as-done works offline (syncs when reconnected)
- [ ] Checklist toggles work offline
- [ ] Visual indicator when offline ("Last updated X minutes ago")
- [ ] No extraction or AI features available offline (capture queued)

### Phase 5 Deliverable

Full Today Command Center with 7 zones. Dynamic status summary, next action selection, departure tracking, chronological timeline, grouped checklists, risk/change display, and evening reset. All item actions work (mark done, assign, edit, dismiss, view source). Adapts by time of day. Works offline.

---

## Phase 6 — Notifications & Proactive Alerts

**Goal:** Nabbo proactively brings the parent back at the right time with actionable, grouped, well-timed notifications.

**Duration:** 2–3 weeks

---

### 6.1 FCM Infrastructure

- [ ] Device token registration on login and app launch
- [ ] Token refresh handling (update Firestore when token changes)
- [ ] Topic subscription per household (`household_{householdId}`)
- [ ] Background message handler (flutter_local_notifications for foreground)
- [ ] Notification permission request flow (iOS requires explicit opt-in)
- [ ] Notification channel setup (Android): separate channels for review, changes, deadlines, prep, briefs
- [ ] Badge count management (unreviewed items + unresolved risks)

### 6.2 Notification Types Implementation

#### Review Needed
- [ ] Trigger: new ExtractedItem created with reviewRequired == true
- [ ] Conditions for sending:
  - Item has deadline today/tomorrow
  - Item contains change detection
  - Item has form/payment/pickup/required items
  - Item has low-confidence fields needing review
- [ ] Suppress when:
  - Item is low priority and not time-sensitive
  - No clear action found
  - Duplicate detected
- [ ] Content: "{Object type} found. Review needed." or "School trip found. Review needed."
- [ ] Deep-link: opens specific Review Card

#### Change Detected
- [ ] Trigger: Change object created during extraction
- [ ] Content format: "{What} changed: {previous} → {new}"
  - "Training time changed: 17:00 → 18:30"
  - "Football location changed to Sports Hall"
  - "School trip cancelled"
- [ ] Deep-link: opens Change Review Card
- [ ] Priority: high (send immediately for today/tomorrow changes)

#### Deadline Risk
- [ ] Trigger: Cloud Tasks scheduled check finds deadline within threshold
- [ ] Content: "{Title} due {when}. {Status}."
  - "Permission form due tomorrow. Owner missing."
  - "€8 payment due today. Still pending."
- [ ] Deep-link: opens deadline item in Today or Review Card
- [ ] Suppress if already completed/paid/submitted

#### Owner Gap
- [ ] Trigger: event/task due within 24h with no assigned owner
- [ ] Content: "{Action} has no owner."
  - "Pickup at 18:30 has no owner."
  - "Form submission has no owner."
- [ ] Tone: neutral, no blame
- [ ] Deep-link: opens assignment action
- [ ] Suppress if owner assigned since detection

#### Preparation Needed
- [ ] Trigger: Cloud Tasks scheduled based on event time minus prep window
- [ ] Content: grouped items per event
  - "Swimming tomorrow: pack towel, goggles, and shampoo."
  - "Football in 2 hours: 3 items to pack."
- [ ] Group related items (never send one notification per item)
- [ ] Deep-link: opens checklist
- [ ] Suppress if all items already marked ready

#### Daily Brief
- [ ] Trigger: Cloud Tasks scheduled at user-configured morning time (default: 07:30)
- [ ] Content: "Today: {X} events, {Y} tasks, {Z} items to pack. {risk summary if any}."
- [ ] Deep-link: opens Today Command Center
- [ ] Optional (user enables in settings)
- [ ] Only send if there's actual content (don't send "nothing today")

### 6.3 Cloud Tasks Scheduling

- [ ] **Morning brief:** daily at user-configured time
- [ ] **Evening reset:** daily at user-configured time (default: 20:00) — summary of tomorrow
- [ ] **Deadline checks:** every 15 minutes — scan for approaching deadlines
- [ ] **Preparation reminders:** scheduled per event (event time - configurable prep window, default: 2 hours before, evening before)
- [ ] **Snooze returns:** scheduled per snoozed item at snooze expiry time
- [ ] **Owner gap alerts:** 24h before event if owner still missing
- [ ] **Escalation:** repeat alert 2h before event if still no owner (conservative)

### 6.4 Notification Logic (Cloud Functions)

- [ ] Priority evaluation:
  - High: changes for today, deadline due today, pickup owner missing for next event
  - Medium: deadline tomorrow, preparation needed, new review items
  - Low: future items, routine suggestions (suppressed from push, only in-app)
- [ ] Grouping logic:
  - Group by event: combine items/risks/owners for same event into one notification
  - Group by child: combine items across events for same child
  - Group by time window: don't send 5 notifications within 10 minutes
  - Maximum: 3 push notifications per hour per household
- [ ] Suppression logic:
  - Item already completed/paid/submitted/packed → suppress
  - Item dismissed → suppress
  - Item snoozed → suppress until snooze expires
  - User already opened and acted on item → suppress
  - Notification for same object sent within last 4 hours → suppress (unless urgency increased)
- [ ] Deep-link payload:
  - Route path (e.g., `/review/{itemId}`, `/today`, `/today/checklist/{checklistId}`)
  - Object type and ID
  - Action context (what the user should do)

### 6.5 Notification Settings Screen

- [ ] Category toggles:
  - Review alerts (on/off)
  - Change alerts (on/off)
  - Deadline alerts (on/off)
  - Owner gap alerts (on/off)
  - Preparation reminders (on/off)
  - Morning brief (on/off + time picker)
  - Evening reset (on/off + time picker)
- [ ] Quiet hours:
  - Enable/disable
  - Start time (default: 22:00)
  - End time (default: 07:00)
  - Allow critical alerts during quiet hours (toggle)
- [ ] Preview: "Based on your settings, you'll receive approximately X notifications per day."

### 6.6 Quiet Hours Enforcement

- [ ] Cloud Functions check quiet hours before sending
- [ ] During quiet hours, only allow:
  - Tomorrow morning event has no owner (if "allow critical" is on)
  - Required item for early morning event
  - Critical deadline before next notification window
- [ ] Queue non-critical notifications for after quiet hours end
- [ ] Never disturb between quiet start and quiet end unless explicitly allowed

### 6.7 Notification Deep-Linking

- [ ] Handle notification tap in Flutter:
  - Parse deep-link payload
  - Navigate to correct screen with correct object loaded
  - Handle app cold-start from notification (initial route override)
  - Handle app background-resume from notification
- [ ] Test matrix:
  - App in foreground → in-app banner, tap opens screen
  - App in background → system notification, tap resumes + navigates
  - App killed → system notification, tap cold-starts + navigates
- [ ] Analytics: track notification → open → action conversion

### Phase 6 Deliverable

Full notification system working. 6 notification types with proper content, grouping, suppression, and deep-linking. Cloud Tasks scheduling for briefs, deadline checks, prep reminders, and snooze returns. User-configurable settings with quiet hours. Notifications lead directly to relevant action screens.

---

## Phase 7 — Owner & Responsibility System

**Goal:** Every action has a clear owner or is visibly marked unassigned. Ownership creates execution clarity.

**Duration:** 1–2 weeks

---

### 7.1 Owner Assignment Flow

- [ ] Member picker component (reusable):
  - Shows all household members with role labels and colors
  - Quick-select primary parent / second parent / specific child
  - "Unassigned" option always available
  - Recent assignments shown (for quick repeat)
- [ ] Assignment contexts:
  - During review (before approval)
  - During approval (prompted if no owner)
  - From Today view (any item with owner gap)
  - From risk card (owner gap risk → direct assign)
  - From notification (deep-link to assign action)
- [ ] Owner record creation: links person → object → timestamp → assigner
- [ ] Ownership inheritance: if event has owner, related tasks inherit suggestion (not auto-assign)

### 7.2 Owner Visibility Across App

- [ ] Review Card: owner field shown; if missing → "Owner missing" with assign button
- [ ] Today timeline: each event/task shows owner name or ⚠ symbol
- [ ] Today departure: pickup/drop-off owner prominently shown
- [ ] Today checklist: packing owner per group
- [ ] Risks section: owner gap risks with one-tap assign
- [ ] Event detail: owner for event + owners for sub-tasks

### 7.3 Owner Gap Detection

- [ ] Real-time detection rules:
  - Event within 48h with no owner → create risk
  - Task due within 48h with no owner → create risk
  - Payment due within 48h with no owner → create risk
  - Pickup/drop-off for event today with no owner → critical risk
  - Form due within 48h with no owner → create risk
- [ ] Auto-resolve when owner assigned
- [ ] Severity escalation: medium (48h) → high (24h) → critical (same-day, pickup/drop-off)
- [ ] Notification trigger: owner gap alert for high/critical severity

### 7.4 Owner States & Completion

- [ ] Owner states (v1): Assigned, Unassigned, Completed
- [ ] Completion flow: owner marks their assigned action as done
- [ ] Completion record: who completed, when, method, optional note
- [ ] Visibility: completed items show ✓ with completor name
- [ ] Historical: who owned what in the past (for patterns, future routine learning)

---

## Phase 8 — Polish, Testing & Production Readiness

**Goal:** App is stable, performant, polished, and ready for real family testing.

**Duration:** 2–3 weeks

---

### 8.1 UI/UX Polish

- [ ] Design system finalization:
  - Color palette (family member colors, status colors, urgency colors)
  - Typography scale (Nunito Sans hierarchy)
  - Spacing system (consistent padding/margins)
  - Icon set (source types, object types, actions, status)
  - Component library (buttons, cards, badges, chips, inputs)
- [ ] Animations:
  - Checklist item check animation (satisfying, not gamified)
  - Card approval animation (brief confirmation)
  - Processing spinner/skeleton states
  - Page transitions
  - Pull-to-refresh feedback
- [ ] Responsive considerations:
  - Large phones / small phones
  - Landscape (supported but not optimized)
  - Dynamic text sizing (accessibility)
  - Safe area handling (notch, home indicator)
- [ ] Dark mode preparation (structure for future, not required v1)
- [ ] Haptic feedback for key actions (approve, mark done, assign)

### 8.2 Error Handling & Edge Cases

- [ ] Network connectivity handling:
  - Offline indicator in app bar
  - Queued actions sync on reconnect
  - Today view from cache
  - Capture queued when offline, processed when online
- [ ] Empty states for all screens (Review, Today, Checklists, each zone)
- [ ] Error states for all operations:
  - Extraction failure → retry + manual add
  - Approval failure → retry with error message
  - Network failure → queued action indicator
  - Auth session expired → re-login prompt
- [ ] Edge cases:
  - User captures 50 items at once (queue/batch handling)
  - Same email forwarded twice (dedup detection)
  - Voice recording too short / too long
  - Image with no extractable text
  - Member deleted while assigned to objects (reassign prompt)
  - All items for today completed (celebration-free "all done" state)
  - Very long source messages (truncation with "view full")

### 8.3 Performance Optimization

- [ ] Firestore query optimization:
  - Composite indexes for Today queries (householdId + date + status)
  - Pagination for Review Inbox (limit 20, load more)
  - Efficient listeners (query-scoped, not collection-wide)
- [ ] Image/attachment optimization:
  - Thumbnail generation for image previews
  - Lazy loading for source view images
  - Download size limits
- [ ] App startup performance:
  - Minimize initial data load (Today essentials only)
  - Background prefetch for Review count
  - Splash screen while Firebase initializes
- [ ] Memory management:
  - Dispose listeners on screen exit
  - Image cache limits
  - Stream controller cleanup

### 8.4 Security & Privacy

- [ ] Firestore security rules (comprehensive):
  - Users can only read/write their own household data
  - No cross-household queries possible
  - Validate data structure on write
  - Rate limiting on writes
- [ ] Cloud Storage security rules:
  - Only household members can read their source files
  - Upload size limits enforced
  - Content type validation
- [ ] Cloud Functions security:
  - Authenticated calls only
  - Household ID validation on every function
  - Input sanitization
  - Vertex AI calls don't include PII in logs
- [ ] Data deletion:
  - User can delete individual source messages + all linked objects
  - User can delete entire account + all household data
  - Cascading deletes (source → extracted items → committed objects)
  - Confirmation UI with clear explanation of what will be deleted
- [ ] Privacy features:
  - Clear explanation that shared/forwarded content is processed
  - No data used for model training (Vertex AI data governance)
  - No manual human review without disclosure
  - GDPR-ready: export user data capability (future)

### 8.5 Localization

- [ ] ARB file setup (app_en.arb, app_nl.arb, app_ar.arb minimum)
- [ ] All user-facing strings externalized
- [ ] RTL support for Arabic (layout mirroring)
- [ ] Date/time formatting per locale
- [ ] Currency formatting per locale
- [ ] Extraction language detection + multi-language prompt handling

### 8.6 Testing Strategy

- [ ] Unit tests:
  - All data models (serialization/deserialization)
  - Repository methods (mock Firestore)
  - Business logic (risk detection, priority sorting, status transitions)
  - Providers (state management)
- [ ] Widget tests:
  - Review Card rendering (all 6 zones)
  - Today Command Center (all 7 zones)
  - Onboarding flow
  - Action behaviors (approve, dismiss, snooze)
- [ ] Integration tests:
  - Full capture → extract → review → approve → Today flow
  - Change detection end-to-end
  - Notification delivery end-to-end
  - Share extension → main app data flow
- [ ] AI extraction testing:
  - 50+ test cases across all input types
  - Multi-language test cases
  - Edge cases (empty, gibberish, non-family content, very long)
  - Accuracy scoring per field type
  - Regression suite (run before any prompt changes)

### 8.7 App Store Preparation

- [ ] App icons (iOS + Android, all sizes)
- [ ] Splash screen
- [ ] App Store screenshots (Review Card, Today view, capture flow)
- [ ] App Store description and metadata
- [ ] Privacy policy
- [ ] Terms of service
- [ ] TestFlight / Firebase App Distribution setup for beta testing
- [ ] Analytics events setup (capture, review, approve, today open, notification action)

### Phase 8 Deliverable

Production-ready app with polished UI, comprehensive error handling, offline support, security rules, localization, testing coverage, and app store assets. Ready for closed beta testing with real families.

---

## Cloud Functions Summary

All backend logic runs as Firebase Cloud Functions (Node.js/TypeScript) or Cloud Run services.

### Event-Driven Functions

| Function | Trigger | Purpose |
|----------|---------|---------|
| `onSourceMessageCreated` | Firestore create on `sourceMessages/` | Route to appropriate pre-processor (voice → STT, image → OCR, text → extraction) |
| `onSourceMessageReadyForExtraction` | Firestore update (status: extracting) | Call Gemini, create ExtractedItems, detect changes, detect risks |
| `onExtractedItemApproved` | Firestore update (reviewStatus: approved) | Create committed objects, run risk detection, schedule reminders |
| `onObjectOwnerAssigned` | Firestore create/update on `owners/` | Resolve owner gap risks, update related objects |
| `onObjectCompleted` | Firestore update (status: completed) | Create Completion record, resolve related risks, suppress notifications |
| `onChangeConfirmed` | Firestore update on `changes/` | Update target object, recalculate risks, adjust reminders |

### Scheduled Functions

| Function | Schedule | Purpose |
|----------|----------|---------|
| `deadlineCheck` | Every 15 minutes | Find approaching/overdue deadlines, generate risks, trigger notifications |
| `morningBrief` | Per-household configured time | Generate and send daily brief notification |
| `eveningReset` | Per-household configured time | Generate tomorrow preview notification |
| `prepReminder` | Dynamic per event | Send preparation reminder (event time - prep window) |
| `snoozeReturn` | Per-item | Return snoozed item to review inbox |
| `ownerGapEscalation` | Hourly | Escalate unresolved owner gaps nearing deadline |
| `riskCleanup` | Daily | Auto-resolve risks for past events, dismiss stale risks |

### Cloud Run Services

| Service | Purpose |
|---------|---------|
| `email-ingestion` | Receive inbound emails, parse, store as SourceMessage |

---

## Firestore Indexes Required

| Collection | Fields | Purpose |
|------------|--------|---------|
| `sourceMessages` | householdId + processingStatus + receivedAt | Fetch pending/recent messages |
| `extractedItems` | householdId + reviewStatus + createdAt | Review inbox query |
| `extractedItems` | householdId + reviewStatus + urgency | Priority sorting |
| `events` | householdId + startDateTime | Today's events |
| `tasks` | householdId + dueDate + status | Tasks due today |
| `deadlines` | householdId + dueDateTime + status | Deadline checks |
| `requiredItems` | householdId + neededByDateTime + packedStatus | Checklist today |
| `risks` | householdId + status + severity | Open risks |
| `changes` | householdId + reviewStatus | Pending changes |
| `reminders` | householdId + reminderTime + status | Scheduled reminders |

---

## Project Structure (Final)

```
nabbo/
├── app/                          # Flutter mobile app
│   ├── lib/
│   │   ├── core/
│   │   │   ├── constants/        # App-wide constants, enums
│   │   │   ├── extensions/       # Dart extensions
│   │   │   ├── l10n/             # Localization
│   │   │   ├── routing/          # Go Router config + guards
│   │   │   ├── theme/            # Colors, typography, theme data
│   │   │   ├── utils/            # Helpers, formatters, validators
│   │   │   └── widgets/          # Shared widgets (app shell, buttons, cards)
│   │   ├── features/
│   │   │   ├── auth/             # Login, registration, auth state
│   │   │   ├── onboarding/       # 7-screen onboarding flow
│   │   │   ├── capture/          # Free text, voice, share extension bridge
│   │   │   ├── review/           # Review Inbox, Review Cards, actions
│   │   │   ├── today/            # Today Command Center (7 zones)
│   │   │   ├── household/        # Family members, household settings
│   │   │   └── settings/         # Notifications, privacy, account
│   │   └── main.dart
│   ├── ios/                      # iOS native (share extension)
│   ├── android/                  # Android native (share target)
│   └── pubspec.yaml
├── functions/                    # Firebase Cloud Functions (TypeScript)
│   ├── src/
│   │   ├── extraction/           # AI extraction pipeline
│   │   ├── processing/           # Pre-processors (OCR, STT, email parse)
│   │   ├── approval/             # Object commitment logic
│   │   ├── detection/            # Change detection, risk detection
│   │   ├── notifications/        # Notification generation + delivery
│   │   ├── scheduled/            # Scheduled tasks (briefs, checks)
│   │   └── utils/                # Shared helpers
│   └── package.json
├── services/                     # Cloud Run services
│   └── email-ingestion/          # Inbound email handler
├── docs/                         # Product & technical documentation
├── firestore.rules               # Security rules
├── storage.rules                 # Storage security rules
└── firebase.json                 # Firebase project config
```

---

## Timeline Estimate (Revised)

| Phase | Scope | Duration | Cumulative |
|-------|-------|----------|------------|
| Phase 1 | Foundation & Data Layer | 2–3 weeks | 2–3 weeks |
| Phase 2 | Capture Layer | 3–4 weeks | 5–7 weeks |
| Phase 3 | AI Extraction Engine | 3–4 weeks | 8–11 weeks |
| Phase 4 | Review Inbox & Cards | 3–4 weeks | 11–15 weeks |
| Phase 5 | Today Command Center | 3–4 weeks | 14–19 weeks |
| Phase 6 | Notifications & Alerts | 2–3 weeks | 16–22 weeks |
| Phase 7 | Owner & Responsibility | 1–2 weeks | 17–24 weeks |
| Phase 8 | Polish & Production | 2–3 weeks | 19–27 weeks |
| **Total** | **v1 complete** | **19–27 weeks** | |

These estimates assume one developer working full-time. With parallel frontend (Flutter) and backend (Cloud Functions / Cloud Run) work, timeline compresses to **14–20 weeks**.

### Milestone Checkpoints

| Milestone | Phase | What's Testable |
|-----------|-------|-----------------|
| **M1: Core Shell** | End of Phase 1 | Sign up, onboarding, household setup, navigation |
| **M2: Capture Working** | End of Phase 2 | All 4 input methods create Source Messages |
| **M3: AI Processing** | End of Phase 3 | Captured content → structured Extracted Items |
| **M4: Core Loop** | End of Phase 4 | Full capture → extract → review → approve loop |
| **M5: Daily Value** | End of Phase 5 | Today Command Center shows approved items + risks |
| **M6: Proactive** | End of Phase 6 | Notifications bring user back at right time |
| **M7: Ownership** | End of Phase 7 | Every action has visible owner or unassigned marker |
| **M8: Beta Ready** | End of Phase 8 | Ready for real family testing |

---

## Dependencies & Prerequisites

### Before Development Starts
- [ ] Firebase project created (iOS + Android apps registered)
- [ ] Google Cloud billing account linked
- [ ] Vertex AI API enabled (Gemini 1.5 Pro access)
- [ ] Domain registered (`nabbo.app`) and DNS configured
- [ ] Apple Developer account (for iOS share extension + TestFlight)
- [ ] Google Play developer account (for Android testing)

### Phase 2 Prerequisites
- [ ] Custom domain email receiving configured (SendGrid/Mailgun/Postmark)
- [ ] Cloud Run service deployed for email ingestion
- [ ] Speech-to-Text API enabled
- [ ] Vision AI / Document AI APIs enabled
- [ ] Cloud Storage buckets created

### Phase 3 Prerequisites
- [ ] Vertex AI endpoint configured
- [ ] Extraction prompt finalized and tested against 50+ test cases
- [ ] Cloud Functions deployment pipeline working

### Phase 6 Prerequisites
- [ ] APNs certificate (iOS push notifications)
- [ ] FCM configuration complete
- [ ] Cloud Tasks API enabled
- [ ] Notification scheduling infrastructure deployed

---

## Open Technical Decisions

| # | Decision | Options | Recommendation |
|---|----------|---------|----------------|
| 1 | Email ingestion provider | SendGrid Inbound Parse / Mailgun / Cloud Functions email trigger | SendGrid (most reliable parsing, good attachment handling) |
| 2 | Vertex AI region | us-central1 / europe-west4 | europe-west4 (if primary users are EU-based) |
| 3 | Extraction model | Gemini 1.5 Pro / Gemini 1.5 Flash | Pro for accuracy; consider Flash for simple inputs to reduce cost |
| 4 | Share extension approach | Native (Swift/Kotlin) + App Groups / Flutter plugin | Native + App Groups (most reliable on iOS) |
| 5 | Offline strategy | Today-only offline / Full offline queue | Today + capture queue offline (review requires network) |
| 6 | Notification provider | FCM only / FCM + local notifications | FCM + flutter_local_notifications (foreground display) |
| 7 | CI/CD | GitHub Actions / Codemagic / Fastlane | Codemagic (Flutter-optimized, handles iOS signing) |
| 8 | Monitoring | Firebase Crashlytics + Performance / Sentry | Crashlytics + Performance (same ecosystem, free tier) |
| 9 | Analytics | Firebase Analytics / Mixpanel / Amplitude | Firebase Analytics v1, Mixpanel later for deeper funnels |
| 10 | Voice recording | record package / custom native | record package (already in pubspec, good enough for v1) |

---

## Success Criteria (v1 Launch)

The product is ready for beta when:

- [ ] A parent can capture a school email in under 10 seconds
- [ ] AI correctly extracts the primary action 70%+ of the time
- [ ] Review → approve takes under 15 seconds for high-confidence items
- [ ] Today view loads in under 2 seconds (including from cold start)
- [ ] Notifications lead to action (not just opens) 40%+ of the time
- [ ] Change detection correctly identifies time/location changes 80%+ of the time
- [ ] Owner gaps are surfaced before the event happens
- [ ] The full loop (capture → review → today) works end-to-end without errors
- [ ] Offline Today view works with last-synced data
- [ ] Source traceability: every Today item links back to its original source

---

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| AI extraction quality too low | Start with simpler extractions (events + tasks), expand object types gradually; human-reviewed test suite before launch |
| Share extension unreliable on iOS | Extensive testing on multiple iOS versions; fallback to clipboard paste |
| Email ingestion spam | Rate limiting + basic sender validation; manual alias sharing (not publicly discoverable) |
| Firestore costs at scale | Query optimization, limit real-time listeners, pagination, archive old data |
| Notification fatigue | Conservative defaults, suppression logic, user controls; measure mute rate as health metric |
| Onboarding drop-off | Keep onboarding to 7 screens max, end with action not education, allow skip-and-return |
| Multi-language extraction quality | Test extraction in target languages early; language-specific prompt tuning |
| Scope creep | Strict v1 boundary (no calendar sync, no integrations, no multi-user auth, no chat) |

# Development Rules

## Source of Truth

The following documents are the source of truth for Nabbo's product and technical requirements:

- `docs/02-product-requirements.md` — Product Requirements (v1 scope)
- `docs/03-product-loop.md` — Core Product Loop
- `docs/04-data-model.md` — Core Data Model (20 objects)
- `docs/05-ai-extraction.md` — AI Extraction Specification
- `docs/06-app-flow.md` — App Flow & Screen Map
- `docs/07-review-card.md` — Review Card Spec
- `docs/08-feed.md` — Feed Spec
- `docs/09-notification-strategy.md` — Notification Strategy
- `docs/10-technical-architecture.md` — Technical Architecture
- `docs/11-implementation-plan.md` — Implementation Plan

## Rules

### 1. Follow Requirements Strictly

- Every code change MUST be traceable to a documented requirement.
- Do NOT implement features, behaviors, or flows that are not described in the requirements documents.
- Do NOT remove or alter existing functionality unless explicitly instructed and documented.

### 2. Conflict Resolution

- If the user provides instructions that CONTRADICT the requirements documents, I MUST:
  1. Inform the user of the contradiction
  2. Reference the specific document and section
  3. Wait for the user to confirm whether to update the requirements doc
  4. Only proceed after the requirements doc is updated
- The user and I work TOGETHER on updating requirements before implementing changes.

### 3. No Undocumented Changes

- Do NOT add dummy data
- Do NOT change navigation structure without updating docs
- Do NOT rename screens/tabs without updating docs
- Do NOT alter the product loop without updating docs
- Do NOT change the data model without updating docs

### 4. Git & Deployment

- Do NOT push to git unless the user explicitly asks
- Do NOT run the app (simulator/web/device) unless the user explicitly asks
- Commit messages should reference which requirement/phase the change implements

### 5. Code Quality

- Every change must compile without errors before presenting to user
- Do NOT introduce regressions — check existing functionality is preserved
- Use the design system (AppColors, AppSpacing, nabbo_widgets) consistently
- Follow the established architecture (Riverpod, Freezed, feature-first)

### 6. Current App State

The app currently has:
- Feed tab (was "Today") — shows source messages (pending/analyzing/needs review) + committed items (events/tasks/payments) grouped by date
- Review tab — shows pending extracted items
- Settings tab — household, family members, notifications, account
- Animated expandable FAB with text/voice/image capture
- AI extraction via Gemini 2.5 Flash Cloud Function
- Approval flow: extracted items → committed to events/tasks/payments/etc.
- Email forwarding via SendGrid → Cloud Run
- Push notifications on extraction + hourly deadline check

### 7. Known Gaps (documented but not yet built)

- Change detection (comparing new extractions against existing data)
- Risk detection (auto-generating risks from gaps)
- Full edit flow on Review Cards (inline field editing before approval)
- Source traceability (tap to see original message from feed item)
- Notification deep-linking
- Multi-language string translations
- iOS native share extension (currently using receive_sharing_intent plugin)

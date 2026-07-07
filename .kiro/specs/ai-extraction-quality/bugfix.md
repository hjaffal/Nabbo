# Bugfix Requirements Document

## Introduction

The `extractSourceMessage` Cloud Function uses Gemini 2.5 Flash to extract actionable items from family messages. While the function works end-to-end, its extraction quality diverges from the extraction schema spec (`docs/05-extraction-schema.md`) in several ways: incomplete field extraction, fragile date parsing, missing owner attribution, no endDate support, and a prompt that underspecifies the expected output format. These gaps reduce extraction accuracy and force parents into more manual correction during review.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN a source message contains a time component (e.g., "dentist at 4pm", "training at 18:30") THEN the system drops the time and stores only the date portion, because `parseDate` creates dates without preserving hours/minutes from the original string

1.2 WHEN a source message references an event with a clear end time or duration (e.g., "party from 2pm to 5pm") THEN the system always stores `endDate: null` because the prompt never asks Gemini to extract an end date and the function hardcodes it

1.3 WHEN a source message explicitly names who should perform an action (e.g., "Dad needs to pick up", "Mum must sign the form") THEN the system stores `ownerId: null` and `ownerName: null` because the prompt does not instruct extraction of the owner/responsible person and the function never matches owners to family members

1.4 WHEN Gemini returns a relative date like "next tuesday" with a time like "at 16:00" THEN the `parseDate` function only resolves the day-of-week and ignores the time portion, resulting in a midnight timestamp

1.5 WHEN the prompt instructs Gemini to return extracted data in a `fields` key THEN the resulting `extractedFields` map has inconsistent/unpredictable keys because the prompt provides no enumeration of expected field names

1.6 WHEN a source message contains recurrence information with an end condition (e.g., "every Tuesday until end of term") THEN the system cannot store the recurrence end date because the prompt schema omits the `endDate` field from the recurrence object

1.7 WHEN Gemini wraps the JSON response in markdown code fences with trailing whitespace or mixed formatting THEN `parseExtractionResponse` may fail to strip fences correctly, returning an empty array and marking the message as `noAction`

1.8 WHEN a source message contains multiple actionable items of different natures (e.g., a payment of €8 + a form to submit + items to pack) THEN the system extracts them all as generic "task" type because the prompt only allows event/task/deadline and provides no guidance on enriching the title or summary to distinguish sub-types

### Expected Behavior (Correct)

2.1 WHEN a source message contains a time component THEN the system SHALL parse and preserve both date and time in the stored Firestore Timestamp (e.g., "next Tuesday at 16:00" → Tuesday at 16:00, not midnight)

2.2 WHEN a source message references an event with a clear end time or duration THEN the system SHALL extract and store the `endDate` field as a Firestore Timestamp

2.3 WHEN a source message explicitly names who should perform an action and that person matches a family member THEN the system SHALL populate `ownerId` and `ownerName` with the matched family member's details

2.4 WHEN Gemini returns a combined relative date+time string THEN the `parseDate` function SHALL resolve both the date and time components into a single accurate Timestamp

2.5 WHEN the prompt instructs Gemini to return extracted data THEN it SHALL specify a defined set of field names in `extractedFields` aligned with the extraction schema (e.g., `category`, `urgency`, `paymentAmount`, `currency`, `submissionMethod`)

2.6 WHEN a source message contains recurrence information with an end condition THEN the system SHALL extract and store the `endDate` in the recurrence object

2.7 WHEN Gemini returns JSON wrapped in various markdown fence formats (with or without language tags, with trailing whitespace/newlines) THEN `parseExtractionResponse` SHALL robustly strip all fence variations and parse the JSON successfully

2.8 WHEN a source message contains items that are payments, forms, or required items THEN the system SHALL enrich the extracted task's title with a clear prefix or category (e.g., "Pay: €8 school portal", "Form: Permission slip", "Pack: Packed lunch") and populate `extractedFields` with structured sub-type data

### Unchanged Behavior (Regression Prevention)

3.1 WHEN a source message contains a simple task without dates or times (e.g., "buy milk") THEN the system SHALL CONTINUE TO extract it as a task with `date: null` and store it with `status: pendingReview`

3.2 WHEN a source message produces no actionable items THEN the system SHALL CONTINUE TO mark the source message as `processingStatus: 'noAction'` and create zero items

3.3 WHEN a source message references a child by name that matches a family member THEN the system SHALL CONTINUE TO populate `childId` and `childName` with the matched member's details

3.4 WHEN the extraction succeeds THEN the system SHALL CONTINUE TO write items to the `items/` collection with `status: 'pendingReview'` and update the source message to `processingStatus: 'completed'`

3.5 WHEN the Gemini API call fails THEN the system SHALL CONTINUE TO catch the error, mark the source message as `processingStatus: 'failed'`, and not create any items

3.6 WHEN items are created successfully THEN the system SHALL CONTINUE TO send a push notification to the household's primary user with the count and first item title

3.7 WHEN a source message contains a clear ISO date string (e.g., "2026-07-15") THEN the system SHALL CONTINUE TO parse it correctly into a Firestore Timestamp at midnight of that date

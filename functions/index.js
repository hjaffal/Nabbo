const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { GoogleGenAI } = require('@google/genai');

initializeApp();
const db = getFirestore();

const PROJECT_ID = 'nabbo-app-4d98a';
const LOCATION = 'europe-west1';

const genai = new GoogleGenAI({
  vertexai: true,
  project: PROJECT_ID,
  location: LOCATION,
});

/**
 * Triggered when a new Source Message is created.
 * Runs the AI extraction pipeline to produce Extracted Items.
 */
exports.extractSourceMessage = onDocumentCreated(
  'households/{householdId}/sourceMessages/{messageId}',
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const message = snapshot.data();
    const householdId = event.params.householdId;
    const messageId = event.params.messageId;

    console.log(`Processing source message: ${messageId} for household: ${householdId}`);

    // Update status to processing
    await snapshot.ref.update({ processingStatus: 'processing' });

    try {
      // Get household context (family members)
      const membersSnapshot = await db
        .collection('households')
        .doc(householdId)
        .collection('members')
        .get();

      const familyMembers = membersSnapshot.docs.map(doc => ({
        id: doc.id,
        name: doc.data().name,
        role: doc.data().role,
      }));

      // Build the extraction prompt
      const prompt = buildExtractionPrompt(message.originalContent, familyMembers);

      // Call Gemini
      const result = await genai.models.generateContent({
        model: 'gemini-2.0-flash',
        contents: prompt,
      });
      const text = result.text;

      // Parse the JSON response
      const extracted = parseExtractionResponse(text);

      if (!extracted || extracted.length === 0) {
        await snapshot.ref.update({
          processingStatus: 'noActionFound',
          processedAt: Timestamp.now(),
        });
        return;
      }

      // Create Extracted Items in Firestore
      const extractedItemIds = [];
      const batch = db.batch();

      for (const item of extracted) {
        const itemRef = db
          .collection('households')
          .doc(householdId)
          .collection('extractedItems')
          .doc();

        batch.set(itemRef, {
          householdId,
          sourceMessageId: messageId,
          affectedMemberId: item.affectedMemberId || null,
          affectedMemberName: item.affectedMemberName || null,
          itemType: item.itemType,
          operationalSummary: item.operationalSummary,
          extractedFields: item.extractedFields || [],
          uncertainFields: item.uncertainFields || [],
          suggestedActions: item.suggestedActions || [],
          suggestedNextStep: item.suggestedNextStep || null,
          reviewStatus: 'pendingReview',
          relatedObjectId: item.relatedObjectId || null,
          relatedObjectType: item.relatedObjectType || null,
          previousValue: item.previousValue || null,
          newValue: item.newValue || null,
          changeType: item.changeType || null,
          riskType: item.riskType || null,
          riskSeverity: item.riskSeverity || null,
          createdAt: Timestamp.now(),
        });

        extractedItemIds.push(itemRef.id);
      }

      await batch.commit();

      // Update source message status
      await snapshot.ref.update({
        processingStatus: 'completed',
        processedAt: Timestamp.now(),
        linkedExtractedItemIds: extractedItemIds,
      });

      console.log(`Created ${extractedItemIds.length} extracted items for message: ${messageId}`);
    } catch (error) {
      console.error('Extraction error:', error);
      await snapshot.ref.update({
        processingStatus: 'failed',
        processedAt: Timestamp.now(),
      });
    }
  }
);

/**
 * Build the extraction prompt for Gemini
 */
function buildExtractionPrompt(content, familyMembers) {
  const membersContext = familyMembers.length > 0
    ? `Family members: ${familyMembers.map(m => `${m.name} (${m.role})`).join(', ')}`
    : 'No family members registered yet.';

  return `You are Nabbo, a family logistics AI assistant. Your job is to extract operational meaning from messy family messages — not just summarize them.

${membersContext}

Analyze the following input and extract ALL actionable household items. For each item, determine:
- Who is affected (match to a family member if possible)
- What needs to happen
- When it matters
- What could be missed

RULES:
- Extract actions, not just summaries
- Create multiple items if the message contains multiple things to do
- Separate facts (clearly stated) from suggestions (inferred)
- Mark uncertain fields clearly
- Do NOT guess important fields (dates, times, amounts) — mark as uncertain if unclear
- A task without an owner should have affectedMemberName set but note "owner: unassigned" in suggestedActions

Return a JSON array. Each item must have this structure:
{
  "itemType": "event|task|deadline|requiredItem|checklist|form|payment|locationUpdate|change|risk",
  "operationalSummary": "Short action-focused summary",
  "affectedMemberName": "Name of the family member affected, or null",
  "affectedMemberId": "ID if matched, or null",
  "extractedFields": [
    { "name": "fieldName", "value": "fieldValue", "confidence": "high|medium|low|unknown", "isSuggested": false, "isInferred": false }
  ],
  "uncertainFields": ["list of field names that are uncertain"],
  "suggestedActions": ["list of suggested next steps"],
  "suggestedNextStep": "The primary action the parent should take",
  "riskType": "noOwner|deadlineNear|missingInfo|null",
  "riskSeverity": "high|medium|low|null",
  "changeType": "timeChanged|dateChanged|locationChanged|null",
  "previousValue": "old value if change detected, or null",
  "newValue": "new value if change detected, or null"
}

Valid confidence levels: "high" (explicitly stated), "medium" (likely but not explicit), "low" (inferred/ambiguous), "unknown" (missing).

INPUT:
${content}

Return ONLY the JSON array. No markdown, no explanation, no wrapping. If nothing actionable is found, return an empty array [].`;
}

/**
 * Parse Gemini's response into structured items
 */
function parseExtractionResponse(text) {
  try {
    // Clean up the response — remove markdown code blocks if present
    let cleaned = text.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.slice(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.slice(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.slice(0, -3);
    }
    cleaned = cleaned.trim();

    const parsed = JSON.parse(cleaned);

    if (!Array.isArray(parsed)) {
      console.error('Extraction response is not an array');
      return [];
    }

    // Validate each item has required fields
    return parsed.filter(item =>
      item.itemType && item.operationalSummary
    );
  } catch (error) {
    console.error('Failed to parse extraction response:', error.message);
    console.error('Raw response:', text.substring(0, 500));
    return [];
  }
}

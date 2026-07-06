const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { GoogleGenAI } = require('@google/genai');

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

const PROJECT_ID = 'nabbo-app-4d98a';
const LOCATION = 'europe-west1';

const genai = new GoogleGenAI({
  apiKey: process.env.GEMINI_API_KEY,
});

/**
 * Triggered when a new Source Message is created.
 * Runs the AI extraction pipeline to produce Extracted Items.
 */
exports.extractSourceMessage = onDocumentCreated(
  {
    document: 'households/{householdId}/sourceMessages/{messageId}',
    secrets: ['GEMINI_API_KEY'],
  },
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

      // Get approved events for context (last 30 days + upcoming 14 days)
      const now = new Date();
      const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
      const eventsSnapshot = await db
        .collection('households')
        .doc(householdId)
        .collection('extractedItems')
        .where('reviewStatus', 'in', ['approved', 'editedAndApproved'])
        .orderBy('createdAt', 'desc')
        .limit(30)
        .get();

      const approvedItems = eventsSnapshot.docs.map(doc => {
        const d = doc.data();
        return {
          type: d.itemType,
          summary: d.operationalSummary,
          member: d.affectedMemberName,
          fields: (d.extractedFields || []).map(f => `${f.name}: ${f.value}`).join(', '),
        };
      });

      // Build the extraction prompt with full context
      const prompt = buildExtractionPrompt(message.originalContent, familyMembers, approvedItems);

      // Call Gemini
      const result = await genai.models.generateContent({
        model: 'gemini-2.5-flash',
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

      // Send push notification to household
      await sendReviewNotification(householdId, extracted);
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
function buildExtractionPrompt(content, familyMembers, approvedItems = []) {
  const membersContext = familyMembers.length > 0
    ? `Family members: ${familyMembers.map(m => `${m.name} (${m.role})`).join(', ')}`
    : 'No family members registered yet.';

  let householdKnowledge = '';
  if (approvedItems.length > 0) {
    householdKnowledge = `\n\nWhat the household already has planned/known:\n${approvedItems.map(item =>
      `- [${item.type}] ${item.summary}${item.member ? ` (${item.member})` : ''}${item.fields ? ` — ${item.fields}` : ''}`
    ).join('\n')}`;
  }

  return `You are Nabbo, a family logistics AI assistant. Your job is to extract operational meaning from messy family messages — not just summarize them.

${membersContext}${householdKnowledge}

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


/**
 * Send push notification when new items need review
 */
async function sendReviewNotification(householdId, extractedItems) {
  try {
    // Get household to find primary user
    const householdDoc = await db.collection('households').doc(householdId).get();
    if (!householdDoc.exists) return;

    const household = householdDoc.data();
    const userId = household.primaryUserId;

    // Get user's FCM token
    const tokenDoc = await db.collection('userTokens').doc(userId).get();
    if (!tokenDoc.exists || !tokenDoc.data().fcmToken) return;

    const fcmToken = tokenDoc.data().fcmToken;

    // Build notification message
    const itemCount = extractedItems.length;
    const firstItem = extractedItems[0];
    const hasUrgent = extractedItems.some(i =>
      i.riskType || i.changeType || (i.itemType === 'deadline')
    );

    let title, body;

    if (hasUrgent) {
      const change = extractedItems.find(i => i.changeType);
      const risk = extractedItems.find(i => i.riskType);
      if (change) {
        title = 'Change detected';
        body = change.operationalSummary;
      } else if (risk) {
        title = 'Needs attention';
        body = risk.operationalSummary;
      } else {
        title = `${itemCount} item${itemCount > 1 ? 's' : ''} need review`;
        body = firstItem.operationalSummary;
      }
    } else {
      title = `${itemCount} item${itemCount > 1 ? 's' : ''} need review`;
      body = firstItem.operationalSummary;
    }

    await messaging.send({
      token: fcmToken,
      notification: { title, body },
      data: {
        type: 'review_needed',
        householdId,
        itemCount: String(itemCount),
      },
      apns: {
        payload: {
          aps: { badge: itemCount, sound: 'default' },
        },
      },
    });

    console.log(`Notification sent to user ${userId}: ${title}`);
  } catch (error) {
    console.error('Failed to send notification:', error.message);
  }
}

/**
 * Scheduled function: runs every hour to check for deadline reminders
 * Sends notifications for deadlines due within 24 hours
 */
exports.checkDeadlines = onSchedule(
  {
    schedule: 'every 60 minutes',
    region: LOCATION,
  },
  async () => {
    const now = new Date();
    const in24Hours = new Date(now.getTime() + 24 * 60 * 60 * 1000);

    // Get all households
    const households = await db.collection('households').get();

    for (const household of households.docs) {
      const householdId = household.id;

      // Check deadlines due within 24h
      const deadlines = await db
        .collection('households')
        .doc(householdId)
        .collection('deadlines')
        .where('status', '==', 'confirmed')
        .where('dueDateTime', '>=', Timestamp.fromDate(now))
        .where('dueDateTime', '<=', Timestamp.fromDate(in24Hours))
        .get();

      // Check payments due within 24h
      const payments = await db
        .collection('households')
        .doc(householdId)
        .collection('payments')
        .where('status', '==', 'confirmed')
        .where('dueDate', '>=', Timestamp.fromDate(now))
        .where('dueDate', '<=', Timestamp.fromDate(in24Hours))
        .get();

      // Check tasks with no owner (owner gaps)
      const ownerGaps = await db
        .collection('households')
        .doc(householdId)
        .collection('tasks')
        .where('status', '==', 'confirmed')
        .where('ownerId', '==', null)
        .get();

      const alerts = [];

      for (const d of deadlines.docs) {
        alerts.push({
          type: 'deadline',
          title: d.data().title,
          member: d.data().affectedMemberName,
        });
      }

      for (const p of payments.docs) {
        alerts.push({
          type: 'payment',
          title: p.data().title,
          amount: p.data().amount,
          currency: p.data().currency,
        });
      }

      for (const t of ownerGaps.docs) {
        alerts.push({
          type: 'owner_gap',
          title: t.data().title,
        });
      }

      if (alerts.length === 0) continue;

      // Send notification
      const userId = household.data().primaryUserId;
      const tokenDoc = await db.collection('userTokens').doc(userId).get();
      if (!tokenDoc.exists || !tokenDoc.data().fcmToken) continue;

      const fcmToken = tokenDoc.data().fcmToken;
      const deadlineCount = deadlines.size;
      const paymentCount = payments.size;
      const ownerGapCount = ownerGaps.size;

      const parts = [];
      if (deadlineCount > 0) parts.push(`${deadlineCount} deadline${deadlineCount > 1 ? 's' : ''} due`);
      if (paymentCount > 0) parts.push(`${paymentCount} payment${paymentCount > 1 ? 's' : ''} due`);
      if (ownerGapCount > 0) parts.push(`${ownerGapCount} owner gap${ownerGapCount > 1 ? 's' : ''}`);

      try {
        await messaging.send({
          token: fcmToken,
          notification: {
            title: 'Needs attention today',
            body: parts.join(', '),
          },
          data: {
            type: 'deadline_reminder',
            householdId,
          },
          apns: {
            payload: {
              aps: { sound: 'default' },
            },
          },
        });
        console.log(`Deadline reminder sent to household ${householdId}`);
      } catch (err) {
        console.error(`Failed to send deadline reminder to ${householdId}:`, err.message);
      }
    }
  }
);

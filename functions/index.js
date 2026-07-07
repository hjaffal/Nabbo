const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { GoogleGenAI } = require('@google/genai');

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

const LOCATION = 'europe-west1';

const genai = new GoogleGenAI({
  apiKey: process.env.GEMINI_API_KEY,
});

/**
 * Triggered when a new Source Message is created.
 * Runs AI extraction and writes items directly to the items/ collection.
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

    await snapshot.ref.update({ processingStatus: 'processing' });

    try {
      // Gather household context
      const membersSnapshot = await db
        .collection('households').doc(householdId).collection('members').get();

      const familyMembers = membersSnapshot.docs.map(doc => ({
        id: doc.id,
        name: doc.data().name,
        role: doc.data().role,
      }));

      // Get existing confirmed items for context (include id + title for matching)
      const existingItemsSnap = await db
        .collection('households').doc(householdId).collection('items')
        .where('status', '==', 'confirmed')
        .orderBy('createdAt', 'desc')
        .limit(30)
        .get();

      const existingItems = existingItemsSnap.docs.map(doc => {
        const d = doc.data();
        return { id: doc.id, title: d.title, type: d.type, childName: d.childName, date: d.date, recurrence: d.recurrence };
      });

      const existingContext = existingItems.map(i =>
        `[${i.type}] ${i.title}${i.childName ? ` (${i.childName})` : ''}`
      );

      // Build prompt and call Gemini
      const prompt = buildExtractionPrompt(message.originalContent, familyMembers, existingContext);

      const result = await genai.models.generateContent({
        model: 'gemini-2.5-flash',
        contents: prompt,
      });
      const text = result.text;

      const extracted = parseExtractionResponse(text);

      if (!extracted || extracted.length === 0) {
        await snapshot.ref.update({ processingStatus: 'noAction', processedAt: Timestamp.now() });
        return;
      }

      // Write items directly to items/ collection
      const batch = db.batch();

      for (const item of extracted) {
        const itemRef = db.collection('households').doc(householdId).collection('items').doc();
        const action = item.action || 'create';

        // Match child to family member (case-insensitive)
        let childId = null;
        let childName = item.childName || null;
        if (childName) {
          const match = familyMembers.find(m =>
            m.name.toLowerCase() === childName.toLowerCase());
          if (match) {
            childId = match.id;
            childName = match.name;
          }
        }

        // Match owner to adult family member (never a child)
        let ownerId = null;
        let ownerName = item.ownerName || null;
        if (ownerName) {
          const adultRoles = ['primaryParent', 'secondaryParent', 'caregiver', 'grandparent'];
          const match = familyMembers.find(m =>
            adultRoles.includes(m.role) &&
            m.name.toLowerCase() === ownerName.toLowerCase());
          if (match) {
            ownerId = match.id;
            ownerName = match.name;
          }
        }

        // For update/cancel: try to find the target item
        let targetItemId = null;
        let previousValues = {};
        if ((action === 'update' || action === 'cancel') && item.targetItemTitle) {
          const target = findMatchingItem(existingItems, item.targetItemTitle, childName, item.type);
          if (target) {
            targetItemId = target.id;
            // Capture previous values for the fields being changed
            if (action === 'update' && item.changes) {
              const targetDoc = await db.collection('households').doc(householdId).collection('items').doc(target.id).get();
              if (targetDoc.exists) {
                const targetData = targetDoc.data();
                for (const key of Object.keys(item.changes)) {
                  previousValues[key] = targetData[key] || null;
                }
              }
            }
          }
        }

        batch.set(itemRef, {
          householdId,
          type: item.type || 'task',
          status: 'pendingReview',
          action,
          title: item.title || item.summary || 'Untitled',
          summary: item.summary || null,
          childId,
          childName,
          ownerId,
          ownerName,
          date: item.date ? parseDate(item.date) : null,
          endDate: item.endDate ? parseDate(item.endDate) : null,
          location: item.location || null,
          recurrence: item.recurrence || null,
          exceptions: [],
          sourceMessageId: messageId,
          targetItemId,
          targetItemTitle: item.targetItemTitle || null,
          changes: item.changes || {},
          previousValues,
          extractedFields: item.fields || {},
          confidence: item.confidence || {},
          uncertainFields: item.uncertainFields || [],
          suggestedActions: item.suggestedActions || [],
          createdAt: Timestamp.now(),
          updatedAt: null,
        });
      }

      await batch.commit();

      // Update source message
      await snapshot.ref.update({
        processingStatus: 'completed',
        processedAt: Timestamp.now(),
      });

      console.log(`Created ${extracted.length} items for message: ${messageId}`);

      // Send notification
      await sendReviewNotification(householdId, extracted);
    } catch (error) {
      console.error('Extraction error:', error);
      await snapshot.ref.update({ processingStatus: 'failed', processedAt: Timestamp.now() });
    }
  }
);

/**
 * Build the extraction prompt.
 * Includes: role, family members, existing items, today's date, rules, output schema.
 */
function buildExtractionPrompt(content, familyMembers, existingContext = []) {
  const today = new Date().toISOString().split('T')[0];
  const dayName = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'][new Date().getDay()];

  const membersStr = familyMembers.length > 0
    ? `Family members: ${familyMembers.map(m => `${m.name} (${m.role})`).join(', ')}`
    : 'No family members registered yet.';

  const contextStr = existingContext.length > 0
    ? `\nExisting household items (for context):\n${existingContext.join('\n')}`
    : '';

  return `You are Nabbo, a family logistics AI. Extract actionable items from the message below.

Today is ${dayName}, ${today}.

${membersStr}${contextStr}

RULES:
- Extract actions, not summaries. Tell the parent what needs to happen.
- Types allowed: "event" (scheduled activity), "task" (action to do), "deadline" (hard due date)
- CHANGE DETECTION: Compare the message against the existing household items listed above. If the message updates or cancels an existing item, use action "update" or "cancel" with targetItemTitle set to the existing item's title. If it's a new item, use action "create".
- Titles must be short, action-focused, and natural.
- Match the affected child to a family member name if possible (set childName).
- Match the responsible adult to a family member if mentioned (set ownerName). Words like "I", "me", "remind me" mean the person who sent this message. "Dad", "Mum" map to parent roles. NEVER assign ownerName to a child.
- Include date AND time when mentioned. "Friday at 18:30" means the date is Friday AND the time is 18:30.
- If an event has an end time (e.g., "2pm to 5pm"), include endDate.
- If recurring, include recurrence object with frequency, dayOfWeek, startDate, and endDate if mentioned.
- For updates: include a "changes" object with only the fields that changed (e.g., {"date": "thursday 18:00", "location": "Main Hall"}).
- Mark uncertain fields in uncertainFields array.
- Do NOT guess dates/times — mark as uncertain if unclear.
- A single message can produce multiple items. Split them.
- If nothing actionable is found, return an empty array [].

Return a JSON array. Each item:
{
  "action": "create|update|cancel",
  "type": "event|task|deadline",
  "title": "Short action-focused title (use existing item's title for update/cancel)",
  "targetItemTitle": "Title of existing item being changed (for update/cancel only, null for create)",
  "changes": { "fieldName": "new value" } (for update only, omit for create/cancel),
  "summary": "What changed or explanation, or null",
  "childName": "Name of affected child or null",
  "ownerName": "Name of responsible adult or null",
  "date": "Date+time string (ISO like 2026-07-15T16:30:00, or relative like 'tomorrow at 4pm', 'friday 18:30', 'next tuesday') or null",
  "endDate": "End date+time string or null",
  "location": "Where it happens or null",
  "recurrence": { "frequency": "weekly|daily|biweekly|monthly", "dayOfWeek": "monday-sunday", "startDate": "YYYY-MM-DD", "endDate": "YYYY-MM-DD or null" } or null,
  "fields": {},
  "confidence": { "date": "high|medium|low|unknown", "childName": "high|medium|low|unknown", "ownerName": "high|medium|low|unknown", "location": "high|medium|low|unknown" },
  "uncertainFields": ["field names that need user verification"],
  "suggestedActions": ["recommended next steps, max 3"]
}

INPUT:
${content}

Return ONLY the JSON array. No markdown fences, no explanation, no extra text.`;
}

/**
 * Parse Gemini response — robustly strips markdown fences.
 */
function parseExtractionResponse(text) {
  try {
    if (!text || !text.trim()) return [];

    let cleaned = text.trim();

    // Strip markdown code fences (various formats)
    if (cleaned.startsWith('```')) {
      // Remove first line (```json or ```)
      const firstNewline = cleaned.indexOf('\n');
      if (firstNewline !== -1) {
        cleaned = cleaned.substring(firstNewline + 1);
      }
    }
    // Remove trailing fence
    const lastFence = cleaned.lastIndexOf('```');
    if (lastFence !== -1) {
      cleaned = cleaned.substring(0, lastFence);
    }

    cleaned = cleaned.trim();

    // Handle case where AI returns just the word "null" or empty
    if (!cleaned || cleaned === 'null' || cleaned === '[]') return [];

    const parsed = JSON.parse(cleaned);
    if (!Array.isArray(parsed)) return [];
    return parsed.filter(item => item.type && item.title);
  } catch (error) {
    console.error('Parse error:', error.message, '| Raw:', text?.substring(0, 200));
    return [];
  }
}

/**
 * Find an existing confirmed item that matches a target title.
 * Uses fuzzy matching: case-insensitive, partial match, same child/type preferred.
 */
function findMatchingItem(existingItems, targetTitle, childName, type) {
  if (!targetTitle) return null;
  const lower = targetTitle.toLowerCase().trim();

  // Exact title match (case-insensitive) + same child + same type
  let match = existingItems.find(i =>
    i.title.toLowerCase() === lower &&
    (!childName || !i.childName || i.childName.toLowerCase() === childName.toLowerCase()) &&
    (!type || i.type === type)
  );
  if (match) return match;

  // Exact title match without child/type filter
  match = existingItems.find(i => i.title.toLowerCase() === lower);
  if (match) return match;

  // Partial match: target contains or is contained in existing title
  match = existingItems.find(i =>
    i.title.toLowerCase().includes(lower) || lower.includes(i.title.toLowerCase())
  );
  return match || null;
}

/**
 * Parse a date string into a Firestore Timestamp.
 * Handles ISO dates, relative dates, and date+time combinations.
 */
function parseDate(dateStr) {
  if (!dateStr) return null;

  try {
    const original = dateStr.trim();
    const lower = original.toLowerCase();

    // 1. Try direct ISO parse (handles "2026-07-15", "2026-07-15T16:30:00", etc.)
    const isoParsed = new Date(original);
    if (!isNaN(isoParsed.getTime()) && /^\d{4}-\d{2}/.test(original)) {
      return Timestamp.fromDate(isoParsed);
    }

    // 2. Extract time component if present (e.g., "at 4pm", "18:30", "at 16:00")
    let hours = null;
    let minutes = 0;

    // Match patterns: "at 4pm", "at 16:00", "4pm", "18:30", "4 pm", "16h00"
    const timePatterns = [
      /(?:at\s+)?(\d{1,2}):(\d{2})\s*(am|pm)?/i,         // 16:00, at 4:30pm, 4:30 pm
      /(?:at\s+)?(\d{1,2})\s*(am|pm)/i,                   // 4pm, at 4 pm, 11am
      /(?:at\s+)?(\d{1,2})h(\d{2})/i,                     // 16h00, 18h30
    ];

    for (const pattern of timePatterns) {
      const match = lower.match(pattern);
      if (match) {
        hours = parseInt(match[1]);
        minutes = match[2] && !match[2].match(/am|pm/i) ? parseInt(match[2]) : 0;
        const ampm = match[3] || match[2];
        if (ampm && /pm/i.test(ampm) && hours < 12) hours += 12;
        if (ampm && /am/i.test(ampm) && hours === 12) hours = 0;
        break;
      }
    }

    // Vague time words
    if (hours === null) {
      if (lower.includes('noon') || lower.includes('12pm')) { hours = 12; minutes = 0; }
      else if (lower.includes('morning')) { hours = 9; minutes = 0; }
      else if (lower.includes('afternoon')) { hours = 14; minutes = 0; }
      else if (lower.includes('evening')) { hours = 18; minutes = 0; }
    }

    // 3. Resolve the date part
    const now = new Date();
    let targetDate = null;

    if (lower.includes('today')) {
      targetDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    } else if (lower.includes('tomorrow')) {
      targetDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
    } else {
      // Check for day-of-week: "monday", "next tuesday", "friday"
      const days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
      const cleanedDay = lower.replace(/at\s+\d.*$/, '').replace('next ', '').trim();

      for (let i = 0; i < days.length; i++) {
        if (cleanedDay.includes(days[i])) {
          const currentDay = now.getDay(); // 0=Sun
          let diff = i - currentDay;
          if (diff <= 0) diff += 7;
          targetDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() + diff);
          break;
        }
      }
    }

    // 4. Combine date + time
    if (targetDate) {
      if (hours !== null) {
        targetDate.setHours(hours, minutes, 0, 0);
      }
      return Timestamp.fromDate(targetDate);
    }

    // 5. Last resort: try Date constructor on the full string
    const lastResort = new Date(original);
    if (!isNaN(lastResort.getTime())) {
      return Timestamp.fromDate(lastResort);
    }
  } catch (_) {}

  return null;
}

/**
 * Send push notification when items need review.
 */
async function sendReviewNotification(householdId, items) {
  try {
    const householdDoc = await db.collection('households').doc(householdId).get();
    if (!householdDoc.exists) return;

    const userId = householdDoc.data().primaryUserId;
    const tokenDoc = await db.collection('userTokens').doc(userId).get();
    if (!tokenDoc.exists || !tokenDoc.data().fcmToken) return;

    const count = items.length;
    const first = items[0];

    await messaging.send({
      token: tokenDoc.data().fcmToken,
      notification: {
        title: `${count} item${count > 1 ? 's' : ''} to review`,
        body: first.title || first.summary || 'New items extracted',
      },
      data: { type: 'review_needed', householdId },
      apns: { payload: { aps: { badge: count, sound: 'default' } } },
    });
  } catch (error) {
    console.error('Notification error:', error.message);
  }
}

/**
 * Scheduled: check for overdue deadlines every hour.
 */
exports.checkDeadlines = onSchedule(
  { schedule: 'every 60 minutes', region: LOCATION },
  async () => {
    const now = new Date();
    const in24h = new Date(now.getTime() + 86400000);

    const households = await db.collection('households').get();

    for (const household of households.docs) {
      const householdId = household.id;

      // Deadlines due within 24h
      const deadlines = await db
        .collection('households').doc(householdId).collection('items')
        .where('type', '==', 'deadline')
        .where('status', '==', 'confirmed')
        .where('date', '>=', Timestamp.fromDate(now))
        .where('date', '<=', Timestamp.fromDate(in24h))
        .get();

      if (deadlines.empty) continue;

      const userId = household.data().primaryUserId;
      const tokenDoc = await db.collection('userTokens').doc(userId).get();
      if (!tokenDoc.exists || !tokenDoc.data().fcmToken) continue;

      try {
        await messaging.send({
          token: tokenDoc.data().fcmToken,
          notification: {
            title: 'Deadlines coming up',
            body: `${deadlines.size} deadline${deadlines.size > 1 ? 's' : ''} due within 24 hours`,
          },
          data: { type: 'deadline_reminder', householdId },
          apns: { payload: { aps: { sound: 'default' } } },
        });
      } catch (err) {
        console.error(`Notification error for ${householdId}:`, err.message);
      }
    }
  }
);

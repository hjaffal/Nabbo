const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
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
    console.log(`Content length: ${(message.originalContent || '').length}, inputMethod: ${message.inputMethod}`);

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

      const existingContext = existingItems.map(i => {
        let desc = `- [${i.type}] "${i.title}"`;
        if (i.childName) desc += ` (child: ${i.childName})`;
        if (i.recurrence) desc += ` [recurring: ${i.recurrence.frequency} on ${i.recurrence.dayOfWeek || 'N/A'}]`;
        else if (i.date) {
          const d = i.date.toDate ? i.date.toDate() : new Date(i.date);
          desc += ` [date: ${d.toISOString().split('T')[0]}]`;
        }
        return desc;
      });

      // Load household intelligence (associations)
      const associationsSnap = await db
        .collection('households').doc(householdId).collection('associations').get();

      const associations = {};
      for (const doc of associationsSnap.docs) {
        const d = doc.data();
        if (!associations[d.childName]) associations[d.childName] = [];
        associations[d.childName].push(`${d.type}:${d.value}`);
      }

      // Clean content (strip HTML tags if present)
      let cleanContent = message.originalContent || '';
      cleanContent = cleanContent.replace(/<[^>]*>/g, ' ').replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/\s+/g, ' ').trim();

      // Build prompt and call Gemini
      const prompt = buildExtractionPrompt(cleanContent, familyMembers, existingContext, associations);

      let result;
      const attachmentUrl = message.attachmentUrl || null;
      const attachmentType = message.attachmentType || null;

      if (attachmentUrl && attachmentType && (attachmentType.startsWith('image') || attachmentType === 'image')) {
        // Multimodal: download image and send as inline data to Gemini
        try {
          const https = require('https');
          const imageBuffer = await new Promise((resolve, reject) => {
            https.get(attachmentUrl, (res) => {
              const chunks = [];
              res.on('data', (chunk) => chunks.push(chunk));
              res.on('end', () => resolve(Buffer.concat(chunks)));
              res.on('error', reject);
            }).on('error', reject);
          });

          const base64Image = imageBuffer.toString('base64');

          result = await genai.models.generateContent({
            model: 'gemini-2.5-flash',
            contents: [
              {
                role: 'user',
                parts: [
                  { text: prompt + '\n\nThe above rules apply. Extract items from the image below:' },
                  { inlineData: { mimeType: 'image/jpeg', data: base64Image } },
                ],
              },
            ],
          });
        } catch (imgErr) {
          console.error('Image download/processing error:', imgErr.message);
          // Fallback to text-only if image fails
          result = await genai.models.generateContent({
            model: 'gemini-2.5-flash',
            contents: prompt,
          });
        }
      } else {
        // Text-only
        result = await genai.models.generateContent({
          model: 'gemini-2.5-flash',
          contents: prompt,
        });
      }
      const text = result.text;

      const extracted = parseExtractionResponse(text);

      if (!extracted || extracted.length === 0) {
        console.log(`No items extracted for ${messageId}. AI response: ${text?.substring(0, 300)}`);
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
          category: item.category || null,
          summary: item.summary || null,
          notes: item.notes || null,
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
      await sendReviewNotification(householdId, extracted, messageId);
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
function buildExtractionPrompt(content, familyMembers, existingContext = [], associations = {}) {
  const today = new Date().toISOString().split('T')[0];
  const dayName = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'][new Date().getDay()];

  const membersStr = familyMembers.length > 0
    ? `Family members: ${familyMembers.map(m => `${m.name} (${m.role})`).join(', ')}`
    : 'No family members registered yet.';

  const contextStr = existingContext.length > 0
    ? `\n\nEXISTING CONFIRMED ITEMS IN THIS HOUSEHOLD (use these for change detection):\n${existingContext.join('\n')}\n\nIMPORTANT: If the input message cancels, reschedules, or modifies any of the items above, you MUST use action "update" or "cancel" with targetItemTitle matching the existing item's title. Do NOT create a new item if it refers to an existing one.`
    : '';

  // Build household intelligence context
  let intelligenceStr = '';
  const childNames = Object.keys(associations);
  if (childNames.length > 0) {
    intelligenceStr = '\n\nHOUSEHOLD INTELLIGENCE (use this to infer which child is affected when not explicitly mentioned):\n';
    for (const child of childNames) {
      intelligenceStr += `- ${child}: ${associations[child].join(', ')}\n`;
    }
    intelligenceStr += '\nIf the message mentions an activity, contact, location, or schedule that matches one child, set childName to that child. If multiple children match, set childName to null and add "childName" to uncertainFields.';
  }

  return `You are Nabbo, a family logistics AI. Extract actionable items from the message below.

Today is ${dayName}, ${today}.

${membersStr}${contextStr}${intelligenceStr}

RULES:
- You are helping a busy parent manage family logistics. Extract ANYTHING that requires parent attention or action.
- Types allowed: "event" (scheduled activity), "task" (action to do), "deadline" (hard due date)
- BE GENEROUS: If there is ANY mention of a date, deadline, enrollment, form, payment, meeting, or request for parent action — extract it. When in doubt, create an item with low confidence rather than returning nothing.
- DEADLINES: Any "by [date]", "before [date]", "due [date]", "deadline", registration closing date, enrollment deadline = create a deadline. This is critical — parents must not miss deadlines.
- OPPORTUNITIES: Enrollment windows, sign-up options, optional activities with deadlines = create a deadline for the decision date AND an event for the activity itself.
- SOFT ACTIONS: "please discuss", "take some time to", "we recommend", "if you wish to", "please complete" = these ARE tasks for the parent. Extract them.
- NOTES FIELD: Capture ALL useful context in the notes field — links, URLs, form names, email addresses to contact, specific instructions, conditions, options to choose from, what subjects are available, etc. The parent should have everything they need in the item without going back to the original message.
- CHANGE DETECTION: Compare the message against the existing household items listed above. If the message updates or cancels an existing item, use action "update" or "cancel" with targetItemTitle. If it's a new item, use action "create".
- Titles must be short, action-focused, and natural.
- Match the affected child to a family member name if possible (set childName). If the message is about all children, create one item per child or set childName to null.
- Match the responsible adult to a family member if mentioned (set ownerName). Words like "I", "me", "remind me" mean the person who sent this message. "Dad", "Mum" map to parent roles. NEVER assign ownerName to a child.
- Include date AND time when mentioned. "Friday at 18:30" means the date is Friday AND the time is 18:30.
- If an event has an end time (e.g., "2pm to 5pm") or date range (Aug 31 to Sep 11), include endDate.
- If recurring, include recurrence object with frequency, dayOfWeek, startDate, and endDate if mentioned.
- For recurrence endDate: "until end of year" = "2026-12-31", "until summer" = "2026-08-31", "until December" = "2026-12-31". Always convert relative end dates to YYYY-MM-DD format.
- For updates: include a "changes" object with only the fields that changed.
- Mark uncertain fields in uncertainFields array.
- A single message can produce multiple items. Split them.
- CRITICAL: School emails, newsletters, and forwards from institutions ALWAYS have actions (enrollment deadlines, events, forms to fill, things to prepare). NEVER return empty for these. Look for dates, deadlines, enrollment periods, forms, payments, or things parents need to decide.
- ONLY return empty array [] if the message is truly personal/social with zero logistics relevance (e.g., "happy birthday!", "thanks for the gift").

Return a JSON array. Each item:
{
  "action": "create|update|cancel",
  "type": "event|task|deadline",
  "category": "A single lowercase word describing what this is about (e.g., basketball, swimming, dentist, school, school trip, birthday, payment, form, pickup, homework, dance, music, hiking, cinema). Choose the most specific and natural category.",
  "title": "Short action-focused title (use existing item's title for update/cancel)",
  "targetItemTitle": "Title of existing item being changed (for update/cancel only, null for create)",
  "changes": { "fieldName": "new value" } (for update only, omit for create/cancel),
  "summary": "Brief explanation of what this is about",
  "notes": "ALL additional useful information: links, URLs, form names, email addresses, instructions, conditions, options, subjects available, contact details, what to bring, how to submit. The parent should have everything they need here.",
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
 * Write a notification to Firestore AND send FCM push.
 * This is the central notification function — all notification triggers use this.
 */
async function writeNotification(householdId, { type, title, body, itemId, sourceMessageId, priority }) {
  try {
    // Write to notifications collection
    const notifRef = db.collection('households').doc(householdId).collection('notifications').doc();
    await notifRef.set({
      type: type || 'general',
      title: title || '',
      body: body || '',
      itemId: itemId || null,
      sourceMessageId: sourceMessageId || null,
      priority: priority || 'medium',
      read: false,
      actedOn: false,
      createdAt: Timestamp.now(),
    });

    // Send FCM push (best-effort)
    try {
      const householdDoc = await db.collection('households').doc(householdId).get();
      if (!householdDoc.exists) return;

      const userId = householdDoc.data().primaryUserId;
      const tokenDoc = await db.collection('userTokens').doc(userId).get();
      if (!tokenDoc.exists || !tokenDoc.data().fcmToken) return;

      // Count unread for badge
      const unreadSnap = await db.collection('households').doc(householdId)
        .collection('notifications').where('read', '==', false).count().get();
      const badgeCount = unreadSnap.data().count || 0;

      await messaging.send({
        token: tokenDoc.data().fcmToken,
        notification: { title, body },
        data: { type, householdId, itemId: itemId || '', notificationId: notifRef.id },
        apns: { payload: { aps: { badge: badgeCount, sound: 'default' } } },
      });
    } catch (fcmErr) {
      console.error('FCM send error:', fcmErr.message);
    }
  } catch (error) {
    console.error('writeNotification error:', error.message);
  }
}

/**
 * Send notification after items are extracted.
 */
async function sendReviewNotification(householdId, items, sourceMessageId) {
  const count = items.length;
  const first = items[0];
  const hasChange = items.some(i => i.action === 'update' || i.action === 'cancel');

  let title, body, type;
  if (hasChange) {
    const changeItem = items.find(i => i.action === 'update' || i.action === 'cancel');
    title = changeItem.action === 'cancel'
        ? `${changeItem.title} cancelled`
        : `${changeItem.title} changed`;
    body = changeItem.summary || 'Tap to review the change';
    type = 'change_detected';
  } else {
    title = `${count} item${count > 1 ? 's' : ''} to review`;
    body = first.title || first.summary || 'New items extracted';
    type = 'review_needed';
  }

  await writeNotification(householdId, {
    type,
    title,
    body,
    sourceMessageId,
    priority: hasChange ? 'high' : 'medium',
  });
}

/**
 * Scheduled: check for deadlines due within 24h (every hour).
 */
exports.checkDeadlines = onSchedule(
  { schedule: 'every 60 minutes', region: LOCATION },
  async () => {
    const now = new Date();
    const in24h = new Date(now.getTime() + 86400000);

    const households = await db.collection('households').get();

    for (const household of households.docs) {
      const householdId = household.id;

      const deadlines = await db
        .collection('households').doc(householdId).collection('items')
        .where('type', '==', 'deadline')
        .where('status', '==', 'confirmed')
        .where('date', '>=', Timestamp.fromDate(now))
        .where('date', '<=', Timestamp.fromDate(in24h))
        .get();

      if (deadlines.empty) continue;

      // Check which deadlines already have notifications (dedup)
      for (const deadline of deadlines.docs) {
        const itemId = deadline.id;
        const itemData = deadline.data();

        // Check if we already notified for this item today
        const existingNotif = await db.collection('households').doc(householdId)
          .collection('notifications')
          .where('itemId', '==', itemId)
          .where('type', '==', 'deadline')
          .where('createdAt', '>=', Timestamp.fromDate(new Date(now.getTime() - 86400000)))
          .limit(1)
          .get();

        if (!existingNotif.empty) continue; // Already notified

        const dueDate = itemData.date.toDate();
        const hoursLeft = Math.round((dueDate - now) / 3600000);

        await writeNotification(householdId, {
          type: 'deadline',
          title: itemData.title,
          body: hoursLeft <= 1 ? 'Due now!' : `Due in ${hoursLeft} hours`,
          itemId,
          priority: hoursLeft <= 3 ? 'high' : 'medium',
        });
      }
    }
  }
);

/**
 * Scheduled: check for upcoming events in next 2 hours (every 30 min).
 */
exports.checkUpcomingEvents = onSchedule(
  { schedule: 'every 30 minutes', region: LOCATION },
  async () => {
    const now = new Date();
    const in2h = new Date(now.getTime() + 7200000);

    const households = await db.collection('households').get();

    for (const household of households.docs) {
      const householdId = household.id;

      const events = await db
        .collection('households').doc(householdId).collection('items')
        .where('type', '==', 'event')
        .where('status', '==', 'confirmed')
        .where('date', '>=', Timestamp.fromDate(now))
        .where('date', '<=', Timestamp.fromDate(in2h))
        .get();

      if (events.empty) continue;

      for (const event of events.docs) {
        const itemId = event.id;
        const itemData = event.data();

        // Dedup: check if we already sent a reminder for this event
        const existingNotif = await db.collection('households').doc(householdId)
          .collection('notifications')
          .where('itemId', '==', itemId)
          .where('type', '==', 'event_reminder')
          .limit(1)
          .get();

        if (!existingNotif.empty) continue;

        const eventTime = itemData.date.toDate();
        const minsLeft = Math.round((eventTime - now) / 60000);
        const timeStr = `${eventTime.getHours().toString().padStart(2, '0')}:${eventTime.getMinutes().toString().padStart(2, '0')}`;

        let body = `At ${timeStr}`;
        if (itemData.location) body += ` — ${itemData.location}`;
        if (itemData.childName) body = `${itemData.childName}: ${body}`;

        await writeNotification(householdId, {
          type: 'event_reminder',
          title: itemData.title,
          body,
          itemId,
          priority: minsLeft <= 60 ? 'high' : 'medium',
        });
      }
    }
  }
);

/**
 * Triggered when an item is updated (e.g., approved).
 * Builds household associations for the intelligence layer.
 */
exports.buildAssociations = onDocumentUpdated(
  {
    document: 'households/{householdId}/items/{itemId}',
  },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const householdId = event.params.householdId;
    const itemId = event.params.itemId;

    // Only trigger when item is approved (status changes to confirmed)
    if (before.status === 'confirmed' || after.status !== 'confirmed') return;
    // Must have a child assigned
    if (!after.childId || !after.childName) return;

    const childId = after.childId;
    const childName = after.childName;
    const associationsRef = db.collection('households').doc(householdId).collection('associations');

    // Helper: upsert an association
    async function upsertAssociation(type, value) {
      if (!value || value.trim() === '') return;
      const normalizedValue = value.toLowerCase().trim();

      // Check if association already exists
      const existing = await associationsRef
        .where('childId', '==', childId)
        .where('type', '==', type)
        .where('value', '==', normalizedValue)
        .limit(1)
        .get();

      if (existing.empty) {
        // Create new association
        await associationsRef.add({
          childId,
          childName,
          type,
          value: normalizedValue,
          confidence: 'inferred',
          sourceItemIds: [itemId],
          lastSeen: Timestamp.now(),
          count: 1,
        });
      } else {
        // Update existing
        const doc = existing.docs[0];
        const data = doc.data();
        const sourceItems = data.sourceItemIds || [];
        if (!sourceItems.includes(itemId)) sourceItems.push(itemId);

        const newCount = (data.count || 0) + 1;
        await doc.ref.update({
          lastSeen: Timestamp.now(),
          count: newCount,
          sourceItemIds: sourceItems,
          // Auto-promote to confirmed after 4 occurrences
          confidence: newCount >= 4 ? 'confirmed' : data.confidence,
        });
      }
    }

    // Extract associations from the approved item
    const title = (after.title || '').toLowerCase();

    // 1. Activity association (extract key activity words from title)
    const activityWords = title.replace(/[^a-z\s]/g, '').split(' ').filter(w => w.length > 3);
    // Use the most significant word (longest, excluding common words)
    const stopWords = ['with', 'from', 'this', 'that', 'have', 'been', 'will', 'your', 'their', 'about', 'school', 'class'];
    const significantWords = activityWords.filter(w => !stopWords.includes(w));
    if (significantWords.length > 0) {
      // Use title as activity if it looks like an activity name
      const activityName = significantWords.sort((a, b) => b.length - a.length)[0];
      if (activityName && activityName.length > 3) {
        await upsertAssociation('activity', activityName);
      }
    }

    // 2. Location association
    if (after.location) {
      await upsertAssociation('location', after.location);
    }

    // 3. Schedule association (day of week from recurrence or date)
    if (after.recurrence && after.recurrence.dayOfWeek) {
      await upsertAssociation('schedule', after.recurrence.dayOfWeek);
    } else if (after.date) {
      const d = after.date.toDate ? after.date.toDate() : new Date(after.date);
      const days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
      await upsertAssociation('schedule', days[d.getDay()]);
    }

    // 4. Contact association (from source message sender)
    if (after.sourceMessageId) {
      try {
        const sourceDoc = await db.collection('households').doc(householdId)
          .collection('sourceMessages').doc(after.sourceMessageId).get();
        if (sourceDoc.exists) {
          const sourceData = sourceDoc.data();
          // If email forwarding, extract sender from content
          if (sourceData.inputMethod === 'emailForwarding') {
            const content = sourceData.originalContent || '';
            // Try to find email address in content
            const emailMatch = content.match(/[\w.-]+@[\w.-]+\.\w+/);
            if (emailMatch) {
              await upsertAssociation('contact', emailMatch[0]);
            }
          }
        }
      } catch (_) {}
    }

    console.log(`Built associations for item ${itemId}, child: ${childName}`);
  }
);

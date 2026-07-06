const express = require('express');
const multer = require('multer');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');

// Initialize Firebase Admin
initializeApp();
const db = getFirestore();
const storage = getStorage();

const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
const upload = multer({ storage: multer.memoryStorage() });

// Health check
app.get('/', (req, res) => {
  res.status(200).send('Nabbo Email Ingestion Service is running');
});

/**
 * Resend Inbound webhook endpoint
 * Receives forwarded emails and stores them as Source Messages in Firestore
 * 
 * Resend sends a JSON POST with:
 * - from: sender email
 * - to: recipient (our alias, e.g. familyname@nabboapp.com)
 * - subject: email subject
 * - text: plain text body
 * - html: HTML body
 * - attachments: array of { filename, content (base64), content_type }
 */
app.post('/inbound', upload.any(), async (req, res) => {
  try {
    const body = req.body;
    const from = body.from;
    const to = body.to;
    const subject = body.subject;
    const text = body.text;
    const html = body.html;
    const attachments = body.attachments || [];

    console.log(`Received email from: ${from}, to: ${to}, subject: ${subject}`);

    // Extract the alias from the "to" field (e.g., "familyname@nabboapp.com")
    const toAddress = extractEmail(to);
    const alias = toAddress.split('@')[0];

    // Find the household by email alias
    const household = await findHouseholdByAlias(toAddress);

    if (!household) {
      console.log(`No household found for alias: ${toAddress}`);
      return res.status(200).send('No household found for this alias');
    }

    // Build the content from the email
    const content = buildContent({ from, subject, text, html });

    // Upload attachments to Cloud Storage if any
    const attachmentUrls = [];
    for (const attachment of attachments) {
      const url = await uploadAttachment(household.id, attachment);
      if (url) attachmentUrls.push(url);
    }

    // Create Source Message in Firestore
    const sourceMessageRef = db
      .collection('households')
      .doc(household.id)
      .collection('sourceMessages')
      .doc();

    await sourceMessageRef.set({
      householdId: household.id,
      submittedBy: 'email-ingestion',
      inputMethod: 'emailForwarding',
      originalContent: content,
      attachmentUrl: attachmentUrls.length > 0 ? attachmentUrls[0] : null,
      attachmentType: attachmentUrls.length > 0 ? 'email-attachment' : null,
      sourceApp: 'email',
      processingStatus: 'pending',
      linkedExtractedItemIds: [],
      receivedAt: Timestamp.now(),
      metadata: {
        from: from,
        to: to,
        subject: subject,
        hasHtml: !!html,
        attachmentCount: attachments.length,
        attachmentUrls: attachmentUrls,
      },
    });

    console.log(`Source message created: ${sourceMessageRef.id} for household: ${household.id}`);

    res.status(200).send('OK');
  } catch (error) {
    console.error('Error processing inbound email:', error);
    res.status(200).send('Error processed');
  }
});

/**
 * Extract email address from a formatted string like "Name <email@example.com>"
 */
function extractEmail(str) {
  if (!str) return '';
  if (typeof str === 'object' && str.address) return str.address.toLowerCase();
  if (typeof str !== 'string') return '';
  const match = str.match(/<(.+?)>/);
  if (match) return match[1].toLowerCase();
  return str.trim().toLowerCase();
}

/**
 * Find household by email alias
 */
async function findHouseholdByAlias(emailAddress) {
  const snapshot = await db
    .collection('households')
    .where('emailAlias', '==', emailAddress)
    .limit(1)
    .get();

  if (snapshot.empty) return null;

  const doc = snapshot.docs[0];
  return { id: doc.id, ...doc.data() };
}

/**
 * Build readable content from email parts
 */
function buildContent({ from, subject, text, html }) {
  let content = '';

  if (subject) {
    content += `Subject: ${subject}\n`;
  }
  if (from) {
    const sender = typeof from === 'string' ? from : from.address || JSON.stringify(from);
    content += `From: ${sender}\n`;
  }
  content += '\n---\n\n';

  if (text) {
    content += text;
  } else if (html) {
    content += html.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim();
  }

  return content.trim();
}

/**
 * Upload attachment to Cloud Storage
 * Resend sends attachments as { filename, content (base64), content_type }
 */
async function uploadAttachment(householdId, attachment) {
  try {
    const bucket = storage.bucket();
    const filename = `households/${householdId}/attachments/${Date.now()}-${attachment.filename}`;
    const blob = bucket.file(filename);

    const buffer = Buffer.from(attachment.content, 'base64');

    await blob.save(buffer, {
      metadata: {
        contentType: attachment.content_type,
      },
    });

    const [url] = await blob.getSignedUrl({
      action: 'read',
      expires: Date.now() + 7 * 24 * 60 * 60 * 1000,
    });

    return url;
  } catch (error) {
    console.error('Error uploading attachment:', error);
    return null;
  }
}

// Start server
const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`Nabbo Email Ingestion Service listening on port ${PORT}`);
});

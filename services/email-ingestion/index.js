const express = require('express');
const multer = require('multer');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');

// Initialize Firebase Admin
initializeApp();
const db = getFirestore();
const storage = getStorage();

const app = express();
const upload = multer({ storage: multer.memoryStorage() });

// Health check
app.get('/', (req, res) => {
  res.status(200).send('Nabbo Email Ingestion Service is running');
});

/**
 * SendGrid Inbound Parse webhook endpoint
 * Receives forwarded emails and stores them as Source Messages in Firestore
 * 
 * SendGrid sends a multipart/form-data POST with:
 * - from: sender email
 * - to: recipient (our alias, e.g. familyname@nabboapp.com)
 * - subject: email subject
 * - text: plain text body
 * - html: HTML body
 * - attachments: number of attachments
 * - attachment1, attachment2, etc: file attachments
 */
app.post('/inbound', upload.any(), async (req, res) => {
  try {
    const { from, to, subject, text, html } = req.body;
    const attachments = req.files || [];

    console.log(`Received email from: ${from}, to: ${to}, subject: ${subject}`);

    // Extract the alias from the "to" field (e.g., "familyname@nabboapp.com")
    const toAddress = extractEmail(to);
    const alias = toAddress.split('@')[0];

    // Find the household by email alias
    const household = await findHouseholdByAlias(toAddress);

    if (!household) {
      console.log(`No household found for alias: ${toAddress}`);
      // Still return 200 so SendGrid doesn't retry
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
    // Return 200 to prevent SendGrid retries on our errors
    res.status(200).send('Error processed');
  }
});

/**
 * Extract email address from a formatted string like "Name <email@example.com>"
 */
function extractEmail(str) {
  if (!str) return '';
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
    content += `From: ${from}\n`;
  }
  content += '\n---\n\n';

  // Prefer plain text, fall back to HTML stripped of tags
  if (text) {
    content += text;
  } else if (html) {
    content += html.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim();
  }

  return content.trim();
}

/**
 * Upload attachment to Cloud Storage
 */
async function uploadAttachment(householdId, file) {
  try {
    const bucket = storage.bucket();
    const filename = `households/${householdId}/attachments/${Date.now()}-${file.originalname}`;
    const blob = bucket.file(filename);

    await blob.save(file.buffer, {
      metadata: {
        contentType: file.mimetype,
      },
    });

    // Make accessible via signed URL (valid for 7 days)
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

# Nabbo Email Ingestion Service

Cloud Run service that receives forwarded emails via SendGrid Inbound Parse and stores them as Source Messages in Firestore.

## How it works

1. Parent forwards an email to `familyname@nabboapp.com`
2. SendGrid receives the email (via MX records)
3. SendGrid POSTs the email content to this Cloud Run service
4. Service finds the household by email alias
5. Service creates a Source Message in Firestore
6. AI extraction pipeline processes it (Phase 3)

## Setup

### 1. SendGrid Inbound Parse

1. Create a SendGrid account at https://sendgrid.com
2. Go to Settings → Inbound Parse
3. Add a host/domain: `nabboapp.com`
4. Set the URL to your Cloud Run service URL: `https://email-ingestion-XXXXX.run.app/inbound`
5. Check "POST the raw, full MIME message" → **OFF**
6. Check "Check incoming emails for spam" → optional

### 2. DNS Records

Add these MX records to your `nabboapp.com` domain:

| Type | Host | Value | Priority |
|------|------|-------|----------|
| MX | @ | mx.sendgrid.net | 10 |

### 3. Deploy to Cloud Run

```bash
gcloud run deploy email-ingestion \
  --source . \
  --region europe-west1 \
  --allow-unauthenticated \
  --project nabbo-app-4d98a
```

### 4. Update Household Email Aliases

When a household is created, their email alias should be set to:
`householdname@nabboapp.com`

## Local Development

```bash
npm install
npm run dev
```

Test with curl:
```bash
curl -X POST http://localhost:8080/inbound \
  -F "from=school@example.com" \
  -F "to=myfamily@nabboapp.com" \
  -F "subject=School Trip Friday" \
  -F "text=Dear parents, Adam's class will visit the museum on Friday."
```

## Environment

- Runs on Google Cloud Run
- Uses Firebase Admin SDK (auto-authenticated on GCP)
- Stores attachments in Cloud Storage
- Writes Source Messages to Firestore

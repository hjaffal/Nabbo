# Nabbo Email Ingestion Service

Cloud Run service that receives forwarded emails via Resend Inbound Webhooks and stores them as Source Messages in Firestore.

## How it works

1. Parent forwards an email to `familyname@nabboapp.com`
2. Resend receives the email (via MX records on nabboapp.com)
3. Resend POSTs the email content to this Cloud Run service webhook
4. Service finds the household by email alias
5. Service creates a Source Message in Firestore
6. AI extraction pipeline processes it (Phase 3)

## Setup

### 1. Resend Inbound

1. Go to https://resend.com → Sign up / Log in
2. Go to **Domains** → Add `nabboapp.com` and verify it
3. Go to **Webhooks** → Create a webhook
4. Set the endpoint URL to your Cloud Run service: `https://email-ingestion-XXXXX.run.app/inbound`
5. Select the event: `email.received`

### 2. DNS Records

Add these records to your `nabboapp.com` domain (Resend will provide the exact values during domain verification):

| Type | Host | Value | Priority |
|------|------|-------|----------|
| MX | inbound | feedback-smtp.us-east-1.amazonses.com | 10 |
| TXT | @ | (Resend verification TXT record) | - |

Note: Resend uses AWS SES under the hood. The exact MX values will be shown in the Resend dashboard during setup.

### 3. Deploy to Cloud Run

```bash
gcloud run deploy email-ingestion \
  --source . \
  --region europe-west1 \
  --allow-unauthenticated \
  --project nabbo-app-4d98a
```

### 4. Household Email Aliases

When a household is created, their email alias is set to:
`householdname@nabboapp.com`

## Local Development

```bash
npm install
npm run dev
```

Test with curl:
```bash
curl -X POST http://localhost:8080/inbound \
  -H "Content-Type: application/json" \
  -d '{
    "from": "school@example.com",
    "to": "myfamily@nabboapp.com",
    "subject": "School Trip Friday",
    "text": "Dear parents, Adam'\''s class will visit the museum on Friday.",
    "attachments": []
  }'
```

## Environment

- Runs on Google Cloud Run
- Uses Firebase Admin SDK (auto-authenticated on GCP)
- Stores attachments in Cloud Storage
- Writes Source Messages to Firestore

# GCP Email Service Setup Guide

This guide explains how to set up the email service using Google Cloud Platform services.

## Architecture

```
React Web App -> Firestore(GCP) -> Cloud Tasks(Cloud Function + Sendgrid)
```

## Prerequisites

1. **Google Cloud Platform Account**
   - Create a GCP project
   - Enable billing (required for Cloud Tasks)

2. **SendGrid Account**
   - Sign up at https://sendgrid.com
   - Get API key from SendGrid dashboard

3. **GCP Services to Enable**
   - Cloud Tasks API
   - Cloud Functions API
   - Cloud Firestore API
   - Cloud Build API (for deployment)

## Setup Steps

### 1. Enable GCP APIs

```bash
gcloud services enable cloudtasks.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable firestore.googleapis.com
gcloud services enable cloudbuild.googleapis.com
```

### 2. Create Cloud Tasks Queue

```bash
# Set your project and location
export PROJECT_ID=your-gcp-project-id
export LOCATION=us-central1
export QUEUE_NAME=email-queue

# Create the queue
gcloud tasks queues create $QUEUE_NAME \
  --location=$LOCATION \
  --project=$PROJECT_ID
```

### 3. Deploy Cloud Function

```bash
cd backend/cloud_functions/send_email

# Deploy the function
gcloud functions deploy send-email \
  --gen2 \
  --runtime=python311 \
  --region=$LOCATION \
  --source=. \
  --entry-point=send_email \
  --trigger-http \
  --allow-unauthenticated \
  --set-env-vars SENDGRID_API_KEY=your_sendgrid_api_key,SENDGRID_FROM_EMAIL=noreply@yourapp.com
```

### 4. Update Environment Variables

In your `.env` file or environment:

```env
USE_GCP=true
GCP_PROJECT_ID=your-gcp-project-id
GCP_LOCATION=us-central1
GCP_QUEUE_NAME=email-queue
EMAIL_HANDLER_URL=https://$LOCATION-$PROJECT_ID.cloudfunctions.net/send-email
SENDGRID_API_KEY=your_sendgrid_api_key
SENDGRID_FROM_EMAIL=noreply@yourapp.com
```

### 5. Set Up Authentication

The FastAPI backend needs to authenticate with GCP:

```bash
# Authenticate with GCP
gcloud auth application-default login

# Or set service account key
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json
```

### 6. Update Firestore Security Rules

Ensure your Firestore rules allow updates:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth == null;
      allow update: if request.auth == null || request.auth.uid == userId;
    }
  }
}
```

## Local Development vs GCP

### Local Development (Default)

Set `USE_GCP=false` in your `.env`:
- Uses Python `asyncio` for async email processing
- Simulates email sending (or uses SendGrid if API key is provided)
- No GCP services required

### GCP Production

Set `USE_GCP=true` in your `.env`:
- Uses Cloud Tasks for task queuing
- Uses Cloud Function for email processing
- Requires GCP project setup

## Testing

### Test Cloud Function Locally

```bash
cd backend/cloud_functions/send_email

# Install dependencies
pip install -r requirements.txt

# Run locally with functions-framework
functions-framework --target=send_email --port=8080
```

### Test with Cloud Tasks Emulator

GCP doesn't provide a Cloud Tasks emulator, but you can:
1. Use local mode (`USE_GCP=false`) for development
2. Deploy to a test GCP project
3. Use Cloud Tasks in a staging environment

## Monitoring

### View Cloud Tasks

```bash
gcloud tasks queues describe $QUEUE_NAME --location=$LOCATION
```

### View Cloud Function Logs

```bash
gcloud functions logs read send-email --gen2 --region=$LOCATION
```

### Monitor SendGrid

- Check SendGrid dashboard for email delivery stats
- Set up webhooks for delivery events


## Troubleshooting

### "Permission denied" errors
- Ensure service account has Cloud Tasks Admin role
- Check IAM permissions for Cloud Functions

### Cloud Function not receiving tasks
- Verify EMAIL_HANDLER_URL matches deployed function URL
- Check Cloud Function logs for errors
- Ensure function allows unauthenticated requests (or configure authentication)

### SendGrid errors
- Verify SENDGRID_API_KEY is correct
- Check SendGrid account status
- Verify sender email is verified in SendGrid

## Alternative: Using Cloud Run

Instead of Cloud Functions, you can deploy to Cloud Run:

```bash
# Build and deploy
gcloud run deploy send-email \
  --source=backend/cloud_functions/send_email \
  --region=$LOCATION \
  --allow-unauthenticated \
  --set-env-vars SENDGRID_API_KEY=your_key
```

Then update `EMAIL_HANDLER_URL` to the Cloud Run service URL.


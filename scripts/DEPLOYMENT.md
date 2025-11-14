# Deployment Guide

This guide covers deploying both the frontend and backend of the User Registration App.

## Prerequisites

### Frontend Deployment
- Node.js and Yarn installed
- Tests passing
- Production build successful

### Backend Deployment
- Python 3.9+ installed
- Virtual environment set up
- Tests passing
- Environment variables configured

## Frontend Deployment

### Quick Deploy

```bash
# Just build (no deployment)
./scripts/deploy-frontend.sh build

# Deploy to Firebase Hosting
./scripts/deploy-frontend.sh firebase


### Firebase Hosting

1. **Initialize Firebase** (if not already done):
   ```bash
   firebase init hosting
   ```
   - Select `frontend/dist` as the public directory
   - Configure as single-page app: Yes

2. **Deploy**:
   ```bash
   ./scripts/deploy-frontend.sh firebase
   ```

3. **Manual deployment**:
   ```bash
   cd frontend
   yarn build
   cd ..
   firebase deploy --only hosting
   ```



### Generic Static Hosting

1. **Build**:
   ```bash
   ./scripts/deploy-frontend.sh build
   ```

2. **Upload** the `frontend/dist/` folder to your hosting provider:
   - AWS S3 + CloudFront
   - GitHub Pages
   - Any static hosting service

## Backend Deployment

### Quick Deploy

```bash
# Just prepare (no deployment)
./scripts/deploy-backend.sh prepare

# Deploy to GCP Cloud Run
./scripts/deploy-backend.sh gcp-cloud-run

# Build Docker image
./scripts/deploy-backend.sh docker
```

### GCP Cloud Run

1. **Prerequisites**:
   ```bash
   # Install gcloud CLI
   # https://cloud.google.com/sdk/docs/install
   
   # Authenticate
   gcloud auth login
   
   # Set project
   export GCP_PROJECT_ID=your-project-id
   gcloud config set project $GCP_PROJECT_ID
   ```

2. **Deploy**:
   ```bash
   export GCP_PROJECT_ID=your-project-id
   export GCP_REGION=us-central1  # Optional, defaults to us-central1
   export SERVICE_NAME=user-registration-api  # Optional
   
   ./scripts/deploy-backend.sh gcp-cloud-run
   ```

3. **Set environment variables**:
   ```bash
   gcloud run services update user-registration-api \
     --region us-central1 \
     --set-env-vars USE_GCP=true,GCP_PROJECT_ID=your-project-id
   ```

4. **Get service URL**:
   ```bash
   gcloud run services describe user-registration-api \
     --region us-central1 \
     --format 'value(status.url)'
   ```

### Docker Deployment

1. **Build Docker image**:
   ```bash
   ./scripts/deploy-backend.sh docker
   ```

2. **Run locally**:
   ```bash
   docker run -p 5001:5001 \
     --env-file backend/.env \
     user-registration-api:latest
   ```

3. **Push to registry**:
   ```bash
   # Tag for your registry
   docker tag user-registration-api:latest \
     your-registry/user-registration-api:latest
   
   # Push
   docker push your-registry/user-registration-api:latest
   ```

4. **Deploy to platform**:
   - AWS ECS/Fargate
   - Azure Container Instances
   - DigitalOcean App Platform
   - Any Docker-compatible platform

### Other Platforms

#### Heroku

1. **Install Heroku CLI** and login
2. **Create Procfile** in `backend/`:
   ```
   web: uvicorn app:app --host 0.0.0.0 --port $PORT
   ```
3. **Deploy**:
   ```bash
   cd backend
   heroku create your-app-name
   git push heroku main
   ```

#### Railway

1. **Connect repository** to Railway
2. **Set root directory** to `backend`
3. **Configure**:
   - Build command: `pip install -r requirements.txt`
   - Start command: `uvicorn app:app --host 0.0.0.0 --port $PORT`

## Environment Variables

### Frontend Production

Update `frontend/src/services/userService.ts` or use environment variables:

```env
VITE_API_URL=https://your-backend-url.com
VITE_FIREBASE_PROJECT_ID=your-project-id
```

### Backend Production

Create `.env` file or set in deployment platform:

```env
USE_GCP=true
GCP_PROJECT_ID=your-project-id
GCP_LOCATION=us-central1
GCP_QUEUE_NAME=email-queue
EMAIL_HANDLER_URL=https://your-cloud-function-url
SENDGRID_API_KEY=your-key
SENDGRID_FROM_EMAIL=noreply@yourapp.com
GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json
```

## Post-Deployment Checklist

### Frontend
- [ ] Update API endpoint URLs in production
- [ ] Configure Firebase for production
- [ ] Test registration flow
- [ ] Verify CORS settings
- [ ] Check console for errors

### Backend
- [ ] Update CORS origins for production frontend URL
- [ ] Configure production Firestore
- [ ] Set up Cloud Tasks queue (if using GCP)
- [ ] Deploy Cloud Functions (if using GCP)
- [ ] Test API endpoints
- [ ] Monitor logs

## Troubleshooting

### Frontend Build Fails
- Check for TypeScript errors: `cd frontend && yarn build`
- Verify all dependencies installed: `yarn install`
- Check environment variables

### Backend Deployment Fails
- Run tests locally: `cd backend && pytest`
- Check Python version: `python3 --version` (should be 3.9+)
- Verify all dependencies: `pip install -r requirements.txt`
- Check environment variables are set

### CORS Errors in Production
- Update `backend/app.py` CORS origins to include production frontend URL
- Redeploy backend after CORS changes

### Email Not Sending
- Verify SendGrid API key is set
- Check Cloud Tasks queue exists (if using GCP)
- Verify Cloud Function is deployed (if using GCP)
- Check backend logs for errors

## Continuous Deployment

### GitHub Actions Example

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: cd frontend && yarn install && yarn build
      - run: firebase deploy --only hosting --token ${{ secrets.FIREBASE_TOKEN }}
  
  deploy-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: google-github-actions/setup-gcloud@v1
      - run: ./scripts/deploy-backend.sh gcp-cloud-run
```

## Support

For more details, see:
- [Backend README](../backend/README.md)
- [GCP Setup Guide](../backend/cloud_functions/GCP_SETUP.md)


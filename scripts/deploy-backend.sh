#!/bin/bash

# Backend Deployment Script
# Usage: ./scripts/deploy-backend.sh [gcp-cloud-run|docker|prepare]
# Default: prepare (just prepares for deployment)

set -e

cd "$(dirname "$0")/.." || exit

DEPLOY_TARGET="${1:-prepare}"

echo "🚀 Backend Deployment Script"
echo "Target: $DEPLOY_TARGET"
echo ""

# Check if backend directory exists
if [ ! -d "backend" ]; then
    echo "❌ Backend directory not found!"
    exit 1
fi

cd backend || exit

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "❌ Virtual environment not found!"
    echo "Creating virtual environment..."
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
else
    source venv/bin/activate
fi

# Run tests before deployment
echo "📋 Running tests..."
if ! pytest; then
    echo "❌ Tests failed! Please fix tests before deploying."
    exit 1
fi
echo "✅ Tests passed!"
echo ""

# Deploy based on target
case "$DEPLOY_TARGET" in
    gcp-cloud-run)
        echo "☁️  Deploying to GCP Cloud Run..."
        
        # Check if gcloud is installed
        if ! command -v gcloud &> /dev/null; then
            echo "❌ gcloud CLI not found. Install from: https://cloud.google.com/sdk/docs/install"
            exit 1
        fi
        
        # Check if Dockerfile exists
        if [ ! -f "Dockerfile" ]; then
            echo "📝 Creating Dockerfile for Cloud Run..."
            cat > Dockerfile << 'EOF'
FROM python:3.10-slim

WORKDIR /app

# Copy requirements
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose port
EXPOSE 8080

# Run the application
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8080"]
EOF
        fi
        
        # Get project ID
        PROJECT_ID="${GCP_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"
        if [ -z "$PROJECT_ID" ]; then
            echo "❌ GCP_PROJECT_ID not set. Set it with: export GCP_PROJECT_ID=your-project-id"
            exit 1
        fi
        
        SERVICE_NAME="${SERVICE_NAME:-user-registration-api}"
        REGION="${GCP_REGION:-us-central1}"
        
        echo "Project: $PROJECT_ID"
        echo "Service: $SERVICE_NAME"
        echo "Region: $REGION"
        echo ""
        
        # Build and deploy
        echo "🔨 Building container..."
        gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME
        
        echo "🚀 Deploying to Cloud Run..."
        gcloud run deploy $SERVICE_NAME \
            --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
            --platform managed \
            --region $REGION \
            --allow-unauthenticated \
            --set-env-vars USE_GCP=true
        
        echo "✅ Deployed to Cloud Run!"
        echo "Get the service URL with: gcloud run services describe $SERVICE_NAME --region $REGION --format 'value(status.url)'"
        ;;
    
    docker)
        echo "🐳 Building Docker image..."
        
        # Check if Dockerfile exists
        if [ ! -f "Dockerfile" ]; then
            echo "📝 Creating Dockerfile..."
            cat > Dockerfile << 'EOF'
FROM python:3.10-slim

WORKDIR /app

# Copy requirements
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose port
EXPOSE 5001

# Run the application
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "5001"]
EOF
        fi
        
        IMAGE_NAME="${IMAGE_NAME:-user-registration-api}"
        IMAGE_TAG="${IMAGE_TAG:-latest}"
        
        docker build -t $IMAGE_NAME:$IMAGE_TAG .
        
        echo "✅ Docker image built: $IMAGE_NAME:$IMAGE_TAG"
        echo ""
        echo "To run the container:"
        echo "  docker run -p 5001:5001 --env-file .env $IMAGE_NAME:$IMAGE_TAG"
        echo ""
        echo "To push to a registry:"
        echo "  docker tag $IMAGE_NAME:$IMAGE_TAG your-registry/$IMAGE_NAME:$IMAGE_TAG"
        echo "  docker push your-registry/$IMAGE_NAME:$IMAGE_TAG"
        ;;
    
    prepare)
        echo "📦 Preparing backend for deployment..."
        echo ""
        echo "✅ Backend is ready for deployment!"
        echo ""
        echo "Next steps:"
        echo "  1. Ensure all environment variables are set in production"
        echo "  2. Review requirements.txt for production dependencies"
        echo "  3. Set up production database/Firestore"
        echo "  4. Configure CORS for production frontend URL"
        echo "  5. Deploy using your preferred method:"
        echo "     - GCP Cloud Run: ./scripts/deploy-backend.sh gcp-cloud-run"
        echo "     - Docker: ./scripts/deploy-backend.sh docker"
        echo "     - Other: Follow your platform's deployment guide"
        ;;
    
    *)
        echo "❌ Unknown deployment target: $DEPLOY_TARGET"
        echo "Available targets: gcp-cloud-run, docker, prepare"
        exit 1
        ;;
esac

echo ""
echo "🎉 Backend deployment process completed!"


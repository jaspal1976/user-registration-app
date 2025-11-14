#!/bin/bash

# Frontend Deployment Script
# Usage: ./scripts/deploy-frontend.sh [firebase|build]
# Default: build (just creates production build)

set -e

cd "$(dirname "$0")/.." || exit

DEPLOY_TARGET="${1:-build}"

echo "🚀 Frontend Deployment Script"
echo "Target: $DEPLOY_TARGET"
echo ""

# Check if frontend directory exists
if [ ! -d "frontend" ]; then
    echo "❌ Frontend directory not found!"
    exit 1
fi

cd frontend || exit

# Run tests before deployment
echo "📋 Running tests..."
if ! yarn test --run; then
    echo "❌ Tests failed! Please fix tests before deploying."
    exit 1
fi
echo "✅ Tests passed!"
echo ""

# Build the application
echo "🔨 Building frontend..."
if ! yarn build; then
    echo "❌ Build failed!"
    exit 1
fi
echo "✅ Build successful!"
echo ""

# Deploy based on target
case "$DEPLOY_TARGET" in
    firebase)
        echo "🔥 Deploying to Firebase Hosting..."
        if ! command -v firebase &> /dev/null; then
            echo "❌ Firebase CLI not found. Install with: npm install -g firebase-tools"
            exit 1
        fi
        
        # Check if firebase.json exists in root
        if [ ! -f "../firebase.json" ]; then
            echo "⚠️  firebase.json not found. Initializing Firebase..."
            cd ..
            firebase init hosting
            cd frontend || exit
        fi
        
        # Deploy to Firebase
        cd ..
        firebase deploy --only hosting
        echo "✅ Deployed to Firebase Hosting!"
        ;;
    
    
    build)
        echo "✅ Production build created in frontend/dist/"
        echo "📦 You can deploy the dist/ folder to any static hosting service."
        echo ""
        echo "Next steps:"
        echo "  - Upload dist/ to your hosting provider"
        echo "  - Configure environment variables for production"
        echo "  - Update API endpoints in production"
        ;;
    
    *)
        echo "❌ Unknown deployment target: $DEPLOY_TARGET"
        echo "Available targets: firebase, build"
        exit 1
        ;;
esac

echo ""
echo "🎉 Frontend deployment process completed!"


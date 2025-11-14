#!/bin/bash

# Script to start ALL services in one terminal (Firebase, Backend, Frontend)
# Usage: ./scripts/start-all.sh
# Note: This requires all dependencies to be installed

cd "$(dirname "$0")/.." || exit

echo "🚀 Starting ALL Services"
echo ""

# Check prerequisites
if [ ! -f "firebase.json" ]; then
    echo "❌ firebase.json not found. Please run 'firebase init' first."
    exit 1
fi

if [ ! -d "backend/venv" ]; then
    echo "❌ Backend virtual environment not found. Please install backend dependencies first."
    exit 1
fi

echo "✅ Starting all services..."
echo "   - Firebase Emulators (port 4000, 8080, 9099)"
echo "   - FastAPI Backend (port 5001)"
echo "   - React Frontend (port 3000)"
echo ""

# Start all services using concurrently
npx concurrently \
  --names "FIREBASE,BACKEND,FRONTEND" \
  --prefix-colors "red,green,blue" \
  "firebase emulators:start" \
  "cd backend && source venv/bin/activate && python app.py" \
  "cd frontend && yarn dev"

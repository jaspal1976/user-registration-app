#!/bin/bash

# Script to start all services for local development
# Usage: ./scripts/start-dev.sh

echo "🚀 Starting User Registration App Development Environment"
echo ""

# Check if Redis is running
if ! redis-cli ping > /dev/null 2>&1; then
    echo "⚠️  Redis is not running. Starting Redis..."
    redis-server --daemonize yes
    sleep 2
fi

# Check if Firebase emulators are configured
if [ ! -f "firebase.json" ]; then
    echo "❌ firebase.json not found. Please run 'firebase init' first."
    exit 1
fi

echo "✅ All checks passed!"
echo ""
echo "📋 To start the application, run these commands in separate terminals:"
echo ""
echo "1. Firebase Emulators:"
echo "   firebase emulators:start"
echo ""
echo "2. Celery Worker (from backend/):"
echo "   cd backend && source venv/bin/activate && celery -A app.celery_app worker --loglevel=info"
echo ""
echo "3. Python Backend (from backend/):"
echo "   cd backend && source venv/bin/activate && python app.py"
echo ""
echo "4. React Frontend:"
echo "   yarn dev"
echo ""
echo "🌐 Access points:"
echo "   - Frontend: http://localhost:3000"
echo "   - Backend API: http://localhost:5000"
echo "   - Firebase UI: http://localhost:4000"
echo ""


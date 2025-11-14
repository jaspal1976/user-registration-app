#!/bin/bash

# Script to start backend service (FastAPI)
# Usage: ./scripts/start-backend.sh

cd "$(dirname "$0")/.." || exit

echo "🚀 Starting Backend Service"
echo ""

# Check if virtual environment exists
if [ ! -d "backend/venv" ]; then
    echo "❌ Virtual environment not found. Please run:"
    echo "   cd backend && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt"
    exit 1
fi

echo "✅ Starting FastAPI backend..."
echo ""

# Source virtual environment and run service
cd backend || exit
source venv/bin/activate
python app.py

# Quick Start Guide

This guide will help you get the User Registration App running locally in minutes.

## Prerequisites Check

Before starting, ensure you have:
- Node.js (v18+) installed
- Python (v3.9+) installed
- Yarn installed (`npm install -g yarn`)
- Firebase CLI installed (`npm install -g firebase-tools`)

## Step-by-Step Setup

### 1. Install Frontend Dependencies

```bash
cd frontend
yarn install
cd ..
```

### 2. Install Backend Dependencies

```bash
cd backend
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements-dev.txt  # For development (includes tests)
cd ..
```

### 3. Install Root Dependencies (Optional - for dev:all script)

```bash
npm install
# Or: yarn install (if you prefer yarn)
```

### 4. Start All Services

You have **3 options**:

#### Option 1: Two Terminals (Recommended)

**Terminal 1: Firebase Emulators**
```bash
firebase emulators:start
```

**Terminal 2: Backend + Frontend (All in one)**
```bash
yarn dev:all
# Or: npm run dev:all
```
This starts FastAPI backend and React frontend together.

#### Option 2: One Terminal (All Services)

```bash
./scripts/start-all.sh
```
This starts Firebase emulators, backend, and frontend all together.

#### Option 3: Manual (3 Terminals)

If you prefer separate terminals:

**Terminal 1: Firebase Emulators**
```bash
firebase emulators:start
```

**Terminal 2: Python Backend**
```bash
cd backend
source venv/bin/activate
python app.py
```

**Terminal 3: React Frontend**
```bash
cd frontend
yarn dev
```

### 4. Access the Application

- **Frontend**: Open http://localhost:3000 in your browser
- **Firebase UI**: Open http://localhost:4000 to view Firestore data
- **Backend API**: http://localhost:5001/api/health (health check)
- **API Docs**: http://localhost:5001/docs (FastAPI interactive docs)

## Testing the Registration Flow

1. Open http://localhost:3000
2. Fill in the registration form:
   - Email: `test@example.com`
   - First Name: `John`
   - Last Name: `Doe`
3. Click "Register"
4. You should see a success message with a spinner
5. Check Firebase UI (http://localhost:4000) to see the user data in Firestore
6. Check backend terminal logs to see the email task being processed

## Running Tests

### Frontend Tests
```bash
cd frontend
yarn test
```

### Backend Tests
```bash
cd backend
source venv/bin/activate  # On Windows: venv\Scripts\activate
pytest
```

> **Note**: Make sure to install development dependencies: `pip install -r requirements-dev.txt`

## Troubleshooting

### "Firebase emulators not found"
- Install Firebase CLI: `npm install -g firebase-tools`
- Initialize: `firebase init` (select Firestore and Auth emulators)

### "Email not sending"
- Check backend console logs for email service messages
- In local mode without SendGrid, emails are simulated (check console)
- Verify SendGrid API key if using real email sending

### "CORS error in browser"
- Ensure backend is running on port 5001
- Check FastAPI CORS middleware is configured in `app.py`
- Verify CORS origins include `http://localhost:3000`

### Port conflicts
If ports are already in use:
- **3000**: Change in `frontend/vite.config.ts`
- **5001**: Change in `backend/app.py`
- **8080/9099/4000**: Change in `firebase.json`

## Next Steps

- Read the full [README.md](./README.md) for detailed documentation
- Check out the test files to understand the testing approach
- Review the code comments for implementation details


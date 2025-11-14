# User Registration Web App

A full-stack user registration application built with React.js (TypeScript) frontend and Python (FastAPI) backend, featuring Firestore integration and async email sending with full local development support.

## 🚀 Quick Start

For a quick setup guide, see [QUICKSTART.md](./QUICKSTART.md)

**TL;DR:**
```bash
# Terminal 1: Firebase Emulators
firebase emulators:start

# Terminal 2: Backend + Frontend
yarn dev:all
```

Then open http://localhost:3000 in your browser.

## Features

- **User Registration Form**: Clean, modern UI with form validation
- **Firestore Integration**: User data saved to Firestore using Firebase emulators
- **Async Email Sending**: Background job processing using GCP Cloud Tasks (production) or Python asyncio (local)
- **GCP Integration**: Native Google Cloud Platform services for scalable email processing
- **Local Development**: Fully runnable locally with emulators
- **Unit Tests**: Comprehensive test coverage for both frontend and backend
- **TypeScript**: Fully typed frontend codebase
- **Documentation**: Well-documented codebase with JSDoc and docstrings

## Architecture

```
┌─────────────────┐
│  React Frontend │
│   (TypeScript)  │
└────────┬────────┘
         │
         ├─────────────────┐
         │                 │
         ▼                 ▼
┌─────────────────┐  ┌──────────────┐
│ Firestore       │  │ FastAPI      │
│ Emulator        │  │ Backend      │
│ (Port 8080)     │  │ (Port 5001)  │
└─────────────────┘  └──────────────┘
                              │
                              ▼
                     ┌─────────────────┐
                     │ Email Service   │
                     │ (asyncio/GCP)   │
                     └─────────────────┘
```

**Data Flow:**
1. User submits registration form → Data saved to Firestore
2. Frontend triggers email service → Backend queues async email task
3. Email service processes task → Sends email via SendGrid (or simulates locally)

## Prerequisites

- **Node.js** (v18 or higher)
- **Python** (v3.9 or higher)
- **Yarn** (package manager)
- **Firebase CLI** (for emulators)

Install Firebase CLI:
```bash
npm install -g firebase-tools
```

## Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd user-registeraton
```

### 2. Install Frontend Dependencies

```bash
cd frontend
yarn install
cd ..
```

### 3. Install Backend Dependencies

```bash
cd backend
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements-dev.txt  # For development (includes tests)
# Or for production: pip install -r requirements.txt
cd ..
```

### 4. Install Root Dependencies (Optional - for dev:all script)

```bash
npm install
# Or: yarn install
```

> **Note**: See [backend/README.md](./backend/README.md) for detailed backend setup instructions.

## Running the Application

### Option 1: Two Terminals (Recommended)

**Terminal 1: Firebase Emulators**
```bash
firebase emulators:start
```

**Terminal 2: Backend + Frontend**
```bash
yarn dev:all
# Or from root: npm run dev:all (after installing root dependencies)
```

### Option 2: One Terminal (All Services)

```bash
./scripts/start-all.sh
```

### Option 3: Manual Setup (3 Terminals)

See [QUICKSTART.md](./QUICKSTART.md) for detailed manual setup instructions.

### Access Points

Once running, access:
- **Frontend**: http://localhost:3000
- **Firebase Emulator UI**: http://localhost:4000
- **Backend API Docs**: http://localhost:5001/docs
- **Backend Health Check**: http://localhost:5001/api/health

## Project Structure

```
user-registeraton/
├── frontend/                   # React frontend (TypeScript)
│   ├── src/                    # Source code
│   │   ├── components/         # React components
│   │   ├── services/           # API services
│   │   ├── firebase/          # Firebase configuration
│   │   └── test/              # Test setup
│   ├── package.json           # Frontend dependencies
│   ├── vite.config.ts         # Vite configuration
│   ├── tsconfig.json          # TypeScript configuration
│   └── index.html             # HTML entry point
├── backend/                    # Python FastAPI backend
│   ├── app.py                 # FastAPI application entry point
│   ├── models.py              # Pydantic models
│   ├── routers/               # API routes
│   ├── services/              # Business logic
│   ├── cloud_functions/       # GCP Cloud Functions
│   ├── tests/                 # Backend unit tests
│   ├── requirements.txt       # Production dependencies
│   ├── requirements-dev.txt   # Development dependencies
│   └── README.md              # Backend-specific documentation
├── firebase.json              # Firebase emulator configuration
├── firestore.rules            # Firestore security rules
├── package.json               # Root package (dev scripts)
├── QUICKSTART.md              # Quick start guide
└── README.md                  # This file
```

> **Note**: For detailed backend structure and API documentation, see [backend/README.md](./backend/README.md)

## Testing

### Frontend Tests

```bash
cd frontend
yarn test
```

Run with coverage:
```bash
cd frontend
yarn test:coverage
```

### Backend Tests

```bash
cd backend
source venv/bin/activate
pytest
```

Run with coverage:
```bash
pytest --cov
```

> **Note**: See [backend/README.md](./backend/README.md) for detailed testing instructions.

## Configuration

### Environment Variables

Create a `.env` file in the `backend` directory for local development:

```env
USE_GCP=false
EMAIL_MIN_DELAY_SECONDS=1.0
SENDGRID_API_KEY=your_key_here  # Optional for local development
SENDGRID_FROM_EMAIL=noreply@yourapp.com
```

> **Note**: For production/GCP configuration, see [backend/cloud_functions/GCP_SETUP.md](./backend/cloud_functions/GCP_SETUP.md)

### Email Service Modes

The application supports two modes:

- **Local Development** (Default): Uses Python `asyncio` for async email processing
- **GCP Production**: Uses Cloud Tasks and Cloud Functions for scalable email processing

See [backend/README.md](./backend/README.md) for mode configuration details.

## API Documentation

### Main Endpoints

- `POST /api/send-email` - Queue email for async sending
- `GET /api/health` - Health check
- `GET /` - API information

> **Note**: For detailed API documentation, interactive docs are available at http://localhost:5001/docs when the backend is running. See [backend/README.md](./backend/README.md) for API details.

## Troubleshooting

### Firebase Emulators Not Starting

- Ensure Firebase CLI is installed: `firebase --version`
- Check if ports 8080, 9099, and 4000 are available
- Verify `firebase.json` configuration

### Backend Not Starting

- Ensure virtual environment is activated
- Check Python version: `python3 --version` (should be 3.9+)
- Verify dependencies are installed: `pip list`
- Check port 5001 is available

### Frontend Not Starting

- Ensure Node.js is installed: `node --version` (should be 18+)
- Verify dependencies are installed: `yarn install`
- Check port 3000 is available

### Email Not Sending

- Check backend logs for email service errors
- Verify SendGrid API key is set (optional for local development)
- In local mode without SendGrid, emails are simulated (check console logs)
- See [backend/README.md](./backend/README.md) for email service troubleshooting

### CORS Errors

- Ensure FastAPI CORS middleware is configured
- Check backend is running on port 5001
- Verify frontend is making requests to `http://localhost:5001`

## Deployment

### Frontend Deployment

```bash
# Build for production
./scripts/deploy-frontend.sh build

# Deploy to Firebase Hosting
./scripts/deploy-frontend.sh firebase

# Deploy to Vercel
./scripts/deploy-frontend.sh vercel

# Deploy to Netlify
./scripts/deploy-frontend.sh netlify
```

### Backend Deployment

```bash
# Prepare for deployment
./scripts/deploy-backend.sh prepare

# Deploy to GCP Cloud Run
./scripts/deploy-backend.sh gcp-cloud-run

# Build Docker image
./scripts/deploy-backend.sh docker
```

> **Note**: For detailed deployment instructions, see [scripts/DEPLOYMENT.md](./scripts/DEPLOYMENT.md)

## Documentation

- **[QUICKSTART.md](./QUICKSTART.md)**: Quick setup guide
- **[backend/README.md](./backend/README.md)**: Backend API documentation, setup, and testing
- **[backend/cloud_functions/GCP_SETUP.md](./backend/cloud_functions/GCP_SETUP.md)**: GCP Cloud Functions and Cloud Tasks setup guide
- **[scripts/DEPLOYMENT.md](./scripts/DEPLOYMENT.md)**: Deployment guide for frontend and backend

## Development

### Code Style

- **Frontend**: TypeScript with React best practices
- **Backend**: Python with FastAPI, following PEP 8 style guide

### Adding Features

1. Create a feature branch
2. Add tests for new functionality
3. Ensure all tests pass
4. Update documentation as needed
5. Submit a pull request

## License

MIT

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests
5. Ensure all tests pass
6. Update documentation
7. Commit your changes (`git commit -m 'Add some amazing feature'`)
8. Push to the branch (`git push origin feature/amazing-feature`)
9. Open a Pull Request

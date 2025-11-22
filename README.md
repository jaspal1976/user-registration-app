# User Registration Web App

[![GitHub](https://img.shields.io/badge/GitHub-Repository-blue)](https://github.com/jaspal1976/user-registration-app)

A full-stack user registration app with React/TypeScript frontend and FastAPI backend. Uses Firestore for data storage and supports async email sending.

## Clone the Repository

```bash
git clone https://github.com/jaspal1976/user-registration-app.git
cd user-registration-app
```

## Quick Start (Docker - Recommended)

**Prerequisites:** Install [Docker](https://www.docker.com/get-started) and Docker Compose (included with Docker Desktop).

Start everything with one command:

```bash
./scripts/docker-start.sh start
```

This starts below end point after couple of seconds:
- Frontend (http://localhost:3000)
- Backend API (http://localhost:5001)
- Firebase Emulators (http://localhost:4000)

The script displays all endpoints when ready.

**Other Docker commands:**
```bash
./scripts/docker-start.sh stop     # Stop services
./scripts/docker-start.sh restart  # Restart
./scripts/docker-start.sh logs     # View logs
./scripts/docker-start.sh status   # Check status
```

## Local Development (Without Docker)

**Prerequisites:**
- Node.js v18+, Python 3.9+, Yarn, Firebase CLI

**Setup:**
```bash
# Frontend
cd frontend && yarn install && cd ..

# Backend
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements-dev.txt
cd ..
```

**Run (2 terminals):**
```bash
# Terminal 1: Firebase Emulators
firebase emulators:start

# Terminal 2: Backend + Frontend
yarn dev:all
```

**Access:**
- Frontend: http://localhost:3000
- Backend API: http://localhost:5001
- API Docs: http://localhost:5001/docs
- Firebase UI: http://localhost:4000

## Testing

**Using Docker (Recommended):**
```bash
# Run all tests
./scripts/docker-start.sh test

# Run backend tests only
./scripts/docker-start.sh test:backend

# Run frontend tests only
./scripts/docker-start.sh test:frontend
```

**Or using Docker Compose directly:**
```bash
# Backend tests
docker compose exec backend python -m pytest -v

# Frontend tests
docker compose exec frontend yarn test --run

# View backend logs only
docker compose logs -f backend
```

**Local (without Docker):**
```bash
# Frontend
cd frontend && yarn test

# Backend
cd backend
source venv/bin/activate
pytest
```

## Deployment

### Frontend

**Deploy to Firebase:**
```bash
./scripts/deploy.sh frontend firebase
```

**Build only:**
```bash
./scripts/deploy.sh frontend build
```

### Backend

**Deploy to GCP using Terraform (Recommended):**
```bash
./scripts/deploy.sh backend gcp
```

This provisions:
- Cloud Tasks queue
- Cloud Function for email processing
- Secret Manager for API keys
- All required GCP services

**Deploy to Cloud Run directly:**
```bash
./scripts/deploy.sh backend cloud-run
```

**After Terraform deployment:**
1. Update `backend/.env` with Terraform output values
2. Set SendGrid secrets: `./terraform/scripts/update-secrets.sh`

For detailed Terraform setup, see [terraform/README.md](./terraform/README.md)

## Project Structure

```
.
├── frontend/          # React/TypeScript frontend
├── backend/           # FastAPI backend
│   ├── routers/       # API routes
│   ├── services/      # Business logic
│   ├── models/        # Pydantic models
│   └── tests/         # Unit tests
├── terraform/         # GCP infrastructure
├── scripts/           # Deployment scripts
└── docker-compose.yml # Docker setup
```

## Features

- User registration with form validation
- Firestore integration (emulators for local dev)
- Async email sending (GCP Cloud Tasks or Python asyncio)
- Full TypeScript support
- Unit tests for frontend and backend
- Docker support for easy local development

## Environment Variables

**Local Development:**
```env
USE_GCP=false
EMAIL_MIN_DELAY_SECONDS=1.0
LOG_LEVEL=INFO
```

**GCP Production:**
```env
USE_GCP=true
GCP_PROJECT_ID=your-project-id
GCP_LOCATION=us-central1
GCP_QUEUE_NAME=email-queue
EMAIL_HANDLER_URL=https://...
SENDGRID_API_KEY=your-key
```

## Troubleshooting

**Docker issues:**
- Ensure Docker is running
- Check ports 3000, 4000, 5001 are available
- Run `./scripts/docker-start.sh clean` to reset

**Local development:**
- Install Firebase CLI: `npm install -g firebase-tools`
- Check ports 3000, 4000, 5001, 8080, 9099 are available
- Activate virtual environment: `source backend/venv/bin/activate`

**Email sending:**
- Local: Simulated (no SendGrid needed)
- Production: Requires SendGrid API key in Secret Manager

## Documentation

- [Backend API Details](./backend/README.md)
- [Terraform Infrastructure](./terraform/README.md)

## License

MIT

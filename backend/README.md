# Backend API

FastAPI backend service for user registration with async email sending.
See the cloud_functions/GCP_SETUP.md for GCP setup

## Setup

1. Create virtual environment:
```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:

For production:
```bash
pip install -r requirements.txt
```

For development (includes testing tools):
```bash
pip install -r requirements-dev.txt
```

3. Create `.env` file (optional, for local development):
```env
USE_GCP=false
EMAIL_MIN_DELAY_SECONDS=1.0
SENDGRID_API_KEY=your_key_here
SENDGRID_FROM_EMAIL=noreply@yourapp.com
```

## Running

Start the server:
```bash
python app.py
# or
uvicorn app:app --host 0.0.0.0 --port 5001 --reload
```

Server runs on `http://localhost:5001`

API docs available at: `http://localhost:5001/docs`

## API Endpoints

- `POST /api/send-email` - Queue email for async sending
- `GET /api/health` - Health check
- `GET /` - API info

## Testing

**Important**: Make sure the virtual environment is activated before running tests.

Run tests:
```bash
source venv/bin/activate  # On Windows: venv\Scripts\activate
pytest
```

Run with coverage:
```bash
source venv/bin/activate
pytest --cov
```

## Project Structure

```
backend/
├── app.py                 # FastAPI application
├── models.py              # Pydantic models
├── routers/               # API routes
│   └── email_router.py
├── services/              # Business logic
│   └── email_service.py
├── cloud_functions/       # GCP Cloud Functions
│   └── send_email/
└── tests/                 # Unit tests
    └── test_app.py
```

## Modes

- **Local**: Uses `asyncio` for async email processing
- **GCP**: Uses Cloud Tasks to queue emails (see `GCP_SETUP.md`)


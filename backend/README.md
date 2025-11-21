# Backend API

FastAPI backend for user registration with async email sending.

For GCP setup, see [terraform/README.md](../../terraform/README.md)

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

Activate venv first, then:
```bash
pytest
pytest --cov  # with coverage
```

## Project Structure

```
backend/
├── app.py                 # FastAPI application
├── models.py              # Pydantic models
├── logger_config.py      # Logging configuration
├── routers/               # API routes
│   └── email_router.py
├── services/              # Business logic
│   └── email_service.py
├── cloud_functions/       # GCP Cloud Functions
│   └── send_email/
├── logs/                  # Log files (auto-generated)
└── tests/                 # Unit tests
    └── test_app.py
```

## Logging

- Console output (stdout)
- File logs: `logs/app.log`
- Error logs: `logs/error.log`
- Auto-rotation at 10MB (keeps 5 backups)

Set `LOG_LEVEL` env var (default: `INFO`)

## Modes

- **Local**: Python asyncio
- **GCP**: Cloud Tasks (see [terraform/README.md](../../terraform/README.md))


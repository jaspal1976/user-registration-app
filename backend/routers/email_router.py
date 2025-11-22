from fastapi import APIRouter, HTTPException, status
from models import SendEmailRequest, SendEmailResponse, HealthResponse
from services.email_service import EmailService
from logger_config import logger

router = APIRouter(prefix="/api", tags=["email"])
email_service = EmailService()


@router.post("/send-email", response_model=SendEmailResponse, status_code=status.HTTP_202_ACCEPTED)
async def send_email(request: SendEmailRequest) -> SendEmailResponse:
    logger.info("=" * 60)
    logger.info(f"EMAIL TRIGGERED - User registered: {request.userId}, Email: {request.email}")
    logger.info(f"User registration completed, initiating email job creation...")
    logger.info("=" * 60)
    
    try:
        logger.info(f"🔄 Creating email job for user: {request.userId}")
        task_id = await email_service.queue_email(request.userId, request.email)
        logger.info(f"Email job created successfully")
        logger.info(f"Job ID: {task_id}")
        logger.info(f"User ID: {request.userId}")
        logger.info(f"Email: {request.email}")
        logger.info("=" * 60)
        return SendEmailResponse(
            success=True,
            taskId=task_id,
            message="Email queued successfully"
        )
    except Exception as e:
        logger.error("=" * 60)
        logger.error(f"FAILED to create email job for user: {request.userId}")
        logger.error(f"Error: {str(e)}", exc_info=True)
        logger.error("=" * 60)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to queue email: {str(e)}"
        )


@router.get("/health", response_model=HealthResponse)
async def health() -> HealthResponse:
    return HealthResponse(status="healthy")



from fastapi import APIRouter, HTTPException, status
from models import SendEmailRequest, SendEmailResponse, HealthResponse
from services.email_service import EmailService
from logger_config import logger

router = APIRouter(prefix="/api", tags=["email"])

email_service = EmailService()
logger.info("Email router initialized")


@router.post(
    "/send-email",
    response_model=SendEmailResponse,
    status_code=status.HTTP_202_ACCEPTED,
    summary="Trigger async email sending",
    description="Queues an email task for background processing"
)
async def send_email(request: SendEmailRequest) -> SendEmailResponse:
    """Queue email for async sending."""
    logger.info(f"Received email request for user: {request.userId}, email: {request.email}")
    
    try:
        task_id = await email_service.queue_email(request.userId, request.email)
        logger.info(f"Email queued successfully. Task ID: {task_id}, User ID: {request.userId}")
        
        return SendEmailResponse(
            success=True,
            taskId=task_id,
            message="Email queued successfully"
        )
    except Exception as e:
        logger.error(f"Failed to queue email for user {request.userId}: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to queue email: {str(e)}"
        )


@router.get(
    "/health",
    response_model=HealthResponse,
    summary="Health check",
    description="Check if the service is running"
)
async def health() -> HealthResponse:
    """Health check endpoint."""
    logger.debug("Health check endpoint accessed")
    return HealthResponse(status="healthy")


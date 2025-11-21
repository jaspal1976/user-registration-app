from fastapi import APIRouter, HTTPException, status
from models import SendEmailRequest, SendEmailResponse, HealthResponse
from services.email_service import EmailService
from logger_config import logger

router = APIRouter(prefix="/api", tags=["email"])
email_service = EmailService()


@router.post("/send-email", response_model=SendEmailResponse, status_code=status.HTTP_202_ACCEPTED)
async def send_email(request: SendEmailRequest) -> SendEmailResponse:
    logger.info(f"Email request for user {request.userId}")
    
    try:
        task_id = await email_service.queue_email(request.userId, request.email)
        return SendEmailResponse(
            success=True,
            taskId=task_id,
            message="Email queued successfully"
        )
    except Exception as e:
        logger.error(f"Failed to queue email for {request.userId}: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to queue email: {str(e)}"
        )


@router.get("/health", response_model=HealthResponse)
async def health() -> HealthResponse:
    return HealthResponse(status="healthy")


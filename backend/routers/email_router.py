
from fastapi import APIRouter, HTTPException, status
from models import SendEmailRequest, SendEmailResponse, HealthResponse
from services.email_service import EmailService

router = APIRouter(prefix="/api", tags=["email"])

email_service = EmailService()


@router.post(
    "/send-email",
    response_model=SendEmailResponse,
    status_code=status.HTTP_202_ACCEPTED,
    summary="Trigger async email sending",
    description="Queues an email task for background processing"
)
async def send_email(request: SendEmailRequest) -> SendEmailResponse:
    
    try:
        task_id = await email_service.queue_email(request.userId, request.email)
        
        return SendEmailResponse(
            success=True,
            taskId=task_id,
            message="Email queued successfully"
        )
    except Exception as e:
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
   
    return HealthResponse(status="healthy")


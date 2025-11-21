from pydantic import BaseModel, EmailStr, Field, ConfigDict
from typing import Optional


class SendEmailRequest(BaseModel):
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "userId": "abc123",
                "email": "user@example.com"
            }
        }
    )
    
    userId: str
    email: EmailStr


class SendEmailResponse(BaseModel):
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "success": True,
                "taskId": "task-123",
                "message": "Email queued successfully"
            }
        }
    )
    
    success: bool
    taskId: Optional[str] = None
    message: Optional[str] = None
    error: Optional[str] = None


class HealthResponse(BaseModel):
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "status": "healthy"
            }
        }
    )
    
    status: str


class EmailTaskResult(BaseModel):
    success: bool
    messageId: Optional[str] = None
    email: str
    userId: str
    error: Optional[str] = None


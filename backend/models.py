from pydantic import BaseModel, EmailStr, Field
from typing import Optional


class SendEmailRequest(BaseModel):
    """Request model for sending email."""
    userId: str = Field(..., description="Firestore document ID of the user")
    email: EmailStr = Field(..., description="User's email address")

    class Config:
        json_schema_extra = {
            "example": {
                "userId": "abc123",
                "email": "user@example.com"
            }
        }


class SendEmailResponse(BaseModel):
    """Response model for email sending request."""
    success: bool = Field(..., description="Whether the request was successful")
    taskId: Optional[str] = Field(None, description="Task ID for the queued email")
    message: Optional[str] = Field(None, description="Response message")
    error: Optional[str] = Field(None, description="Error message if request failed")

    class Config:
        json_schema_extra = {
            "example": {
                "success": True,
                "taskId": "task-123",
                "message": "Email queued successfully"
            }
        }


class HealthResponse(BaseModel):
    """Response model for health check."""
    status: str = Field(..., description="Service status")

    class Config:
        json_schema_extra = {
            "example": {
                "status": "healthy"
            }
        }


class EmailTaskResult(BaseModel):
    """Model for email task result."""
    success: bool
    messageId: Optional[str] = None
    email: str
    userId: str
    error: Optional[str] = None


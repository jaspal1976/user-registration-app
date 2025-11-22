from pydantic import BaseModel, EmailStr
from typing import Optional


class SendEmailRequest(BaseModel):
    userId: str
    email: EmailStr


class SendEmailResponse(BaseModel):
    success: bool
    taskId: Optional[str] = None
    message: Optional[str] = None
    error: Optional[str] = None


class HealthResponse(BaseModel):
    status: str


class EmailTaskResult(BaseModel):
    success: bool
    messageId: Optional[str] = None
    email: str
    userId: str
    error: Optional[str] = None


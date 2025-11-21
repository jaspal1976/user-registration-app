variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region for resources"
  type        = string
  default     = "us-central1"
}

variable "queue_name" {
  description = "Name of the Cloud Tasks queue"
  type        = string
  default     = "email-queue"
}

variable "deploy_backend_to_cloud_run" {
  description = "Whether to deploy backend API to Cloud Run"
  type        = bool
  default     = false
}

variable "backend_image_url" {
  description = "Docker image URL for backend API (required if deploy_backend_to_cloud_run is true)"
  type        = string
  default     = ""
}

variable "allow_public_backend_access" {
  description = "Allow unauthenticated access to Cloud Run backend (not recommended for production)"
  type        = bool
  default     = false
}

variable "sendgrid_api_key" {
  description = "SendGrid API key (will be stored in Secret Manager)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "sendgrid_from_email" {
  description = "SendGrid from email address"
  type        = string
  default     = "noreply@yourapp.com"
}


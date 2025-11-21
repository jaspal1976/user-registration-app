output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
}

output "region" {
  description = "GCP Region"
  value       = var.region
}

output "cloud_tasks_queue_name" {
  description = "Cloud Tasks queue name"
  value       = google_cloud_tasks_queue.email_queue.name
}

output "cloud_tasks_queue_location" {
  description = "Cloud Tasks queue location"
  value       = google_cloud_tasks_queue.email_queue.location
}

output "cloud_function_http_url" {
  description = "HTTP-triggered Cloud Function URL"
  value       = google_cloudfunctions2_function.send_email_http.service_config[0].uri
}

output "cloud_function_name" {
  description = "Cloud Function name"
  value       = google_cloudfunctions2_function.send_email_http.name
}

output "cloud_run_backend_url" {
  description = "Cloud Run backend API URL (if deployed)"
  value       = var.deploy_backend_to_cloud_run ? google_cloud_run_service.backend_api[0].status[0].url : null
}

output "service_accounts" {
  description = "Service account emails"
  value = {
    cloud_tasks   = google_service_account.cloud_tasks_sa.email
    cloud_function = google_service_account.cloud_function_sa.email
  }
}

output "secret_manager_secrets" {
  description = "Secret Manager secret names"
  value = {
    sendgrid_api_key  = google_secret_manager_secret.sendgrid_api_key.secret_id
    sendgrid_from_email = google_secret_manager_secret.sendgrid_from_email.secret_id
  }
}

output "function_source_bucket" {
  description = "GCS bucket name for Cloud Function source"
  value       = google_storage_bucket.function_source.name
}

output "environment_variables" {
  description = "Environment variables for backend configuration"
  value = {
    USE_GCP          = "true"
    GCP_PROJECT_ID   = var.project_id
    GCP_LOCATION     = var.region
    GCP_QUEUE_NAME   = var.queue_name
    EMAIL_HANDLER_URL = google_cloudfunctions2_function.send_email_http.service_config[0].uri
  }
  sensitive = false
}


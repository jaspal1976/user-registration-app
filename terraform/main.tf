# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "cloudtasks.googleapis.com",
    "cloudfunctions.googleapis.com",
    "run.googleapis.com",
    "firestore.googleapis.com",
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com",
    "iam.googleapis.com",
  ])

  project = var.project_id
  service = each.value

  disable_dependent_services = false
  disable_on_destroy         = false
}

# Service account for Cloud Tasks
resource "google_service_account" "cloud_tasks_sa" {
  account_id   = "cloud-tasks-sa"
  display_name = "Cloud Tasks Service Account"
  description  = "Service account for Cloud Tasks to invoke Cloud Functions"
}

# Service account for Cloud Function
resource "google_service_account" "cloud_function_sa" {
  account_id   = "email-function-sa"
  display_name = "Email Cloud Function Service Account"
  description  = "Service account for email processing Cloud Function"
}

# Grant Cloud Tasks SA permission to invoke Cloud Function
resource "google_project_iam_member" "cloud_tasks_invoker" {
  project = var.project_id
  role    = "roles/cloudfunctions.invoker"
  member  = "serviceAccount:${google_service_account.cloud_tasks_sa.email}"
}

# Grant Cloud Function SA permission to access Firestore
resource "google_project_iam_member" "function_firestore_user" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.cloud_function_sa.email}"
}

# Grant Cloud Function SA permission to access Secret Manager
resource "google_project_iam_member" "function_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloud_function_sa.email}"
}

# Secret Manager secret for SendGrid API key
resource "google_secret_manager_secret" "sendgrid_api_key" {
  secret_id = "sendgrid-api-key"

  replication {
    auto {}
  }

  depends_on = [google_project_service.required_apis]
}

# Secret version for SendGrid API key
resource "google_secret_manager_secret_version" "sendgrid_api_key" {
  secret      = google_secret_manager_secret.sendgrid_api_key.id
  secret_data = var.sendgrid_api_key != "" ? var.sendgrid_api_key : "CHANGE_ME"

  lifecycle {
    ignore_changes = [secret_data]
  }
}

# Secret Manager secret for SendGrid from email
resource "google_secret_manager_secret" "sendgrid_from_email" {
  secret_id = "sendgrid-from-email"

  replication {
    auto {}
  }

  depends_on = [google_project_service.required_apis]
}

# Secret version for SendGrid from email
resource "google_secret_manager_secret_version" "sendgrid_from_email" {
  secret      = google_secret_manager_secret.sendgrid_from_email.id
  secret_data = var.sendgrid_from_email

  lifecycle {
    ignore_changes = [secret_data]
  }
}

# Cloud Tasks Queue
resource "google_cloud_tasks_queue" "email_queue" {
  name     = var.queue_name
  location = var.region

  rate_limits {
    max_concurrent_dispatches = 10
    max_dispatches_per_second = 5
  }

  retry_config {
    max_attempts       = 3
    max_retry_duration = "300s"
    min_backoff        = "1s"
    max_backoff        = "300s"
    max_doublings      = 5
  }

  depends_on = [google_project_service.required_apis]
}

# HTTP-triggered Cloud Function (Gen2) for email processing
resource "google_cloudfunctions2_function" "send_email_http" {
  name        = "send-email-http"
  location    = var.region
  description = "HTTP-triggered Cloud Function for email processing"

  build_config {
    runtime     = "python311"
    entry_point = "send_email"
    source {
      storage_source {
        bucket = google_storage_bucket.function_source.name
        object = google_storage_bucket_object.function_source.name
      }
    }
  }

  service_config {
    max_instance_count    = 10
    min_instance_count    = 0
    available_memory      = "256M"
    timeout_seconds       = 60
    service_account_email = google_service_account.cloud_function_sa.email
    ingress_settings      = "ALLOW_INTERNAL_AND_GCLB"

    # Use Secret Manager for sensitive values
    secret_environment_variables {
      key        = "SENDGRID_API_KEY"
      project_id = var.project_id
      secret     = google_secret_manager_secret.sendgrid_api_key.secret_id
      version    = "latest"
    }

    secret_environment_variables {
      key        = "SENDGRID_FROM_EMAIL"
      project_id = var.project_id
      secret     = google_secret_manager_secret.sendgrid_from_email.secret_id
      version    = "latest"
    }
  }

  depends_on = [
    google_project_service.required_apis,
    google_storage_bucket.function_source,
    google_service_account.cloud_function_sa,
  ]
}

# IAM binding to allow Cloud Tasks to invoke the function
resource "google_cloudfunctions2_function_iam_member" "invoker" {
  project        = var.project_id
  location       = var.region
  cloud_function = google_cloudfunctions2_function.send_email_http.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${google_service_account.cloud_tasks_sa.email}"

  depends_on = [google_cloudfunctions2_function.send_email_http]
}

# Optional: Cloud Run service for backend API
resource "google_cloud_run_service" "backend_api" {
  count    = var.deploy_backend_to_cloud_run ? 1 : 0
  name     = "user-registration-api"
  location = var.region

  template {
    spec {
      containers {
        image = var.backend_image_url
        ports {
          container_port = 5001
        }
        env {
          name  = "USE_GCP"
          value = "true"
        }
        env {
          name  = "GCP_PROJECT_ID"
          value = var.project_id
        }
        env {
          name  = "GCP_LOCATION"
          value = var.region
        }
        env {
          name  = "GCP_QUEUE_NAME"
          value = var.queue_name
        }
        env {
          name  = "EMAIL_HANDLER_URL"
          value = google_cloudfunctions2_function.send_email_http.service_config[0].uri
        }
        env {
          name  = "LOG_LEVEL"
          value = "INFO"
        }
      }
      service_account_name = google_service_account.cloud_tasks_sa.email
    }
  }

  traffic {
    percent = 100
    latest_revision = true
  }

  depends_on = [google_project_service.required_apis]
}

# Allow unauthenticated access to Cloud Run (optional, configure as needed)
resource "google_cloud_run_service_iam_member" "public_access" {
  count    = var.deploy_backend_to_cloud_run && var.allow_public_backend_access ? 1 : 0
  service  = google_cloud_run_service.backend_api[0].name
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Storage bucket for Cloud Function source code
resource "google_storage_bucket" "function_source" {
  name     = "${var.project_id}-function-source-${random_id.bucket_suffix.hex}"
  location = var.region

  uniform_bucket_level_access = true
  force_destroy               = true

  depends_on = [google_project_service.required_apis]
}

# Random ID for bucket name uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Upload Cloud Function source code
# IMPORTANT: You must create and upload the zip file BEFORE running terraform apply
# 
# Option 1: Use the script
#   ./terraform/scripts/deploy-function.sh
#
# Option 2: Manual upload
#   cd backend/cloud_functions/send_email
#   zip -r function-source.zip . -x "*.pyc" "__pycache__/*" "*.zip"
#   gsutil cp function-source.zip gs://BUCKET_NAME/function-source.zip
#   terraform import google_storage_bucket_object.function_source gs://BUCKET_NAME/function-source.zip
#
# Option 3: Let Terraform upload (requires zip to exist locally)
resource "google_storage_bucket_object" "function_source" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.function_source.name
  
  # This will work if the zip file exists, otherwise you'll need to import it
  source = "${path.module}/../backend/cloud_functions/send_email/function-source.zip"
  
  lifecycle {
    # Ignore changes to source after initial creation
    # This allows you to update the function via gcloud instead of Terraform
    ignore_changes = [source]
  }
}


# Terraform Infrastructure

Terraform scripts to provision GCP infrastructure for the User Registration App.

## What Gets Created

- Cloud Tasks queue for async email processing
- Cloud Function (Gen2) for email sending
- Service accounts with proper IAM roles
- Secret Manager for SendGrid API key
- Optional: Cloud Run service for backend API

## Quick Start

**Using deploy script (Recommended):**
```bash
cd ..
./scripts/deploy.sh backend gcp
```

**Manual setup:**
```bash
cd terraform

# 1. Configure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your GCP project ID

# 2. Initialize
terraform init

# 3. Plan and Apply
terraform plan
terraform apply
```

## Configuration

Edit `terraform.tfvars`:
```hcl
project_id = "your-gcp-project-id"
region = "us-central1"
queue_name = "email-queue"
deploy_backend_to_cloud_run = false
```

## Deployment Methods

### Cloud Function (Email Service)
- Uses **source code** (Python files zipped)
- Automatically packaged by `deploy.sh`
- No Docker required

### Cloud Run (Backend API - Optional)
- Uses **Docker images**
- Requires building and pushing image first:
  ```bash
  ./terraform/scripts/deploy-backend-docker.sh
  ```
- Then set `deploy_backend_to_cloud_run = true` in `terraform.tfvars`

## After Deployment

1. **Get configuration values:**
   ```bash
   terraform output
   ```

2. **Update backend/.env:**
   ```env
   USE_GCP=true
   GCP_PROJECT_ID=$(terraform output -raw project_id)
   GCP_LOCATION=$(terraform output -raw region)
   GCP_QUEUE_NAME=$(terraform output -raw queue_name)
   EMAIL_HANDLER_URL=$(terraform output -raw cloud_function_url)
   ```

3. **Set SendGrid secrets:**
   ```bash
   ./terraform/scripts/update-secrets.sh
   ```

## Clean Up

```bash
terraform destroy
```

## Files

- `main.tf` - Main infrastructure definitions
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `terraform.tfvars.example` - Example configuration
- `scripts/` - Helper scripts

#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$TERRAFORM_DIR"

PROJECT_ID=$(terraform output -raw project_id 2>/dev/null || echo "")

if [ -z "$PROJECT_ID" ]; then
    echo -e "${YELLOW}Project ID not found${NC}"
    read -p "Enter GCP Project ID: " PROJECT_ID
fi

echo -e "${BLUE}Updating SendGrid secrets${NC}"
echo ""

read -sp "SendGrid API Key: " SENDGRID_KEY
echo ""
if [ -n "$SENDGRID_KEY" ]; then
    echo -n "$SENDGRID_KEY" | gcloud secrets versions add sendgrid-api-key \
      --data-file=- \
      --project="$PROJECT_ID"
    echo -e "${GREEN}API key updated${NC}"
fi

read -p "From Email [noreply@yourapp.com]: " SENDGRID_EMAIL
SENDGRID_EMAIL=${SENDGRID_EMAIL:-noreply@yourapp.com}
echo -n "$SENDGRID_EMAIL" | gcloud secrets versions add sendgrid-from-email \
  --data-file=- \
  --project="$PROJECT_ID"
echo -e "${GREEN}From email updated${NC}"


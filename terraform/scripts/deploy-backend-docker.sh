#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$TERRAFORM_DIR/.." && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"

PROJECT_ID=$(cd "$TERRAFORM_DIR" && terraform output -raw project_id 2>/dev/null || gcloud config get-value project 2>/dev/null || echo "")

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}Error: Could not determine GCP Project ID${NC}"
    read -p "Enter GCP Project ID: " PROJECT_ID
fi

TAG="${1:-latest}"
IMAGE_NAME="gcr.io/$PROJECT_ID/user-registration-api:$TAG"

echo -e "${YELLOW}Project:${NC} $PROJECT_ID"
echo -e "${YELLOW}Image:${NC} $IMAGE_NAME"
echo ""

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker not installed${NC}"
    exit 1
fi

if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud not installed${NC}"
    exit 1
fi

echo -e "${YELLOW}Configuring Docker for GCR...${NC}"
gcloud auth configure-docker --quiet

echo ""
echo -e "${YELLOW}Building image...${NC}"
cd "$BACKEND_DIR"
docker build -t "$IMAGE_NAME" .

if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed${NC}"
    exit 1
fi

echo -e "${GREEN}Image built${NC}"

echo ""
echo -e "${YELLOW}Pushing to GCR...${NC}"
docker push "$IMAGE_NAME"

if [ $? -ne 0 ]; then
    echo -e "${RED}Push failed${NC}"
    exit 1
fi

echo -e "${GREEN}Image pushed${NC}"

echo ""
echo -e "${YELLOW}Updating terraform.tfvars...${NC}"
cd "$TERRAFORM_DIR"

if [ -f "terraform.tfvars" ]; then
    if grep -q "backend_image_url" terraform.tfvars; then
        sed -i.bak "s|backend_image_url.*|backend_image_url = \"$IMAGE_NAME\"|g" terraform.tfvars
        rm terraform.tfvars.bak 2>/dev/null || true
    else
        echo "backend_image_url = \"$IMAGE_NAME\"" >> terraform.tfvars
    fi
    
    if grep -q "deploy_backend_to_cloud_run" terraform.tfvars; then
        sed -i.bak "s/deploy_backend_to_cloud_run.*/deploy_backend_to_cloud_run = true/g" terraform.tfvars
        rm terraform.tfvars.bak 2>/dev/null || true
    else
        echo "deploy_backend_to_cloud_run = true" >> terraform.tfvars
    fi
    
    echo -e "${GREEN}Updated terraform.tfvars${NC}"
else
    echo -e "${YELLOW}terraform.tfvars not found. Add:${NC}"
    echo "  backend_image_url = \"$IMAGE_NAME\""
    echo "  deploy_backend_to_cloud_run = true"
fi

echo ""
echo -e "${GREEN}Ready for Cloud Run!${NC}"
echo ""
echo -e "Image: ${BLUE}$IMAGE_NAME${NC}"
echo ""
echo "Next:"
echo "  1. Review terraform.tfvars"
echo "  2. terraform plan"
echo "  3. terraform apply"


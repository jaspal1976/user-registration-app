#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

cd "$(dirname "$0")/.." || exit

DEPLOY_TARGET="${1:-help}"

deploy_frontend() {
    local target="${1:-build}"
    
    if [ ! -d "frontend" ]; then
        echo -e "${RED}Error: frontend directory not found${NC}"
        exit 1
    fi
    
    cd frontend
    
    echo -e "${BLUE}Running frontend tests...${NC}"
    if ! yarn test --run; then
        echo -e "${RED}Tests failed${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Building frontend...${NC}"
    if ! yarn build; then
        echo -e "${RED}Build failed${NC}"
        exit 1
    fi
    
    case "$target" in
        firebase)
            if ! command -v firebase &> /dev/null; then
                echo -e "${RED}Error: Firebase CLI not found${NC}"
                exit 1
            fi
            
            if [ ! -f "../firebase.json" ]; then
                cd ..
                firebase init hosting
                cd frontend
            fi
            
            cd ..
            echo -e "${BLUE}Deploying to Firebase Hosting...${NC}"
            firebase deploy --only hosting
            echo -e "${GREEN}Frontend deployed to Firebase${NC}"
            ;;
        
        build)
            echo -e "${GREEN}Build complete: frontend/dist/${NC}"
            ;;
        
        *)
            echo -e "${RED}Error: unknown frontend target '$target'${NC}"
            echo "Available: firebase, build"
            exit 1
            ;;
    esac
}

deploy_backend_gcp() {
    if ! command -v gcloud &> /dev/null; then
        echo -e "${RED}Error: gcloud CLI not found${NC}"
        exit 1
    fi
    
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}Error: Terraform not found${NC}"
        exit 1
    fi
    
    cd terraform
    
    if [ ! -f "main.tf" ]; then
        echo -e "${RED}Error: terraform directory not found${NC}"
        exit 1
    fi
    
    if [ ! -d ".terraform" ]; then
        echo -e "${YELLOW}Initializing Terraform...${NC}"
        terraform init
    fi
    
    if [ ! -f "terraform.tfvars" ]; then
        echo -e "${YELLOW}Creating terraform.tfvars...${NC}"
        cp terraform.tfvars.example terraform.tfvars
        
        CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
        read -p "GCP Project ID [$CURRENT_PROJECT]: " PROJECT_ID
        PROJECT_ID=${PROJECT_ID:-$CURRENT_PROJECT}
        
        read -p "GCP Region [us-central1]: " REGION
        REGION=${REGION:-us-central1}
        
        sed -i.bak "s/your-gcp-project-id/$PROJECT_ID/g" terraform.tfvars
        sed -i.bak "s/us-central1/$REGION/g" terraform.tfvars
        rm terraform.tfvars.bak 2>/dev/null || true
    fi
    
    FUNCTION_DIR="../backend/cloud_functions/send_email"
    if [ -d "$FUNCTION_DIR" ]; then
        cd "$FUNCTION_DIR"
        if [ ! -f "function-source.zip" ] || [ "function-source.zip" -ot "main.py" ]; then
            echo -e "${YELLOW}Packaging Cloud Function...${NC}"
            zip -r function-source.zip . -x "*.pyc" "__pycache__/*" "*.zip" ".DS_Store" "*.log" 2>/dev/null || true
        fi
        cd - > /dev/null
    fi
    
    echo -e "${BLUE}Running Terraform plan...${NC}"
    terraform plan
    
    echo ""
    read -p "Apply Terraform changes? (yes/no): " CONFIRM
    if [ "$CONFIRM" = "yes" ]; then
        terraform apply
        echo ""
        echo -e "${GREEN}Terraform deployment complete${NC}"
        echo ""
        terraform output
        echo ""
        echo -e "${YELLOW}Next steps:${NC}"
        echo "  1. Update backend/.env with Terraform output values"
        echo "  2. Set SendGrid secrets: ./terraform/scripts/update-secrets.sh"
    else
        echo "Aborted"
    fi
}

deploy_backend_cloud_run() {
    if [ ! -d "backend" ]; then
        echo -e "${RED}Error: backend directory not found${NC}"
        exit 1
    fi
    
    cd backend
    
    if [ ! -d "venv" ]; then
        echo -e "${YELLOW}Creating venv...${NC}"
        python3 -m venv venv
        source venv/bin/activate
        pip install -r requirements.txt
    else
        source venv/bin/activate
    fi
    
    echo -e "${BLUE}Running backend tests...${NC}"
    if ! pytest; then
        echo -e "${RED}Tests failed${NC}"
        exit 1
    fi
    
    if ! command -v gcloud &> /dev/null; then
        echo -e "${RED}Error: gcloud CLI not found${NC}"
        exit 1
    fi
    
    if [ ! -f "Dockerfile" ]; then
        cat > Dockerfile << 'EOF'
FROM python:3.10-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8080
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8080"]
EOF
    fi
    
    PROJECT_ID="${GCP_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"
    if [ -z "$PROJECT_ID" ]; then
        echo -e "${RED}Error: GCP_PROJECT_ID not set${NC}"
        exit 1
    fi
    
    SERVICE_NAME="${SERVICE_NAME:-user-registration-api}"
    REGION="${GCP_REGION:-us-central1}"
    
    echo -e "${BLUE}Building container...${NC}"
    gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME
    
    echo -e "${BLUE}Deploying to Cloud Run...${NC}"
    gcloud run deploy $SERVICE_NAME \
        --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
        --platform managed \
        --region $REGION \
        --allow-unauthenticated \
        --set-env-vars USE_GCP=true
    
    SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region $REGION --format 'value(status.url)' 2>/dev/null)
    echo ""
    echo -e "${GREEN}Backend deployed to Cloud Run${NC}"
    echo -e "${BLUE}Service URL:${NC} $SERVICE_URL"
}

show_help() {
    echo "Deployment Script"
    echo ""
    echo "Usage:"
    echo "  ./deploy.sh frontend [firebase|build]"
    echo "  ./deploy.sh backend [gcp|cloud-run]"
    echo ""
    echo "Examples:"
    echo "  ./deploy.sh frontend firebase    # Deploy frontend to Firebase"
    echo "  ./deploy.sh frontend build        # Build frontend only"
    echo "  ./deploy.sh backend gcp           # Deploy backend using Terraform"
    echo "  ./deploy.sh backend cloud-run    # Deploy backend to Cloud Run"
    echo ""
}

case "$DEPLOY_TARGET" in
    frontend)
        deploy_frontend "${2:-build}"
        ;;
    backend)
        case "${2:-gcp}" in
            gcp)
                deploy_backend_gcp
                ;;
            cloud-run)
                deploy_backend_cloud_run
                ;;
            *)
                echo -e "${RED}Error: unknown backend target '${2}'${NC}"
                echo "Available: gcp, cloud-run"
                exit 1
                ;;
        esac
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}Error: unknown target '$DEPLOY_TARGET'${NC}"
        show_help
        exit 1
        ;;
esac


#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

cd "$(dirname "$0")/.." || exit

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker not installed${NC}"
    exit 1
fi

if docker compose version &> /dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
elif command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    echo -e "${RED}Error: Docker Compose not installed${NC}"
    exit 1
fi

if [ ! -f backend/.env ]; then
    echo -e "${YELLOW}Creating backend/.env...${NC}"
    cat > backend/.env << EOF
USE_GCP=false
EMAIL_MIN_DELAY_SECONDS=1.0
LOG_LEVEL=INFO
FIRESTORE_EMULATOR_HOST=firebase-emulators:8080
FIREBASE_AUTH_EMULATOR_HOST=firebase-emulators:9099
EOF
fi

start_services() {
    echo -e "${BLUE}Starting local development environment...${NC}"
    echo ""
    
    $DOCKER_COMPOSE up --build -d
    
    echo ""
    echo -e "${YELLOW}Waiting for services to be ready...${NC}"
    sleep 8
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     Local Development Environment Ready!              ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Testing Endpoints:${NC}"
    echo ""
    echo -e "  ${BLUE}Frontend:${NC}     http://localhost:3000"
    echo -e "  ${BLUE}Backend API:${NC}  http://localhost:5001"
    echo -e "  ${BLUE}API Docs:${NC}     http://localhost:5001/docs"
    echo -e "  ${BLUE}Health Check:${NC} http://localhost:5001/api/health"
    echo ""
    echo -e "  ${BLUE}Firebase UI:${NC}  http://localhost:4000"
    echo -e "  ${BLUE}Firestore:${NC}   localhost:8080"
    echo -e "  ${BLUE}Auth:${NC}        localhost:9099"
    echo ""
    echo -e "${CYAN}Quick Test:${NC}"
    echo -e "  1. Open ${BLUE}http://localhost:3000${NC} in your browser"
    echo -e "  2. Fill the registration form"
    echo -e "  3. Check ${BLUE}http://localhost:4000${NC} to see saved data"
    echo ""
    echo -e "${CYAN}Useful Commands:${NC}"
    echo -e "  ${YELLOW}$DOCKER_COMPOSE logs -f${NC}        View logs"
    echo -e "  ${YELLOW}$DOCKER_COMPOSE ps${NC}             Check status"
    echo -e "  ${YELLOW}$DOCKER_COMPOSE down${NC}            Stop services"
    echo ""
}

stop_services() {
    echo -e "${YELLOW}Stopping services...${NC}"
    $DOCKER_COMPOSE down
    echo -e "${GREEN}Services stopped${NC}"
}

test_backend() {
    echo -e "${BLUE}Running backend tests...${NC}"
    echo ""
    
    # Check if containers are running
    if ! $DOCKER_COMPOSE ps backend 2>/dev/null | grep -q "Up"; then
        echo -e "${YELLOW}Starting required services...${NC}"
        $DOCKER_COMPOSE up -d firebase-emulators backend 2>&1 | grep -v "already in use" || true
        echo -e "${YELLOW}Waiting for services to be ready...${NC}"
        sleep 10
    fi
    
    echo -e "${BLUE}Executing backend tests...${NC}"
    echo ""
    $DOCKER_COMPOSE exec -T backend python -m pytest -v
}

test_frontend() {
    echo -e "${BLUE}Running frontend tests...${NC}"
    echo ""
    
    # Check if containers are running
    if ! $DOCKER_COMPOSE ps frontend | grep -q "Up"; then
        echo -e "${YELLOW}Starting required services...${NC}"
        $DOCKER_COMPOSE up -d firebase-emulators frontend
        echo -e "${YELLOW}Waiting for services to be ready...${NC}"
        sleep 10
    fi
    
    echo -e "${BLUE}Executing frontend tests...${NC}"
    echo ""
    $DOCKER_COMPOSE exec -T frontend yarn test --run
}

test_services() {
    local target="${1:-all}"
    
    case "$target" in
        backend)
            test_backend
            ;;
        frontend)
            test_frontend
            ;;
        all)
            echo -e "${BLUE}Running all tests...${NC}"
            echo ""
            test_backend
            echo ""
            echo -e "${BLUE}--- Frontend Tests ---${NC}"
            echo ""
            test_frontend
            ;;
        *)
            echo -e "${RED}Unknown test target: $target${NC}"
            echo "Available: backend, frontend, all"
            exit 1
            ;;
    esac
}

case "${1:-start}" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        stop_services
        start_services
        ;;
    logs)
        $DOCKER_COMPOSE logs -f
        ;;
    status)
        $DOCKER_COMPOSE ps
        ;;
    clean)
        echo -e "${YELLOW}Cleaning up...${NC}"
        $DOCKER_COMPOSE down -v
        docker system prune -f
        echo -e "${GREEN}Cleanup complete${NC}"
        ;;
    test)
        test_services "${2:-all}"
        ;;
    *)
        # Handle test:backend and test:frontend
        if [[ "$1" == "test:backend" ]]; then
            test_backend
        elif [[ "$1" == "test:frontend" ]]; then
            test_frontend
        else
            echo "Usage: $0 {start|stop|restart|logs|status|clean|test|test:backend|test:frontend}"
            exit 1
        fi
        ;;
esac

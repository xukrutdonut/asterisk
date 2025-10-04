#!/bin/bash
# Verification script for Docker installation of Asterisk on Raspberry Pi 5
# This script checks if the Docker setup is working correctly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Asterisk Docker Verification Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if Docker is installed
echo -e "${YELLOW}Checking Docker installation...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker is not installed${NC}"
    echo -e "${YELLOW}Please install Docker first:${NC}"
    echo "  curl -fsSL https://get.docker.com -o get-docker.sh"
    echo "  sudo sh get-docker.sh"
    exit 1
fi
echo -e "${GREEN}✓ Docker is installed${NC}"

# Check if Docker Compose is available
echo -e "${YELLOW}Checking Docker Compose...${NC}"
if ! docker compose version &> /dev/null; then
    echo -e "${RED}✗ Docker Compose is not available${NC}"
    echo -e "${YELLOW}Please install Docker Compose plugin${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker Compose is available${NC}"

# Check if docker-compose.yml exists
echo -e "${YELLOW}Checking docker-compose.yml...${NC}"
if [ ! -f docker-compose.yml ]; then
    echo -e "${RED}✗ docker-compose.yml not found${NC}"
    echo -e "${YELLOW}Please run this script from the repository root directory${NC}"
    exit 1
fi
echo -e "${GREEN}✓ docker-compose.yml found${NC}"

# Check if Dockerfile exists
echo -e "${YELLOW}Checking Dockerfile...${NC}"
if [ ! -f Dockerfile ]; then
    echo -e "${RED}✗ Dockerfile not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Dockerfile found${NC}"

# Validate docker-compose.yml syntax
echo -e "${YELLOW}Validating docker-compose.yml syntax...${NC}"
if ! docker compose config > /dev/null 2>&1; then
    echo -e "${RED}✗ docker-compose.yml has syntax errors${NC}"
    docker compose config
    exit 1
fi
echo -e "${GREEN}✓ docker-compose.yml is valid${NC}"

# Check if container is running
echo -e "${YELLOW}Checking if Asterisk container is running...${NC}"
if docker ps | grep -q asterisk; then
    echo -e "${GREEN}✓ Asterisk container is running${NC}"
    
    # Get container uptime
    UPTIME=$(docker inspect --format='{{.State.StartedAt}}' asterisk 2>/dev/null)
    if [ -n "$UPTIME" ]; then
        echo -e "${BLUE}  Started at: $UPTIME${NC}"
    fi
    
    # Check Asterisk version
    echo -e "${YELLOW}Checking Asterisk version...${NC}"
    VERSION=$(docker exec asterisk asterisk -V 2>/dev/null || echo "Unable to get version")
    echo -e "${BLUE}  $VERSION${NC}"
    
    # Check if Asterisk is responsive
    echo -e "${YELLOW}Checking Asterisk responsiveness...${NC}"
    if docker exec asterisk asterisk -rx "core show version" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Asterisk is responsive${NC}"
    else
        echo -e "${YELLOW}⚠ Asterisk may be starting up or not fully initialized${NC}"
    fi
    
    # Check volumes
    echo -e "${YELLOW}Checking persistent volumes...${NC}"
    for vol in asterisk-config asterisk-sounds asterisk-spool asterisk-logs; do
        if docker volume ls | grep -q "$vol"; then
            echo -e "${GREEN}✓ Volume $vol exists${NC}"
        else
            echo -e "${YELLOW}⚠ Volume $vol not found${NC}"
        fi
    done
    
else
    echo -e "${YELLOW}⚠ Asterisk container is not running${NC}"
    echo -e "${BLUE}You can start it with: docker compose up -d${NC}"
    
    # Check if container exists but is stopped
    if docker ps -a | grep -q asterisk; then
        echo -e "${YELLOW}Container exists but is stopped${NC}"
        echo -e "${BLUE}Start it with: docker compose start${NC}"
    fi
fi

# Check architecture
echo -e "${YELLOW}Checking system architecture...${NC}"
ARCH=$(uname -m)
echo -e "${BLUE}  Architecture: $ARCH${NC}"
if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    echo -e "${GREEN}✓ Running on ARM64 (native)${NC}"
else
    echo -e "${YELLOW}⚠ Not running on ARM64. Build will use emulation and be slower.${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Verification complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  ${BLUE}1.${NC} Build and start: ${GREEN}docker compose up -d --build${NC}"
echo -e "  ${BLUE}2.${NC} View logs: ${GREEN}docker compose logs -f${NC}"
echo -e "  ${BLUE}3.${NC} Access CLI: ${GREEN}docker exec -it asterisk asterisk -rvvv${NC}"
echo -e "  ${BLUE}4.${NC} Stop: ${GREEN}docker compose down${NC}"
echo ""
echo -e "${YELLOW}Documentation:${NC}"
echo -e "  ${BLUE}•${NC} English: ${GREEN}DOCKER.md${NC}"
echo -e "  ${BLUE}•${NC} Español: ${GREEN}INICIO-RAPIDO-RPI5.md${NC}"
echo ""

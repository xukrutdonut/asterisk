#!/bin/bash
# Automated build script for Asterisk on Raspberry Pi 5
# Usage: ./build-rpi5.sh [version]
#
# Example: ./build-rpi5.sh 20.0.0

set -e

# Default version if not specified
VERSION=${1:-20.0.0}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Building Asterisk for Raspberry Pi 5 ===${NC}"
echo -e "Version: ${YELLOW}${VERSION}${NC}"
echo ""

# Detect architecture
ARCH=$(uname -m)
echo -e "Current architecture: ${YELLOW}${ARCH}${NC}"

if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
    echo -e "${YELLOW}Warning: You are not on an ARM64 system.${NC}"
    echo -e "${YELLOW}Cross-compilation will use QEMU emulation and may be slow.${NC}"
    read -p "Continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Step 1: Build the packager container
echo -e "\n${GREEN}Step 1: Building packager container image...${NC}"
docker build --pull -f contrib/docker/Dockerfile.packager.rpi5 -t asterisk-build-rpi5 .

# Step 2: Create output directory
echo -e "\n${GREEN}Step 2: Preparing output directory...${NC}"
mkdir -p out
rm -f out/*.deb

# Step 3: Build the Asterisk DEB package
echo -e "\n${GREEN}Step 3: Building Asterisk DEB package (this may take a while)...${NC}"
docker run -ti \
    -v $(pwd):/application:ro \
    -v $(pwd)/out:/build \
    -w /application asterisk-build-rpi5 \
    /application/contrib/docker/make-package-deb.sh ${VERSION}

# Check if DEB was created
if [ ! -f out/*.deb ]; then
    echo -e "${RED}Error: DEB package was not created!${NC}"
    exit 1
fi

echo -e "${GREEN}DEB package created:${NC}"
ls -lh out/*.deb

# Step 4: Build the runtime container
echo -e "\n${GREEN}Step 4: Building runtime container image...${NC}"
docker build --rm -t asterisk-rpi5:${VERSION} -f contrib/docker/Dockerfile.rpi5 .

# Success message
echo -e "\n${GREEN}=== Build Complete! ===${NC}"
echo -e "\nYou can now run Asterisk with:"
echo -e "${YELLOW}docker run -d --name asterisk --network host asterisk-rpi5:${VERSION}${NC}"
echo -e "\nOr use docker-compose:"
echo -e "${YELLOW}docker-compose -f contrib/docker/docker-compose.rpi5.yml up -d${NC}"
echo -e "\nTo access the Asterisk CLI:"
echo -e "${YELLOW}docker exec -it asterisk asterisk -rvvv${NC}"

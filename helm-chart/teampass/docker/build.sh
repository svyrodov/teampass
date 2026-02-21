#!/bin/bash
# ============================================
# Build script for custom TeamPass Docker image
# ============================================

set -e

# Configuration
IMAGE_NAME="${DOCKER_IMAGE_NAME:-teampass-custom}"
IMAGE_TAG="${DOCKER_IMAGE_TAG:-3.1.6.7-alpine3.21}"
BASE_IMAGE="${BASE_IMAGE:-php:8.3-fpm-alpine3.21}"
REGISTRY="${DOCKER_REGISTRY:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}Building custom TeamPass Docker image${NC}"
echo -e "${GREEN}============================================${NC}"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo -e "${YELLOW}Configuration:${NC}"
echo "  Image name:    ${IMAGE_NAME}"
echo "  Image tag:     ${IMAGE_TAG}"
echo "  Base image:    ${BASE_IMAGE}"
echo "  Registry:      ${REGISTRY:-<none>}"
echo "  Build context: ${SCRIPT_DIR}"
echo ""

# Build the image
echo -e "${YELLOW}Building Docker image...${NC}"
if [ -n "$REGISTRY" ]; then
    FULL_IMAGE_NAME="${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
else
    FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"
fi

docker build \
    --build-arg BASE_IMAGE="${BASE_IMAGE}" \
    -t "${FULL_IMAGE_NAME}" \
    -f Dockerfile \
    .

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}Build completed successfully!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "Image: ${FULL_IMAGE_NAME}"
echo ""
echo "Next steps:"
echo "  1. Test the image:"
echo "     docker run --rm ${FULL_IMAGE_NAME} ps aux | grep php-fpm"
echo ""
echo "  2. Push to registry (if set):"
echo "     docker push ${FULL_IMAGE_NAME}"
echo ""
echo "  3. Update Helm chart values.yaml:"
echo "     image:"
echo "       repository: ${IMAGE_NAME}"
echo "       tag: \"${IMAGE_TAG}\""
echo ""

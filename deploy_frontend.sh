#!/bin/bash
# DropTrack Frontend Production Build Script
# This script builds the frontend for production deployment to S3

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo "DropTrack Frontend Production Build"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo -e "${RED}Error: package.json not found. Please run this script from the frontend directory.${NC}"
    exit 1
fi

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}node_modules not found. Installing dependencies...${NC}"
    npm install
fi

echo -e "${GREEN}Step 1: Cleaning previous build...${NC}"
rm -rf dist/

echo ""
echo -e "${GREEN}Step 2: Copying production environment file...${NC}"
if [ -f ".env.production" ]; then
    cp .env.production .env
    echo -e "${GREEN}✅ Production environment configured${NC}"
else
    echo -e "${RED}Error: .env.production not found!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Step 3: Building production bundle...${NC}"
npm run build

echo ""
echo -e "${GREEN}Step 4: Verifying build...${NC}"
if [ -d "dist" ]; then
    echo -e "${GREEN}✅ Build successful!${NC}"
    echo ""
    echo "Build statistics:"
    du -sh dist/
    echo ""
    echo "Files created:"
    ls -lh dist/
else
    echo -e "${RED}❌ Build failed - dist directory not created${NC}"
    exit 1
fi

echo ""
echo "=========================================="
echo -e "${GREEN}✅ Production Build Complete!${NC}"
echo "=========================================="
echo ""
echo "Build location: $(pwd)/dist"
echo ""
echo "Next steps:"
echo "  1. Test the build locally: npm run preview"
echo "  2. Deploy to S3: ./deploy-to-s3.sh"
echo ""

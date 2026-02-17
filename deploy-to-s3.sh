#!/bin/bash
# DropTrack Frontend S3 Deployment Script
# This script deploys the production build to AWS S3

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
S3_BUCKET="droptrack.com.au"  # Change this to your S3 bucket name
AWS_REGION="ap-southeast-2"
CLOUDFRONT_DISTRIBUTION_ID="E1YBNWUM2D2NMV"  # Optional: Add your CloudFront distribution ID

echo "=========================================="
echo "DropTrack Frontend S3 Deployment"
echo "=========================================="
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed.${NC}"
    echo "Install it with: brew install awscli"
    echo "Or visit: https://aws.amazon.com/cli/"
    exit 1
fi

# Verify .env.production exists and is being used
echo ""
echo -e "${GREEN}Step 0: Verifying environment configuration...${NC}"
if [ ! -f ".env.production" ]; then
    echo -e "${RED}Error: .env.production file not found${NC}"
    echo "This file is required for production builds to load the correct API URL"
    exit 1
fi

# Verify critical production variables are set in .env.production
required_vars=("VITE_API_BASE_URL" "VITE_COGNITO_USER_POOL_ID" "VITE_COGNITO_CLIENT_ID")
missing_vars=()
for var in "${required_vars[@]}"; do
    if ! grep -q "^${var}=" ".env.production"; then
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -gt 0 ]; then
    echo -e "${RED}Error: Missing required variables in .env.production:${NC}"
    for var in "${missing_vars[@]}"; do
        echo "  - $var"
    done
    exit 1
fi

echo -e "${GREEN}✅ .env.production found and validated${NC}"

# Check if build exists
if [ ! -d "dist" ]; then
    echo -e "${YELLOW}Build not found. Running production build...${NC}"
    npm run build  # This now uses --mode production from package.json
fi

echo -e "${GREEN}Step 1: Verifying AWS credentials...${NC}"
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}Error: AWS credentials not configured.${NC}"
    echo "Configure with: aws configure"
    exit 1
fi
echo -e "${GREEN}✅ AWS credentials verified${NC}"

echo ""
echo -e "${GREEN}Step 2: Checking S3 bucket...${NC}"
if ! aws s3 ls "s3://$S3_BUCKET" &> /dev/null; then
    echo -e "${YELLOW}Bucket $S3_BUCKET does not exist. Creating...${NC}"
    aws s3 mb "s3://$S3_BUCKET" --region "$AWS_REGION"
    
    # Configure bucket for static website hosting
    aws s3 website "s3://$S3_BUCKET" \
        --index-document index.html \
        --error-document index.html
    
    # Set bucket policy for public read access
    cat > /tmp/bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$S3_BUCKET/*"
        }
    ]
}
EOF
    
    aws s3api put-bucket-policy \
        --bucket "$S3_BUCKET" \
        --policy file:///tmp/bucket-policy.json
    
    rm /tmp/bucket-policy.json
    
    echo -e "${GREEN}✅ Bucket created and configured${NC}"
else
    echo -e "${GREEN}✅ Bucket exists${NC}"
fi

echo ""
echo -e "${GREEN}Step 3: Uploading files to S3...${NC}"
aws s3 sync dist/ "s3://$S3_BUCKET" \
    --delete \
    --cache-control "public, max-age=31536000" \
    --exclude "index.html" \
    --exclude "*.map"

# Upload index.html with no-cache to ensure updates are immediate
aws s3 cp dist/index.html "s3://$S3_BUCKET/index.html" \
    --cache-control "no-cache, no-store, must-revalidate" \
    --content-type "text/html"

echo -e "${GREEN}✅ Files uploaded successfully${NC}"

echo ""
echo -e "${GREEN}Step 4: Setting CORS configuration...${NC}"
cat > /tmp/cors-config.json << 'EOF'
{
    "CORSRules": [
        {
            "AllowedOrigins": ["*"],
            "AllowedMethods": ["GET", "HEAD"],
            "AllowedHeaders": ["*"],
            "MaxAgeSeconds": 3000
        }
    ]
}
EOF

aws s3api put-bucket-cors \
    --bucket "$S3_BUCKET" \
    --cors-configuration file:///tmp/cors-config.json

rm /tmp/cors-config.json
echo -e "${GREEN}✅ CORS configured${NC}"

# Invalidate CloudFront cache if distribution ID is provided
if [ -n "$CLOUDFRONT_DISTRIBUTION_ID" ]; then
    echo ""
    echo -e "${GREEN}Step 5: Invalidating CloudFront cache...${NC}"
    aws cloudfront create-invalidation \
        --distribution-id "$CLOUDFRONT_DISTRIBUTION_ID" \
        --paths "/*"
    echo -e "${GREEN}✅ CloudFront cache invalidated${NC}"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}✅ Deployment Complete!${NC}"
echo "=========================================="
echo ""
echo "Website URL: http://$S3_BUCKET.s3-website-$AWS_REGION.amazonaws.com"
echo ""
echo "Next steps:"
echo "  1. Test the website at the URL above"
echo "  2. Set up CloudFront for HTTPS and better performance"
echo "  3. Configure a custom domain name"
echo ""

#!/bin/bash
# Production build script for DropVerify Frontend
# This script ensures all prerequisites are met before building

set -e  # Exit on error

echo "🔨 Building DropVerify Frontend for production..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js first."
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed. Please install npm first."
    exit 1
fi

# Check for required environment variables
echo "🔍 Checking environment variables..."
MISSING_VARS=()

if [ -z "$VITE_COGNITO_USER_POOL_ID" ]; then
    MISSING_VARS+=("VITE_COGNITO_USER_POOL_ID")
fi

if [ -z "$VITE_COGNITO_CLIENT_ID" ]; then
    MISSING_VARS+=("VITE_COGNITO_CLIENT_ID")
fi

if [ -z "$VITE_COGNITO_REGION" ]; then
    MISSING_VARS+=("VITE_COGNITO_REGION")
fi

if [ -z "$VITE_API_BASE_URL" ]; then
    MISSING_VARS+=("VITE_API_BASE_URL")
fi

if [ -z "$VITE_GOOGLE_MAPS_API_KEY" ]; then
    MISSING_VARS+=("VITE_GOOGLE_MAPS_API_KEY")
fi

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo "⚠️  Warning: Missing environment variables:"
    for var in "${MISSING_VARS[@]}"; do
        echo "   - $var"
    done
    echo ""
    echo "💡 Tip: Create a .env file or set these variables before building."
    echo "   See env.example for reference."
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Clean previous build
echo "🧹 Cleaning previous build..."
rm -rf dist
rm -rf node_modules/.vite

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Run TypeScript type checking
echo "📝 Type checking..."
if npm run type-check 2>/dev/null || npx tsc --noEmit; then
    echo "✅ Type checking passed"
else
    echo "⚠️  Type checking found errors, but continuing with build..."
fi

# Run linting (non-blocking)
echo "🔍 Linting code..."
if npm run lint; then
    echo "✅ Linting passed"
else
    echo "⚠️  Linting found issues, but continuing with build..."
fi

# Build the application
echo "🏗️  Building application..."
NODE_ENV=production npm run build

# Verify build output
if [ ! -f "dist/index.html" ]; then
    echo "❌ Build failed: index.html not found in dist/"
    exit 1
fi

# Check build size
echo ""
echo "✅ Build completed successfully!"
echo "📦 Output directory: dist/"
echo "📊 Build size:"
du -sh dist/ 2>/dev/null || echo "   (size calculation unavailable)"

# List main files
echo ""
echo "📄 Main build files:"
ls -lh dist/*.html dist/*.js dist/*.css 2>/dev/null | head -10 || echo "   (file listing unavailable)"

echo ""
echo "🎉 Production build is ready!"
echo "💡 Next steps:"
echo "   1. Test the build: npm run preview"
echo "   2. Deploy dist/ to your hosting service"
echo "   3. Ensure all environment variables are set in production"






















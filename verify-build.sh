#!/bin/bash
# Verify production build configuration
# This script checks if the built frontend bundle contains the correct production API URL

set -e

echo "🔍 Verifying production build configuration..."
echo ""

# Check if dist directory exists
if [ ! -d "dist" ]; then
    echo "❌ ERROR: dist/ directory not found. Please run 'npm run build' first."
    exit 1
fi

# Check if built JavaScript files exist
if ! ls dist/assets/*.js >/dev/null 2>&1; then
    echo "❌ ERROR: No JavaScript files found in dist/assets/"
    exit 1
fi

echo "✅ Build directory found"
echo ""

# Check for localhost URLs (should NOT be present in production build)
echo "Checking for localhost URLs (should be absent)..."
if grep -r "localhost:8000" dist/assets/*.js 2>/dev/null; then
    echo ""
    echo "❌ ERROR: localhost:8000 found in build!"
    echo "   This means the build is using the wrong .env file."
    echo "   The frontend will try to connect to localhost instead of production backend."
    echo ""
    echo "   Solution:"
    echo "   1. Ensure .env.production exists with VITE_API_BASE_URL=https://api.droptrack.com.au"
    echo "   2. Rebuild with: npm run build"
    echo "   3. Run this script again to verify"
    exit 1
else
    echo "✅ No localhost URLs found (good!)"
fi

echo ""

# Check for production API URL (should be present)
echo "Checking for production API URL..."
if grep -r "api.droptrack.com.au" dist/assets/*.js 2>/dev/null; then
    echo "✅ Production API URL found in build (https://api.droptrack.com.au)"
else
    echo "⚠️  WARNING: Production API URL not found in build"
    echo "   This might be okay if the API URL is dynamically configured."
    echo "   However, if you're seeing connection issues, verify your .env.production file."
fi

echo ""
echo "=========================================="
echo "✅ Build verification completed!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Test locally: npm run preview"
echo "  2. Deploy to production: ./deploy-to-s3.sh"
echo "  3. Test production deployment at https://droptrack.com.au"

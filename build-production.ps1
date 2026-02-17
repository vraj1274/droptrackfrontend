# Production Build Script for DropVerify Frontend
# This script performs a complete production build with validation

param(
    [Parameter(Mandatory=$false)]
    [switch]$SkipValidation = $false,
    [Parameter(Mandatory=$false)]
    [switch]$SkipTests = $false
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DropTrack Production Build Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if we're in the right directory
if (-not (Test-Path "package.json")) {
    Write-Host "❌ Error: package.json not found. Please run this script from the DropVerify_webfront directory." -ForegroundColor Red
    exit 1
}

# Check Node.js
Write-Host "🔍 Checking prerequisites..." -ForegroundColor Yellow
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Node.js is not installed. Please install Node.js first." -ForegroundColor Red
    exit 1
}

$nodeVersion = node --version
Write-Host "✅ Node.js version: $nodeVersion" -ForegroundColor Green

# Check npm
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Host "❌ npm is not installed. Please install npm first." -ForegroundColor Red
    exit 1
}

$npmVersion = npm --version
Write-Host "✅ npm version: $npmVersion" -ForegroundColor Green

# Production Environment Validation
if (-not $SkipValidation) {
    Write-Host ""
    Write-Host "🔍 Validating production environment..." -ForegroundColor Yellow
    
    $missingVars = @()
    $requiredVars = @(
        "VITE_COGNITO_USER_POOL_ID",
        "VITE_COGNITO_CLIENT_ID",
        "VITE_API_BASE_URL",
        "VITE_GOOGLE_MAPS_API_KEY"
    )
    
    foreach ($var in $requiredVars) {
        $value = [Environment]::GetEnvironmentVariable($var, "Process")
        if ([string]::IsNullOrEmpty($value)) {
            # Check .env file
            if (Test-Path ".env") {
                $envContent = Get-Content ".env" -Raw
                if ($envContent -notmatch "$var\s*=") {
                    $missingVars += $var
                }
            } else {
                $missingVars += $var
            }
        }
    }
    
    if ($missingVars.Count -gt 0) {
        Write-Host ""
        Write-Host "⚠️  Warning: Missing environment variables:" -ForegroundColor Yellow
        foreach ($var in $missingVars) {
            Write-Host "   - $var" -ForegroundColor Yellow
        }
        Write-Host ""
        Write-Host "💡 Tip: Create a .env file or set these variables before building." -ForegroundColor Cyan
        Write-Host "   See env.example for reference." -ForegroundColor Cyan
        Write-Host ""
        $continue = Read-Host "Continue anyway? (y/N)"
        if ($continue -ne "y" -and $continue -ne "Y") {
            exit 1
        }
    } else {
        Write-Host "✅ All required environment variables are set" -ForegroundColor Green
    }
    
    # Validate HTTPS in production URLs
    Write-Host ""
    Write-Host "🔒 Validating HTTPS configuration..." -ForegroundColor Yellow
    if (Test-Path ".env") {
        $envContent = Get-Content ".env" -Raw
        if ($envContent -match "VITE_API_BASE_URL\s*=\s*http://(?!localhost|127\.0\.0\.1)") {
            Write-Host "⚠️  Warning: VITE_API_BASE_URL should use HTTPS in production" -ForegroundColor Yellow
        }
        if ($envContent -match "VITE_COGNITO_REDIRECT_URI\s*=\s*http://(?!localhost|127\.0\.0\.1)") {
            Write-Host "⚠️  Warning: VITE_COGNITO_REDIRECT_URI should use HTTPS in production" -ForegroundColor Yellow
        }
    }
}

# Clean previous build
Write-Host ""
Write-Host "🧹 Cleaning previous build..." -ForegroundColor Yellow
if (Test-Path "dist") {
    Remove-Item -Recurse -Force "dist"
    Write-Host "✅ Removed dist directory" -ForegroundColor Green
}
if (Test-Path "node_modules\.vite") {
    Remove-Item -Recurse -Force "node_modules\.vite"
}

# Install dependencies if needed
if (-not (Test-Path "node_modules")) {
    Write-Host ""
    Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Dependencies installed" -ForegroundColor Green
}

# Type checking
Write-Host ""
Write-Host "📝 Running TypeScript type checking..." -ForegroundColor Yellow
npm run type-check
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Type checking found errors" -ForegroundColor Yellow
    $continue = Read-Host "Continue with build anyway? (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        exit 1
    }
} else {
    Write-Host "✅ Type checking passed" -ForegroundColor Green
}

# Linting (non-blocking)
Write-Host ""
Write-Host "🔍 Running linter..." -ForegroundColor Yellow
npm run lint
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Linting found issues" -ForegroundColor Yellow
    $continue = Read-Host "Continue with build anyway? (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        exit 1
    }
} else {
    Write-Host "✅ Linting passed" -ForegroundColor Green
}

# Build the application
Write-Host ""
Write-Host "🏗️  Building application for production..." -ForegroundColor Yellow
$env:NODE_ENV = "production"
npm run build

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed" -ForegroundColor Red
    exit 1
}

# Verify build output
Write-Host ""
Write-Host "✅ Build completed successfully!" -ForegroundColor Green

if (-not (Test-Path "dist\index.html")) {
    Write-Host "❌ Build failed: index.html not found in dist/" -ForegroundColor Red
    exit 1
}

# Check for PWA files
Write-Host ""
Write-Host "📱 Verifying PWA files..." -ForegroundColor Yellow
$pwaFiles = @("manifest.json", "sw.js")
$missingPWA = @()
foreach ($file in $pwaFiles) {
    if (-not (Test-Path "dist\$file")) {
        $missingPWA += $file
    }
}
if ($missingPWA.Count -gt 0) {
    Write-Host "⚠️  Warning: Missing PWA files: $($missingPWA -join ', ')" -ForegroundColor Yellow
} else {
    Write-Host "✅ PWA files present" -ForegroundColor Green
}

# Build size
Write-Host ""
Write-Host "📊 Build Statistics:" -ForegroundColor Cyan
$distSize = (Get-ChildItem -Path "dist" -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
Write-Host "   Total size: $([math]::Round($distSize, 2)) MB" -ForegroundColor White

# List main files
Write-Host ""
Write-Host "📄 Main build files:" -ForegroundColor Cyan
Get-ChildItem -Path "dist" -File | Select-Object -First 10 Name, @{Name="Size";Expression={"{0:N2} KB" -f ($_.Length / 1KB)}} | Format-Table -AutoSize

Write-Host ""
Write-Host "🎉 Production build is ready!" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Next steps:" -ForegroundColor Cyan
Write-Host "   1. Test the build: npm run preview" -ForegroundColor White
Write-Host "   2. Deploy dist/ to your hosting service (S3, CloudFront, etc.)" -ForegroundColor White
Write-Host "   3. Ensure all environment variables are set in production" -ForegroundColor White
Write-Host "   4. Configure SPA routing (404 → index.html)" -ForegroundColor White
Write-Host "   5. Enable HTTPS and configure security headers" -ForegroundColor White






















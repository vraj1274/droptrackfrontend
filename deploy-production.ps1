# Production Deployment Script for DropVerify Frontend
# This script builds and prepares the application for deployment

param(
    [Parameter(Mandatory=$false)]
    [string]$Environment = "production",
    [Parameter(Mandatory=$false)]
    [switch]$SkipBuild = $false,
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DropTrack Production Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if we're in the right directory
if (-not (Test-Path "package.json")) {
    Write-Host "❌ Error: package.json not found. Please run this script from the DropVerify_webfront directory." -ForegroundColor Red
    exit 1
}

# Build if not skipped
if (-not $SkipBuild) {
    Write-Host "🔨 Running production build..." -ForegroundColor Yellow
    & "$PSScriptRoot\build-production.ps1"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Build failed. Deployment aborted." -ForegroundColor Red
        exit 1
    }
}

# Verify build exists
if (-not (Test-Path "dist")) {
    Write-Host "❌ Error: dist directory not found. Run build first." -ForegroundColor Red
    exit 1
}

# Pre-deployment checks
Write-Host ""
Write-Host "🔍 Pre-deployment validation..." -ForegroundColor Yellow

# Check for required files
$requiredFiles = @("index.html", "manifest.json")
$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (-not (Test-Path "dist\$file")) {
        $missingFiles += $file
    }
}
if ($missingFiles.Count -gt 0) {
    Write-Host "❌ Missing required files: $($missingFiles -join ', ')" -ForegroundColor Red
    exit 1
}

# Check build size (warn if too large)
$distSize = (Get-ChildItem -Path "dist" -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
if ($distSize -gt 50) {
    Write-Host "⚠️  Warning: Build size is large ($([math]::Round($distSize, 2)) MB). Consider optimizing." -ForegroundColor Yellow
}

# Deployment instructions
Write-Host ""
Write-Host "📦 Deployment Instructions:" -ForegroundColor Cyan
Write-Host ""
Write-Host "For AWS S3 + CloudFront:" -ForegroundColor Yellow
Write-Host "   1. Upload dist/ contents to S3 bucket" -ForegroundColor White
Write-Host "   2. Configure S3 bucket:" -ForegroundColor White
Write-Host "      - Static website hosting: Enabled" -ForegroundColor White
Write-Host "      - Index document: index.html" -ForegroundColor White
Write-Host "      - Error document: index.html (for SPA routing)" -ForegroundColor White
Write-Host "   3. Configure CloudFront:" -ForegroundColor White
Write-Host "      - Origin: S3 bucket" -ForegroundColor White
Write-Host "      - Error pages: 403 → /index.html (200)" -ForegroundColor White
Write-Host "      - Error pages: 404 → /index.html (200)" -ForegroundColor White
Write-Host "      - SSL certificate: Required" -ForegroundColor White
Write-Host "      - Security headers: Configure CSP, HSTS, etc." -ForegroundColor White
Write-Host ""
Write-Host "For other platforms:" -ForegroundColor Yellow
Write-Host "   - Ensure SPA routing is configured (all routes → index.html)" -ForegroundColor White
Write-Host "   - Enable HTTPS" -ForegroundColor White
Write-Host "   - Configure security headers" -ForegroundColor White
Write-Host "   - Set environment variables in your hosting platform" -ForegroundColor White

if ($DryRun) {
    Write-Host ""
    Write-Host "🔍 Dry run mode - no actual deployment performed" -ForegroundColor Cyan
    exit 0
}

# Ask for confirmation
Write-Host ""
$confirm = Read-Host "Ready to deploy? This will prepare the dist/ folder for deployment. Continue? (y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Deployment cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "✅ Build is ready for deployment!" -ForegroundColor Green
Write-Host "📁 Deployment directory: $PWD\dist" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next: Upload the contents of dist/ to your hosting service." -ForegroundColor White






















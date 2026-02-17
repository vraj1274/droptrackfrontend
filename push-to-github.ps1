# PowerShell script to push DropVerify_webfront to GitHub
# Repository: https://github.com/poonam-mscit/Dropvverify_webfront1.git

Write-Host "=== Pushing DropVerify_webfront to GitHub ===" -ForegroundColor Cyan
Write-Host ""

# Check if we're in the right directory
if (-not (Test-Path ".git")) {
    Write-Host "Error: Not a git repository. Please run this script from DropVerify_webfront directory." -ForegroundColor Red
    exit 1
}

# Check git status
Write-Host "Checking git status..." -ForegroundColor Yellow
git status

Write-Host ""
Write-Host "Current remotes:" -ForegroundColor Yellow
git remote -v

Write-Host ""
Write-Host "Setting up remote 'poonam'..." -ForegroundColor Yellow
git remote set-url poonam https://github.com/poonam-mscit/Dropvverify_webfront1.git

Write-Host ""
Write-Host "Attempting to push to poonam/main..." -ForegroundColor Yellow
Write-Host "Note: You may be prompted for GitHub credentials." -ForegroundColor Cyan
Write-Host ""

# Try to push
$pushResult = git push poonam main 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Successfully pushed to GitHub!" -ForegroundColor Green
    Write-Host "Repository: https://github.com/poonam-mscit/Dropvverify_webfront1.git" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "❌ Push failed. Possible reasons:" -ForegroundColor Red
    Write-Host "1. Repository doesn't exist yet - Create it at: https://github.com/new" -ForegroundColor Yellow
    Write-Host "2. Authentication required - You'll need to:" -ForegroundColor Yellow
    Write-Host "   a) Create a Personal Access Token at: https://github.com/settings/tokens" -ForegroundColor Yellow
    Write-Host "   b) Use it when prompted for password" -ForegroundColor Yellow
    Write-Host "3. No access to repository - Contact repository owner" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Error details:" -ForegroundColor Red
    Write-Host $pushResult
}


# PowerShell script to build Flutter web app and update docs folder for GitHub Pages
# Usage: .\update-docs.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Flutter Web Docs Update Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Build Flutter web app
Write-Host "Step 1: Building Flutter web app..." -ForegroundColor Yellow
Write-Host "Command: flutter build web --base-href /chat-App/ --release" -ForegroundColor Gray
Write-Host ""

$buildResult = flutter build web --base-href /chat-App/ --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Flutter build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Build completed successfully" -ForegroundColor Green
Write-Host ""

# Step 2: Copy build output to docs folder
Write-Host "Step 2: Copying build output to docs folder..." -ForegroundColor Yellow

if (-not (Test-Path "build\web")) {
    Write-Host "ERROR: build\web directory not found!" -ForegroundColor Red
    exit 1
}

# Create docs folder if it doesn't exist
if (-not (Test-Path "docs")) {
    New-Item -ItemType Directory -Path "docs" | Out-Null
    Write-Host "Created docs folder" -ForegroundColor Gray
}

# Remove existing contents from docs folder
Write-Host "Cleaning docs folder..." -ForegroundColor Gray
Get-ChildItem -Path "docs" -Exclude ".git" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

# Copy build output to docs folder
Write-Host "Copying files from build\web to docs..." -ForegroundColor Gray
Copy-Item -Recurse -Force "build\web\*" "docs\"

Write-Host "✓ Docs folder updated successfully" -ForegroundColor Green
Write-Host ""

# Step 3: Show git status
Write-Host "Step 3: Checking git status..." -ForegroundColor Yellow
Write-Host ""

git status docs

Write-Host ""

# Step 4: Ask user if they want to commit and push
$response = Read-Host "Do you want to commit and push the docs folder to GitHub? (y/n)"

if ($response -eq "y" -or $response -eq "Y" -or $response -eq "yes") {
    Write-Host ""
    Write-Host "Step 4: Committing and pushing to GitHub..." -ForegroundColor Yellow
    
    # Stage docs folder
    git add docs
    
    # Check if there are changes to commit
    $hasChanges = git diff --staged --quiet docs
    if ($LASTEXITCODE -eq 0) {
        Write-Host "No changes to commit in docs folder." -ForegroundColor Yellow
    } else {
        # Commit changes
        $commitMessage = Read-Host "Enter commit message (or press Enter for default)"
        if ([string]::IsNullOrWhiteSpace($commitMessage)) {
            $commitMessage = "Update docs folder with latest web build"
        }
        
        git commit -m $commitMessage
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "ERROR: Git commit failed!" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "✓ Changes committed" -ForegroundColor Green
        
        # Push to GitHub
        Write-Host "Pushing to GitHub..." -ForegroundColor Gray
        git push
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "ERROR: Git push failed!" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "✓ Changes pushed to GitHub successfully" -ForegroundColor Green
    }
} else {
    Write-Host ""
    Write-Host "Skipping commit and push. You can manually commit later with:" -ForegroundColor Yellow
    Write-Host "  git add docs" -ForegroundColor Gray
    Write-Host "  git commit -m 'Update docs folder with latest web build'" -ForegroundColor Gray
    Write-Host "  git push" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Script completed successfully!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan


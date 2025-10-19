# PowerShell Script to Create All DevOps Assignment Files
# Run this from: Desktop\DevOps_Assignment\

Write-Host "Creating DevOps Assignment Project Structure..." -ForegroundColor Green

# Create directories
$dirs = @(
    "terraform",
    "ansible", 
    "docker",
    "django_app\myproject",
    "django_app\myapp",
    "django_app\templates",
    "ci",
    "selenium",
    "scripts"
)

foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "Created: $dir" -ForegroundColor Cyan
    }
}

Write-Host "`nAll directories created!" -ForegroundColor Green
Write-Host "`nNow manually create files in VS Code using the artifacts provided." -ForegroundColor Yellow
Write-Host "Or follow the step-by-step guide below..." -ForegroundColor Yellow
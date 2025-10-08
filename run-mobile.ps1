# MetartPay Mobile App Runner
# This script ensures Flutter commands run from the correct directory
param(
    [Parameter(Position=0)]
    [string]$Command = "run"
)

Write-Host "🚀 MetartPay Mobile App Runner" -ForegroundColor Cyan
Write-Host "Navigating to mobile directory..." -ForegroundColor Yellow

# Navigate to mobile directory
Set-Location -Path (Join-Path $PSScriptRoot "mobile")

# Verify we're in the right place
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "❌ Error: pubspec.yaml not found. Not in Flutter project directory." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Found pubspec.yaml - we're in the right directory!" -ForegroundColor Green
Write-Host "Current directory: $(Get-Location)" -ForegroundColor White

switch ($Command.ToLower()) {
    "run" {
        Write-Host "🎯 Running Flutter app..." -ForegroundColor Green
        flutter run
    }
    "clean" {
        Write-Host "🧹 Cleaning Flutter project..." -ForegroundColor Yellow
        flutter clean
        flutter pub get
    }
    "build" {
        Write-Host "🔨 Building Flutter app..." -ForegroundColor Blue
        flutter build apk
    }
    "debug" {
        Write-Host "🐛 Running Flutter app in debug mode..." -ForegroundColor Magenta
        flutter run --debug --verbose
    }
    "get" {
        Write-Host "📦 Getting Flutter dependencies..." -ForegroundColor Cyan
        flutter pub get
    }
    "upgrade" {
        Write-Host "⬆️ Upgrading Flutter dependencies..." -ForegroundColor Green
        flutter pub upgrade
    }
    "test" {
        Write-Host "🧪 Running Flutter tests..." -ForegroundColor Yellow
        flutter test
    }
    default {
        Write-Host "🤖 Running custom Flutter command: $Command" -ForegroundColor White
        Invoke-Expression "flutter $Command"
    }
}

Write-Host "✨ Command completed!" -ForegroundColor Green
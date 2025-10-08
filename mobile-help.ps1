# MetartPay Development Commands
# Quick commands for common Flutter operations

Write-Host "📱 MetartPay Flutter Commands" -ForegroundColor Cyan
Write-Host "Available commands:" -ForegroundColor White
Write-Host ""
Write-Host "  .\run-mobile.ps1 run       - Run the Flutter app" -ForegroundColor Green
Write-Host "  .\run-mobile.ps1 clean     - Clean and get dependencies" -ForegroundColor Yellow
Write-Host "  .\run-mobile.ps1 build     - Build APK" -ForegroundColor Blue
Write-Host "  .\run-mobile.ps1 debug     - Run with verbose debugging" -ForegroundColor Magenta
Write-Host "  .\run-mobile.ps1 get       - Get dependencies only" -ForegroundColor Cyan
Write-Host "  .\run-mobile.ps1 test      - Run tests" -ForegroundColor Yellow
Write-Host ""
Write-Host "Examples:" -ForegroundColor White
Write-Host "  .\run-mobile.ps1           # Runs the app (default)" -ForegroundColor Gray
Write-Host "  .\run-mobile.ps1 clean     # Cleans project" -ForegroundColor Gray
Write-Host "  .\run-mobile.ps1 'pub outdated'  # Custom command" -ForegroundColor Gray
Write-Host ""
Write-Host "💡 This ensures commands always run from the mobile/ directory!" -ForegroundColor Yellow
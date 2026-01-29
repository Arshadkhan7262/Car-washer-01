# Admin Panel Startup Script
Write-Host "🚀 Starting Admin Panel..." -ForegroundColor Cyan
Write-Host "📍 Directory: $PWD" -ForegroundColor Gray

# Check if node_modules exists
if (-not (Test-Path "node_modules")) {
    Write-Host "❌ node_modules not found. Installing dependencies..." -ForegroundColor Yellow
    npm install
}

# Get WiFi IP
$wifiIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
    $_.InterfaceAlias -like "*Wi-Fi*" -and 
    $_.IPAddress -notlike "169.254.*" 
} | Select-Object -First 1).IPAddress

if ($wifiIP) {
    Write-Host "`n🌐 Your WiFi IP: $wifiIP" -ForegroundColor Green
    Write-Host "📍 Admin Panel will be available at:" -ForegroundColor Cyan
    Write-Host "   Local:  http://localhost:3001" -ForegroundColor White
    Write-Host "   Network: http://$wifiIP:3001" -ForegroundColor White
    Write-Host "`n💡 Press Ctrl+C to stop the server`n" -ForegroundColor Yellow
} else {
    Write-Host "⚠️  Could not detect WiFi IP" -ForegroundColor Yellow
    Write-Host "📍 Admin Panel will be available at: http://localhost:3001" -ForegroundColor Cyan
}

# Start the server
npm run dev













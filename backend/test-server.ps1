# Backend Server Diagnostic Script
# This script helps diagnose why the server might not be starting

Write-Host "`n🔍 Backend Server Diagnostic`n" -ForegroundColor Cyan

# Check if we're in the backend directory
if (-not (Test-Path "server.js")) {
    Write-Host "❌ Error: server.js not found!" -ForegroundColor Red
    Write-Host "   Please run this script from the backend directory" -ForegroundColor Yellow
    exit 1
}

# Check Node.js
Write-Host "1. Checking Node.js..." -ForegroundColor Yellow
$nodeVersion = node --version 2>$null
if ($nodeVersion) {
    Write-Host "   ✅ Node.js: $nodeVersion" -ForegroundColor Green
} else {
    Write-Host "   ❌ Node.js not found!" -ForegroundColor Red
    exit 1
}

# Check .env file
Write-Host "`n2. Checking .env file..." -ForegroundColor Yellow
if (Test-Path ".env") {
    Write-Host "   ✅ .env file exists" -ForegroundColor Green
    $port = (Get-Content .env | Select-String "^PORT=").ToString().Split("=")[1]
    Write-Host "   📌 Port: $port" -ForegroundColor Cyan
} else {
    Write-Host "   ❌ .env file not found!" -ForegroundColor Red
    exit 1
}

# Check node_modules
Write-Host "`n3. Checking dependencies..." -ForegroundColor Yellow
if (Test-Path "node_modules") {
    Write-Host "   ✅ node_modules exists" -ForegroundColor Green
} else {
    Write-Host "   ❌ node_modules not found!" -ForegroundColor Red
    Write-Host "   Run: npm install" -ForegroundColor Yellow
    exit 1
}

# Check if port is in use
Write-Host "`n4. Checking if port $port is available..." -ForegroundColor Yellow
$portInUse = netstat -an | Select-String ":$port.*LISTENING"
if ($portInUse) {
    Write-Host "   ⚠️  Port $port is already in use!" -ForegroundColor Yellow
    Write-Host "   Stopping existing Node processes..." -ForegroundColor Cyan
    Get-Process | Where-Object {$_.ProcessName -eq "node"} | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
} else {
    Write-Host "   ✅ Port $port is available" -ForegroundColor Green
}

# Get local IP
Write-Host "`n5. Your Network IP Address..." -ForegroundColor Yellow
$localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*"} | Select-Object -First 1).IPAddress
if ($localIP) {
    Write-Host "   📍 Local IP: $localIP" -ForegroundColor Cyan
    Write-Host "   💡 Flutter app should use: http://$localIP:$port/api/v1" -ForegroundColor Yellow
} else {
    Write-Host "   ⚠️  Could not find local network IP" -ForegroundColor Yellow
}

# Try to start server
Write-Host "`n6. Starting server..." -ForegroundColor Yellow
Write-Host "   If server fails to start, check the error messages below:`n" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# Start server (this will run in foreground so you can see errors)
node server.js

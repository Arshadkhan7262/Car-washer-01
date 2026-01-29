# Backend Server Startup Script with Diagnostics
# This script checks all prerequisites and starts the server

Write-Host "`n🔍 Backend Server Diagnostics`n" -ForegroundColor Cyan

# Check Node.js
Write-Host "1. Checking Node.js..." -ForegroundColor Yellow
$nodeVersion = node --version 2>$null
if ($nodeVersion) {
    Write-Host "   ✅ Node.js: $nodeVersion" -ForegroundColor Green
} else {
    Write-Host "   ❌ Node.js not found! Please install Node.js" -ForegroundColor Red
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

# Check MongoDB URI
Write-Host "`n3. Checking MongoDB configuration..." -ForegroundColor Yellow
$mongoUri = (Get-Content .env | Select-String "^MONGODB_URI=").ToString()
if ($mongoUri -like "*mongodb+srv://*") {
    Write-Host "   ✅ Using MongoDB Atlas (Cloud)" -ForegroundColor Green
    Write-Host "   ⚠️  Make sure your IP is whitelisted in MongoDB Atlas!" -ForegroundColor Yellow
} elseif ($mongoUri -like "*mongodb://localhost*") {
    Write-Host "   ✅ Using Local MongoDB" -ForegroundColor Green
    Write-Host "   ⚠️  Make sure MongoDB service is running!" -ForegroundColor Yellow
} else {
    Write-Host "   ⚠️  MongoDB URI found but format unclear" -ForegroundColor Yellow
}

# Get current public IP
Write-Host "`n4. Getting your public IP address..." -ForegroundColor Yellow
try {
    $publicIP = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing -TimeoutSec 5).Content
    Write-Host "   📍 Your Public IP: $publicIP" -ForegroundColor Cyan
    Write-Host "   💡 Add this IP to MongoDB Atlas Network Access whitelist" -ForegroundColor Yellow
} catch {
    Write-Host "   ⚠️  Could not fetch public IP" -ForegroundColor Yellow
}

# Get local network IP
Write-Host "`n5. Getting local network IP..." -ForegroundColor Yellow
$localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*"} | Select-Object -First 1).IPAddress
if ($localIP) {
    Write-Host "   📍 Local Network IP: $localIP" -ForegroundColor Cyan
    Write-Host "   💡 Mobile app should use: http://$localIP:3000/api/v1" -ForegroundColor Yellow
} else {
    Write-Host "   ⚠️  Could not find local network IP" -ForegroundColor Yellow
}

# Check firewall
Write-Host "`n6. Checking Windows Firewall..." -ForegroundColor Yellow
$firewallRule = Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*3000*" -or $_.DisplayName -like "*Node*"} | Select-Object -First 1
if ($firewallRule) {
    Write-Host "   ✅ Firewall rule exists for Node.js" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  No specific firewall rule found (Windows may allow by default)" -ForegroundColor Yellow
}

# Check if port is in use
Write-Host "`n7. Checking if port 3000 is available..." -ForegroundColor Yellow
$portInUse = netstat -an | Select-String ":3000.*LISTENING"
if ($portInUse) {
    Write-Host "   ⚠️  Port 3000 is already in use!" -ForegroundColor Yellow
    Write-Host "   💡 Stopping existing Node processes..." -ForegroundColor Cyan
    Get-Process | Where-Object {$_.ProcessName -eq "node"} | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
} else {
    Write-Host "   ✅ Port 3000 is available" -ForegroundColor Green
}

# Start server
Write-Host "`n8. Starting backend server...`n" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

node server.js
















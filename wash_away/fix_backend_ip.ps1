# PowerShell script to automatically find and update backend IP address
# Run this script from the wash_away directory

Write-Host "🔍 Finding your computer's IP address..." -ForegroundColor Cyan

# Get current IP address
$ipAddresses = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
    ($_.InterfaceAlias -like "*Wi-Fi*" -or 
     $_.InterfaceAlias -like "*Ethernet*" -or
     $_.InterfaceAlias -like "*Local Area Connection*") -and 
    $_.IPAddress -notlike "169.254.*" -and
    $_.IPAddress -notlike "127.*"
} | Select-Object IPAddress, InterfaceAlias

if ($ipAddresses.Count -eq 0) {
    Write-Host "❌ Could not find your IP address!" -ForegroundColor Red
    Write-Host "Please manually check your IP using: ipconfig" -ForegroundColor Yellow
    exit 1
}

# Use the first valid IP
$currentIP = $ipAddresses[0].IPAddress
$interface = $ipAddresses[0].InterfaceAlias

Write-Host "✅ Found IP address: $currentIP ($interface)" -ForegroundColor Green
Write-Host ""

# Check if .env file exists
if (-not (Test-Path ".env")) {
    Write-Host "❌ .env file not found!" -ForegroundColor Red
    Write-Host "Creating .env file from template..." -ForegroundColor Yellow
    
    # Create .env file
    @"
# Flutter App Environment Variables
# DO NOT COMMIT THIS FILE TO GIT - Contains sensitive keys

# API Configuration
# For Android Emulator: http://10.0.2.2:3000/api/v1
# For Physical Device: http://YOUR_COMPUTER_IP:3000/api/v1
API_BASE_URL=http://$currentIP:3000/api/v1

# Stripe Configuration
# IMPORTANT: Must match your backend STRIPE_SECRET_KEY account
# Backend uses: STRIPE_SECRET_KEY from backend/.env
# This must be the PUBLISHABLE key from the SAME Stripe account
# Get from: https://dashboard.stripe.com/test/apikeys
STRIPE_PUBLISHABLE_KEY=pk_test_your_publishable_key_here

# Apple Pay Configuration
APPLE_PAY_MERCHANT_IDENTIFIER=merchant.com.washaway.app

# Connection Timeouts (in milliseconds)
CONNECTION_TIMEOUT=60000
RECEIVE_TIMEOUT=60000
"@ | Out-File -FilePath ".env" -Encoding utf8
    
    Write-Host "✅ Created .env file" -ForegroundColor Green
} else {
    # Read existing .env file
    $envContent = Get-Content ".env"
    $updated = $false
    $newContent = @()
    
    foreach ($line in $envContent) {
        if ($line -match "^API_BASE_URL=(.+)") {
            $oldUrl = $matches[1]
            $newUrl = "http://$currentIP:3000/api/v1"
            $newContent += "API_BASE_URL=$newUrl"
            $updated = $true
            Write-Host "📝 Updated API_BASE_URL" -ForegroundColor Yellow
            Write-Host "   Old: $oldUrl" -ForegroundColor Gray
            Write-Host "   New: $newUrl" -ForegroundColor Green
        } else {
            $newContent += $line
        }
    }
    
    if ($updated) {
        $newContent | Set-Content ".env" -Encoding utf8
        Write-Host "✅ .env file updated successfully!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  API_BASE_URL not found in .env file" -ForegroundColor Yellow
        Write-Host "Adding API_BASE_URL to .env..." -ForegroundColor Yellow
        Add-Content ".env" -Value "`nAPI_BASE_URL=http://$currentIP:3000/api/v1" -Encoding utf8
        Write-Host "✅ Added API_BASE_URL to .env file" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ Configuration Updated!" -ForegroundColor Green
Write-Host ""
Write-Host "📱 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Make sure backend server is running:" -ForegroundColor White
Write-Host "      cd ..\backend" -ForegroundColor Gray
Write-Host "      node server.js" -ForegroundColor Gray
Write-Host ""
Write-Host "   2. Verify backend is accessible:" -ForegroundColor White
Write-Host "      Open browser: http://$currentIP:3000/api/v1/health" -ForegroundColor Gray
Write-Host "      Should show: {`"success`":true,`"message`":`"Server is running`"}" -ForegroundColor Gray
Write-Host ""
Write-Host "   3. Restart your Flutter app (hot restart won't reload .env)" -ForegroundColor White
Write-Host ""
Write-Host "🌐 Backend URL: http://$currentIP:3000/api/v1" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

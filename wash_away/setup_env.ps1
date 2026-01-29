# PowerShell script to set up .env file for Flutter app
# Run this script from the wash_away directory

Write-Host "🔧 Setting up .env file for Wash Away Flutter app..." -ForegroundColor Cyan

# Check if .env already exists
if (Test-Path ".env") {
    Write-Host "⚠️  .env file already exists!" -ForegroundColor Yellow
    $overwrite = Read-Host "Do you want to overwrite it? (y/n)"
    if ($overwrite -ne "y" -and $overwrite -ne "Y") {
        Write-Host "❌ Setup cancelled." -ForegroundColor Red
        exit
    }
}

# Copy from example if it exists
if (Test-Path ".env.example") {
    Copy-Item ".env.example" ".env" -Force
    Write-Host "✅ Created .env from .env.example" -ForegroundColor Green
} else {
    Write-Host "⚠️  .env.example not found. Creating new .env file..." -ForegroundColor Yellow
    
    # Create basic .env file
    @"
# Flutter App Environment Variables
# DO NOT COMMIT THIS FILE TO GIT

# API Configuration
# For Android Emulator: http://10.0.2.2:3000/api/v1
# For Physical Device: http://YOUR_COMPUTER_IP:3000/api/v1
API_BASE_URL=http://192.168.18.7:3000/api/v1

# Stripe Configuration
# IMPORTANT: Must match your backend STRIPE_SECRET_KEY account
# Get from: https://dashboard.stripe.com/test/apikeys
STRIPE_PUBLISHABLE_KEY=pk_test_your_publishable_key_here

# Apple Pay Configuration
APPLE_PAY_MERCHANT_IDENTIFIER=merchant.com.washaway.app

# Connection Timeouts (in milliseconds)
CONNECTION_TIMEOUT=60000
RECEIVE_TIMEOUT=60000
"@ | Out-File -FilePath ".env" -Encoding utf8
    
    Write-Host "✅ Created new .env file" -ForegroundColor Green
}

Write-Host ""
Write-Host "📝 Please edit .env file and fill in your values:" -ForegroundColor Cyan
Write-Host "   1. API_BASE_URL - Your backend server URL" -ForegroundColor White
Write-Host "   2. STRIPE_PUBLISHABLE_KEY - Must match backend STRIPE_SECRET_KEY!" -ForegroundColor Yellow
Write-Host "   3. APPLE_PAY_MERCHANT_IDENTIFIER - Your Apple Pay merchant ID" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  CRITICAL: Stripe keys must match!" -ForegroundColor Red
Write-Host "   • Backend uses: STRIPE_SECRET_KEY from backend/.env" -ForegroundColor White
Write-Host "   • Frontend uses: STRIPE_PUBLISHABLE_KEY from wash_away/.env" -ForegroundColor White
Write-Host "   • Both must be from the SAME Stripe account!" -ForegroundColor White
Write-Host ""
Write-Host "📖 See README_ENV.md for detailed instructions" -ForegroundColor Cyan
Write-Host ""


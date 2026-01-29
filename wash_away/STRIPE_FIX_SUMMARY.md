# Stripe Payment Intent Fix - Complete Solution

## Problem Summary

The app was experiencing "No such payment_intent" errors repeatedly because:
1. **Stripe keys were hardcoded** in `constants.dart`
2. **No validation** to ensure keys match between backend and frontend
3. **Multiple payment intents** were being created on retry, causing conflicts
4. **No clear error messages** to help diagnose the issue

## Solution Implemented

### 1. ✅ Added .env File Support

- Added `flutter_dotenv` package
- Created `EnvConfig` class to load configuration from `.env`
- Updated `AppConstants` to use `.env` values
- Created `.env.example` template file

### 2. ✅ Fixed Payment Intent Retry Logic

- **Removed** logic that creates new payment intents on retry
- **Added** retry with same payment intent (waits longer)
- **Improved** error messages to indicate Stripe key mismatch
- **Added** validation before creating payment intents

### 3. ✅ Added Stripe Key Validation

- Validates Stripe publishable key format
- Checks if key is properly configured
- Provides helpful error messages
- Shows key ID to help match with backend

### 4. ✅ Improved Error Messages

- Clear messages about Stripe key mismatch
- Instructions on how to fix the issue
- References to setup documentation

## Setup Instructions

### Step 1: Install Dependencies

```bash
cd wash_away
flutter pub get
```

### Step 2: Create .env File

**Option A: Use setup script (Windows PowerShell)**
```powershell
cd wash_away
.\setup_env.ps1
```

**Option B: Manual setup**
```bash
# Copy example file
cp .env.example .env
# Or on Windows:
Copy-Item .env.example .env
```

### Step 3: Configure Stripe Keys (CRITICAL!)

1. **Check your backend `.env`** (in `backend/.env`):
   ```env
   STRIPE_SECRET_KEY=sk_test_...your_secret_key...
   ```

2. **Get matching publishable key**:
   - Go to: https://dashboard.stripe.com/test/apikeys
   - Find the publishable key that matches your secret key
   - The key ID (middle part) should match!

3. **Update Flutter `.env`** (in `wash_away/.env`):
   ```env
   STRIPE_PUBLISHABLE_KEY=pk_test_...your_publishable_key...
   ```

### Step 4: Verify Configuration

Restart the app. You should see:
```
✅ Environment variables loaded from .env
✅ Stripe publishable key validated
   Mode: TEST
   Key ID: 51SrHGn3TRO...
   ⚠️  Ensure backend STRIPE_SECRET_KEY matches this account!
   Backend key should start with: sk_test_51SrHGn3TRO...
✅ Stripe initialized successfully
```

## How to Verify Keys Match

### Method 1: Check Key ID

Both keys should have the same middle part (key ID):

- **Backend**: `sk_test_...` (secret key)
- **Frontend**: `pk_test_...` (publishable key)

The long middle part (key ID) must be identical in both keys. Check in Stripe Dashboard → Developers → API keys.

### Method 2: Stripe Dashboard

1. Go to https://dashboard.stripe.com/test/apikeys
2. Find your secret key in the list
3. The publishable key shown next to it is the matching one
4. Copy that publishable key to your Flutter `.env`

## Files Changed

1. **pubspec.yaml** - Added `flutter_dotenv` package
2. **lib/config/env_config.dart** - New file for loading .env
3. **lib/util/constants.dart** - Updated to use .env values
4. **lib/main.dart** - Added .env initialization
5. **lib/services/stripe_payment_service.dart** - Fixed retry logic, added validation
6. **.env.example** - Template file (create this manually)
7. **ENV_SETUP.md** - Setup guide
8. **README_ENV.md** - Detailed instructions

## Testing

After setup:

1. **Start the app** - Check console for Stripe initialization messages
2. **Try a payment** - Should work without "No such payment_intent" errors
3. **If errors persist** - Check that keys match (see verification above)

## Common Issues

### Issue: "Stripe publishable key not found"
**Solution**: Make sure `.env` file exists and has `STRIPE_PUBLISHABLE_KEY` set

### Issue: "Payment intent not found" still occurs
**Solution**: 
1. Verify keys match (see "How to Verify Keys Match" above)
2. Check both keys are test OR both are live (don't mix!)
3. Restart both backend and Flutter app after changing keys

### Issue: ".env file not loading"
**Solution**:
1. Make sure `.env` is in `wash_away/` directory (not `wash_away/lib/`)
2. Check `pubspec.yaml` includes `.env` in assets
3. Run `flutter pub get` again
4. Restart the app

## Next Steps

1. ✅ Create `.env` file from `.env.example`
2. ✅ Add your Stripe publishable key (must match backend!)
3. ✅ Configure API_BASE_URL for your setup
4. ✅ Restart the app
5. ✅ Test payment flow

## Support

If issues persist:
1. Check `ENV_SETUP.md` for detailed setup instructions
2. Verify Stripe keys match between backend and frontend
3. Check console logs for specific error messages
4. Ensure `.env` file is properly formatted (no extra spaces/quotes)


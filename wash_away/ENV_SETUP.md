# Environment Variables Setup Guide

This app now uses `.env` file for configuration instead of hardcoded values.

## Quick Setup

### 1. Install Dependencies

```bash
cd wash_away
flutter pub get
```

### 2. Create `.env` File

Copy the example file and fill in your values:

```bash
# On Windows (PowerShell)
Copy-Item .env.example .env

# On Mac/Linux
cp .env.example .env
```

### 3. Configure Your `.env` File

Open `.env` and update the following values:

```env
# API Configuration
# For Android Emulator: http://10.0.2.2:3000/api/v1
# For Physical Device: http://YOUR_COMPUTER_IP:3000/api/v1
API_BASE_URL=http://192.168.18.7:3000/api/v1

# Stripe Configuration
# IMPORTANT: Must match your backend STRIPE_SECRET_KEY account
# Backend uses: STRIPE_SECRET_KEY from backend/.env
# This must be the PUBLISHABLE key from the SAME Stripe account
STRIPE_PUBLISHABLE_KEY=pk_test_your_key_here

# Apple Pay Configuration
APPLE_PAY_MERCHANT_IDENTIFIER=merchant.com.washaway.app
```

## Critical: Stripe Key Matching

**The payment intent errors occur when Stripe keys don't match!**

### How to Fix:

1. **Check Backend `.env`** (in `backend/.env`):
   ```env
   STRIPE_SECRET_KEY=sk_test_...
   ```

2. **Get Matching Publishable Key**:
   - Go to https://dashboard.stripe.com/test/apikeys
   - Find the publishable key that matches your secret key
   - It should be from the same account and same mode (test/live)

3. **Update Flutter `.env`** (in `wash_away/.env`):
   ```env
   STRIPE_PUBLISHABLE_KEY=pk_test_...  # Must match backend account!
   ```

4. **Verify Keys Match**:
   - Both keys must be from the same Stripe account
   - Both must be test keys OR both must be live keys (don't mix!)
   - The publishable key must correspond to the secret key

### Example:

**Backend `.env`**:
```env
STRIPE_SECRET_KEY=sk_test_...your_secret_key...
```

**Flutter `.env`** (must match):
```env
STRIPE_PUBLISHABLE_KEY=pk_test_...your_publishable_key...
```

Notice: Both keys must be from the same Stripe account (same key ID in the middle). Get them from https://dashboard.stripe.com/test/apikeys

## Verification

After setting up `.env`, restart your app. You should see:

```
✅ Environment variables loaded from .env
✅ Stripe initialized successfully
   Mode: TEST (or LIVE)
   Key: pk_test_51Sr...
   ⚠️ IMPORTANT: Ensure backend STRIPE_SECRET_KEY matches this account!
```

If you see errors, check:
1. `.env` file exists in `wash_away/` directory
2. Keys are correctly formatted (no extra spaces or quotes)
3. Stripe keys match between backend and frontend
4. You ran `flutter pub get` after adding `flutter_dotenv`

## Troubleshooting

### "Failed to load .env file"
- Make sure `.env` file exists in `wash_away/` directory
- Check that `pubspec.yaml` includes `.env` in assets
- Run `flutter pub get` again

### "Stripe publishable key not found"
- Check `.env` file has `STRIPE_PUBLISHABLE_KEY` set
- Ensure no extra spaces or quotes around the key
- Verify the key format: `pk_test_...` or `pk_live_...`

### "Payment intent not found" errors
- **Most likely cause**: Stripe keys don't match between backend and frontend
- Verify backend `STRIPE_SECRET_KEY` and frontend `STRIPE_PUBLISHABLE_KEY` are from the same Stripe account
- Both must be test keys OR both must be live keys (don't mix!)

## Security Notes

- **Never commit `.env` file to Git** - it contains sensitive keys
- `.env` is already in `.gitignore`
- Use `.env.example` as a template for other developers
- For production, use environment variables or secure key management


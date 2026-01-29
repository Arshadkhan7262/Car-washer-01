# Environment Variables Setup

## Quick Start

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Create `.env` file:**
   ```bash
   # Copy the example file
   cp .env.example .env
   # Or on Windows:
   Copy-Item .env.example .env
   ```

3. **Edit `.env` file** with your actual values (see below)

4. **Restart the app**

## Required Environment Variables

### API Configuration
```env
API_BASE_URL=http://192.168.18.7:3000/api/v1
```
- For Android Emulator: `http://10.0.2.2:3000/api/v1`
- For Physical Device: `http://YOUR_COMPUTER_IP:3000/api/v1`

### Stripe Configuration (CRITICAL!)
```env
STRIPE_PUBLISHABLE_KEY=pk_test_...
```

**⚠️ IMPORTANT: This must match your backend STRIPE_SECRET_KEY!**

#### How to Get Matching Keys:

1. **Check your backend `.env`** (in `backend/.env`):
   ```env
   STRIPE_SECRET_KEY=sk_test_...your_secret_key...
   ```

2. **Go to Stripe Dashboard:**
   - Test keys: https://dashboard.stripe.com/test/apikeys
   - Live keys: https://dashboard.stripe.com/apikeys

3. **Find the publishable key that matches your secret key:**
   - Look for keys from the same account
   - The key ID (middle part) should match
   - Example: If secret key is `sk_test_51Sr...`, publishable should be `pk_test_51Sr...`

4. **Update Flutter `.env`**:
   ```env
   STRIPE_PUBLISHABLE_KEY=pk_test_51SrHGn3TRO6sevNJDFTQKVOjH4kwWqpEFMYYmZblh9UzM2fVGsHJVjEaEddB9L4JiaGBG1dYyTBhjN57sKXC8tjf00NWyusAes
   ```

### Apple Pay Configuration
```env
APPLE_PAY_MERCHANT_IDENTIFIER=merchant.com.washaway.app
```

## Why Payment Intents Fail

The "No such payment_intent" error occurs when:

1. **Stripe keys don't match** (most common)
   - Backend creates payment intent with one account
   - Frontend tries to use it with a different account
   - Solution: Ensure keys match (see above)

2. **Test/Live key mismatch**
   - Backend uses test key, frontend uses live key (or vice versa)
   - Solution: Use test keys for development, live keys for production

3. **Payment intent expired**
   - Payment intents expire after a period
   - Solution: The app now handles this automatically

## Verification

After setup, restart the app. You should see:

```
✅ Environment variables loaded from .env
✅ Stripe initialized successfully
   Mode: TEST
   Key: pk_test_51Sr...
   ⚠️ IMPORTANT: Ensure backend STRIPE_SECRET_KEY matches this account!
```

If you see errors, check:
- `.env` file exists in `wash_away/` directory
- Keys are correctly formatted (no spaces/quotes)
- Stripe keys match between backend and frontend
- You ran `flutter pub get` after adding `flutter_dotenv`

## Troubleshooting

### "Failed to load .env file"
- Make sure `.env` exists in `wash_away/` directory
- Check `pubspec.yaml` includes `.env` in assets
- Run `flutter pub get` again

### "Stripe publishable key not found"
- Check `.env` has `STRIPE_PUBLISHABLE_KEY` set
- No extra spaces or quotes
- Key format: `pk_test_...` or `pk_live_...`

### "Payment intent not found" errors
- **Most likely**: Stripe keys don't match
- Verify backend `STRIPE_SECRET_KEY` and frontend `STRIPE_PUBLISHABLE_KEY` are from same account
- Both must be test OR both must be live (don't mix!)

## Security

- ✅ `.env` is in `.gitignore` (won't be committed)
- ✅ Use `.env.example` as template
- ✅ Never commit actual keys to Git
- ✅ Use test keys for development
- ✅ Use live keys only in production


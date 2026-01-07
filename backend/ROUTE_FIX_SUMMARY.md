# Washer Auth Routes - Fix Summary

## Issues Found

1. **Routes returning 404:**
   - `/washer/auth/login` - Route exists but returns 404
   - `/washer/auth/forgot-password` - Route exists but returns 404

2. **Wrong function being called:**
   - `/washer/auth/register` - Returns phone OTP instead of email registration

3. **User not found:**
   - `/washer/auth/verify-email-otp` - Cannot find washer account

## Root Cause

The server needs to be **restarted** to load the new route definitions. The routes are correctly defined in the code, but the running server is using old cached routes.

## Solution

### Step 1: Restart the Backend Server

```bash
# Stop the current server (Ctrl+C)
# Then restart:
cd backend
npm run dev
```

### Step 2: Verify Routes Are Loaded

After restart, check the server logs. You should see routes being registered.

### Step 3: Test the Routes

Use Postman to test:
1. `POST /washer/auth/register` - Should create email-based account
2. `POST /washer/auth/send-email-otp` - Should send email OTP
3. `POST /washer/auth/verify-email-otp` - Should verify email
4. `POST /washer/auth/login` - Should login (if email verified + active)
5. `POST /washer/auth/forgot-password` - Should send reset OTP
6. `POST /washer/auth/reset-password` - Should reset password

## Route Mappings (Current)

All routes are correctly mapped in `backend/src/routes/washerAuth.routes.js`:

- `POST /washer/auth/register` → `registerWithEmail` ✅
- `POST /washer/auth/login` → `loginWithEmail` ✅
- `POST /washer/auth/send-email-otp` → `requestEmailOTP` ✅
- `POST /washer/auth/verify-email-otp` → `verifyEmailOTP` ✅
- `POST /washer/auth/forgot-password` → `requestPasswordReset` ✅
- `POST /washer/auth/reset-password` → `resetPassword` ✅

## Expected Behavior After Restart

1. **Register** - Creates account with `email_verified=false`, `status=pending`
2. **Send Email OTP** - Sends 4-digit OTP to email (5 min expiry)
3. **Verify Email OTP** - Verifies email, returns tokens if `status=active`, message if `status=pending`
4. **Login** - Requires `email_verified=true` AND `status=active`
5. **Forgot Password** - Sends reset OTP to email
6. **Reset Password** - Resets password with OTP

## If Issues Persist After Restart

1. Check server logs for route registration
2. Verify MongoDB connection
3. Check if User exists in database: `db.users.findOne({ email: "veer27420@gmail.com", role: "washer" })`
4. Verify Washer profile exists: `db.washers.findOne({ email: "veer27420@gmail.com" })`


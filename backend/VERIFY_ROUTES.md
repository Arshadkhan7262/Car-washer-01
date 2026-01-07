# Verify Washer Auth Routes

## ⚠️ IMPORTANT: Restart Server First!

The routes are correctly defined in the code, but the server needs to be **restarted** to load them.

## Steps to Fix

### 1. Stop Current Server
Press `Ctrl+C` in the terminal where the server is running

### 2. Restart Server
```bash
cd backend
npm run dev
```

### 3. Verify Server Started
You should see:
```
✅ MongoDB Connected: localhost
🚀 Server running on port 3000
📍 Environment: development
🌐 API URL: http://localhost:3000/api/v1
```

### 4. Test Routes in Postman

#### Test 1: Register (Email-based)
```
POST http://localhost:3000/api/v1/washer/auth/register
Body:
{
  "email": "veer27420@gmail.com",
  "password": "password123",
  "name": "John Washer",
  "phone": "+1234567890"
}

Expected Response:
{
  "success": true,
  "data": {
    "success": true,
    "message": "Account created successfully. Please verify your email...",
    "email": "veer27420@gmail.com",
    "email_verified": false,
    "status": "pending",
    "nextStep": "verify_email"
  }
}
```

#### Test 2: Send Email OTP
```
POST http://localhost:3000/api/v1/washer/auth/send-email-otp
Body:
{
  "email": "veer27420@gmail.com"
}

Expected Response:
{
  "success": true,
  "data": {
    "email": "veer27420@gmail.com",
    "message": "OTP sent to your email",
    "status": "pending",
    "otp": "1234" (only in dev mode)
  }
}
```

#### Test 3: Verify Email OTP
```
POST http://localhost:3000/api/v1/washer/auth/verify-email-otp
Body:
{
  "email": "veer27420@gmail.com",
  "otp": "1234"
}

Expected Response (if status=pending):
{
  "success": true,
  "data": {
    "success": true,
    "email_verified": true,
    "canLogin": false,
    "status": "pending",
    "message": "Email verified. Waiting for admin approval."
  }
}
```

#### Test 4: Login (After Admin Approval)
```
POST http://localhost:3000/api/v1/washer/auth/login
Body:
{
  "email": "veer27420@gmail.com",
  "password": "password123"
}

Expected Response (if email verified + status active):
{
  "success": true,
  "data": {
    "token": "...",
    "refreshToken": "...",
    "user": {...},
    "washer": {...}
  }
}
```

#### Test 5: Forgot Password
```
POST http://localhost:3000/api/v1/washer/auth/forgot-password
Body:
{
  "email": "veer27420@gmail.com"
}

Expected Response:
{
  "success": true,
  "data": {
    "message": "If an account exists with this email, a password reset link has been sent."
  }
}
```

## Route Status Check

After restart, test each route:

- ✅ `/washer/auth/register` - Should create email account (NOT phone OTP)
- ✅ `/washer/auth/login` - Should work (if email verified + active)
- ✅ `/washer/auth/send-email-otp` - Should send email OTP
- ✅ `/washer/auth/verify-email-otp` - Should verify email
- ✅ `/washer/auth/forgot-password` - Should send reset OTP
- ✅ `/washer/auth/reset-password` - Should reset password

## If Routes Still Don't Work

1. **Check server logs** - Look for route registration messages
2. **Verify MongoDB** - Ensure database is connected
3. **Check User exists** - Query: `db.users.findOne({ email: "veer27420@gmail.com", role: "washer" })`
4. **Clear browser/Postman cache** - Sometimes cached responses cause issues

## Common Issues

### Issue: "Route not found"
**Solution:** Server not restarted - restart the server

### Issue: "Washer account not found"
**Solution:** User doesn't exist - register first, then request OTP

### Issue: Register returns phone OTP
**Solution:** Server using old routes - restart server

### Issue: Login fails with "email not verified"
**Solution:** Request and verify email OTP first

### Issue: Login fails with "pending approval"
**Solution:** Admin must change washer status to "active" in admin panel


# Complete OTP Flow Documentation

## Overview
This document describes the complete email OTP (One-Time Password) flow for washer authentication in the Car Wash Pro platform.

## Flow Diagram

```
┌─────────┐         ┌──────────┐         ┌─────────┐         ┌──────────┐
│ Flutter │         │  Node.js │         │   DB    │         │   SMTP   │
│   App   │         │ Backend  │         │         │         │  Server  │
└────┬────┘         └────┬─────┘         └────┬────┘         └────┬─────┘
     │                   │                      │                    │
     │ 1. Enter Email    │                      │                    │
     │──────────────────>│                      │                    │
     │                   │                      │                    │
     │                   │ 2. Generate 4-digit OTP                  │
     │                   │    (1000-9999)                           │
     │                   │                      │                    │
     │                   │ 3. Save OTP + expiry (10 min)            │
     │                   │─────────────────────>│                    │
     │                   │                      │                    │
     │                   │ 4. Send HTML email via SMTP              │
     │                   │──────────────────────────────────────────>│
     │                   │                      │                    │
     │ 5. OTP sent       │                      │                    │
     │<──────────────────│                      │                    │
     │                   │                      │                    │
     │ 6. User enters OTP│                      │                    │
     │──────────────────>│                      │                    │
     │                   │                      │                    │
     │                   │ 7. Verify OTP from DB                    │
     │                   │<─────────────────────│                    │
     │                   │                      │                    │
     │                   │ 8. Mark email_verified = true             │
     │                   │─────────────────────>│                    │
     │                   │                      │                    │
     │ 9. Login success  │                      │                    │
     │<──────────────────│                      │                    │
```

## Step-by-Step Flow

### Step 1: User Enters Email (Flutter App)
- User enters email address in the app
- App calls: `POST /api/v1/washer/auth/request-email-otp`
- Request body:
  ```json
  {
    "email": "washer@example.com"
  }
  ```

### Step 2: Backend Generates OTP (Node.js)
- Backend generates a 4-digit OTP (1000-9999)
- Code location: `backend/src/services/washerAuth.service.js`
- Function: `generateEmailOTP()`

### Step 3: Save OTP + Expiry in Database
- OTP is saved in User model with expiry time (10 minutes)
- Database field: `user.otp = { code: "1234", expiresAt: Date }`
- Model: `backend/src/models/User.model.js`

### Step 4: Send HTML Email via SMTP
- Email service sends beautiful HTML email with OTP
- Service: `backend/src/services/email.service.js`
- SMTP Configuration:
  - Host: `process.env.SMTP_HOST` (default: smtp.gmail.com)
  - Port: `process.env.SMTP_PORT` (default: 587)
  - User: `process.env.SMTP_USER`
  - Password: `process.env.SMTP_PASSWORD`

### Step 5: User Receives Email
- User receives HTML email with:
  - Car Wash Pro branding
  - 4-digit OTP in large, highlighted box
  - Security warnings
  - Expiry information (10 minutes)

### Step 6: User Enters OTP (Flutter App)
- User enters 4-digit OTP in the app
- App calls: `POST /api/v1/washer/auth/verify-email-otp`
- Request body:
  ```json
  {
    "email": "washer@example.com",
    "otp": "1234"
  }
  ```

### Step 7: Backend Verifies OTP
- Backend checks:
  1. OTP exists in database
  2. OTP matches the entered code
  3. OTP is not expired (within 10 minutes)
- If valid, proceed to step 8
- If invalid, return error

### Step 8: Mark Email as Verified ✅
- Set `user.email_verified = true`
- Clear OTP from database: `user.otp = undefined`
- Save user to database
- Generate JWT tokens for authentication

### Step 9: Login Success
- Return JWT tokens (access + refresh)
- Return user and washer data
- App stores tokens and navigates to dashboard

## API Endpoints

### Request Email OTP
```
POST /api/v1/washer/auth/request-email-otp
Content-Type: application/json

{
  "email": "washer@example.com"
}

Response:
{
  "success": true,
  "data": {
    "email": "washer@example.com",
    "message": "OTP sent to your email",
    "status": "pending",
    "otp": "1234" // Only in development mode
  }
}
```

### Verify Email OTP
```
POST /api/v1/washer/auth/verify-email-otp
Content-Type: application/json

{
  "email": "washer@example.com",
  "otp": "1234"
}

Response:
{
  "success": true,
  "data": {
    "token": "jwt_access_token",
    "refreshToken": "jwt_refresh_token",
    "user": {
      "id": "user_id",
      "name": "John Washer",
      "email": "washer@example.com",
      "email_verified": true,
      ...
    },
    "washer": {
      "id": "washer_id",
      "status": "pending",
      ...
    }
}
```

## Environment Variables

Add these to your `.env` file:

```env
# SMTP Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your_email@gmail.com
SMTP_PASSWORD=your_app_password_here
```

### Gmail Setup
1. Enable 2-Step Verification on your Google account
2. Generate an App Password: https://myaccount.google.com/apppasswords
3. Use the app password in `SMTP_PASSWORD`

## Email Templates

### OTP Email Template
- Beautiful HTML design with Car Wash Pro branding
- Large, highlighted OTP code
- Security warnings
- Expiry information
- Responsive design

### Password Reset Email Template
- Similar design to OTP email
- Reset code instead of OTP
- 30-minute expiry

## Security Features

1. **OTP Expiry**: 10 minutes for OTP, 30 minutes for password reset
2. **One-Time Use**: OTP is cleared after successful verification
3. **Email Verification**: `email_verified` flag is set to `true` after OTP verification
4. **Rate Limiting**: Can be added to prevent abuse
5. **No OTP in Production**: OTP is only returned in development mode

## Error Handling

### Common Errors

1. **Account Not Found**
   ```json
   {
     "success": false,
     "message": "Washer account not found. Please register first or contact admin."
   }
   ```

2. **Invalid OTP**
   ```json
   {
     "success": false,
     "message": "Invalid OTP. Please try again."
   }
   ```

3. **Expired OTP**
   ```json
   {
     "success": false,
     "message": "OTP has expired. Please request a new OTP."
   }
   ```

4. **Email Send Failure**
   ```json
   {
     "success": false,
     "message": "Failed to send OTP email. Please try again later."
   }
   ```

## Testing

### Development Mode
- OTP is returned in API response for testing
- Console logs show OTP codes
- Email sending can fail without blocking flow

### Production Mode
- OTP is NOT returned in API response
- Email sending is required
- Errors are properly handled

## Files Modified/Created

1. **Email Service**: `backend/src/services/email.service.js` (NEW)
2. **Washer Auth Service**: `backend/src/services/washerAuth.service.js` (UPDATED)
3. **Routes**: `backend/src/routes/index.routes.js` (UPDATED)
4. **Postman Collection**: `backend/CarWashPro_API_Collection.postman_collection.json` (NEW)

## Next Steps

1. Configure SMTP settings in `.env` file
2. Test email sending with a real email account
3. Import Postman collection for API testing
4. Test complete flow in Flutter app


# Washer Authentication UI Alignment - Complete Changes

## Overview
Updated the Washer authentication system to match the UI flow exactly. All changes ensure email-based OTP authentication with proper restrictions.

---

## ✅ Backend Changes

### 1. OTP Configuration
- **OTP Digits**: Changed from 6 to **4 digits**
- **OTP Expiry**: Changed from 10 minutes to **5 minutes**
- **Location**: `backend/src/services/washerAuth.service.js`

### 2. Registration Flow (`registerWithEmail`)
**Changes:**
- `email_verified` now set to `false` on registration (was `true`)
- Registration **no longer returns tokens**
- Returns success message directing user to verify email
- Washer status set to `pending` (admin must approve)

**Response Format:**
```json
{
  "success": true,
  "email": "user@example.com",
  "email_verified": false,
  "status": "pending",
  "nextStep": "verify_email",
  "message": "Account created. Please verify your email..."
}
```

### 3. Login Restrictions (`loginWithEmail`)
**New Restrictions:**
- ❌ **Cannot login if `email_verified = false`**
- ❌ **Cannot login if `status = pending`**
- ❌ **Cannot login if `status = suspended`**
- ❌ **Cannot login if `status = inactive`**
- ✅ **Can only login if `email_verified = true` AND `status = active`**

**Error Messages:**
- `"Please verify your email before logging in. Check your inbox for the verification OTP."`
- `"Your account is pending admin approval. You cannot login until your account is activated."`

### 4. Email Verification Flow (`verifyEmailOTP`)
**Changes:**
- After OTP verification, checks washer status
- If `status = pending`: Returns message about admin approval (no tokens)
- If `status = active`: Returns tokens for login

**Response Format (Pending):**
```json
{
  "success": true,
  "email_verified": true,
  "canLogin": false,
  "status": "pending",
  "message": "Email verified. Waiting for admin approval."
}
```

**Response Format (Active):**
```json
{
  "success": true,
  "canLogin": true,
  "token": "...",
  "refreshToken": "...",
  "user": {...},
  "washer": {...}
}
```

### 5. Password Reset
- OTP expiry changed to **5 minutes** (was 30 minutes)

### 6. Routes Updated
**New Primary Routes:**
- `POST /washer/auth/register` (was `/register-email`)
- `POST /washer/auth/login` (was `/login-email`)
- `POST /washer/auth/send-email-otp` (was `/request-email-otp`)
- `POST /washer/auth/verify-email-otp` (unchanged)
- `POST /washer/auth/forgot-password` (was `/request-password-reset`)
- `POST /washer/auth/reset-password` (unchanged)

**Legacy routes maintained for backward compatibility**

---

## ✅ Flutter App Changes

### 1. Auth Service (`auth_service.dart`)
**Updated Endpoints:**
- `/washer/auth/login` (was `/login-email`)
- `/washer/auth/register` (was `/register-email`)
- `/washer/auth/forgot-password` (was `/request-password-reset`)

**Registration Response Handling:**
- No longer expects tokens on registration
- Handles `nextStep: "verify_email"` to navigate to OTP screen

**OTP Verification Response Handling:**
- Checks `canLogin` flag
- If `false`: Navigates to dashboard with pending overlay
- If `true`: Saves tokens and navigates to dashboard

### 2. Auth Controller (`auth_controller.dart`)
**Registration Flow:**
- After registration → Navigate to email verification screen
- No longer navigates directly to dashboard

**OTP Verification Flow:**
- Checks `canLogin` flag from response
- Handles pending status appropriately

---

## ✅ Postman Collection Updates

**Updated Collection:**
- `backend/CarWashPro_API_Collection.postman_collection.json`

**New Endpoint Names:**
- All endpoints updated to match new route structure
- Added descriptions explaining the flow
- Numbered steps (1-6) matching UI flow

---

## 🔐 Complete Auth Flow

### Step 1: Register
```
POST /washer/auth/register
Body: { email, password, name, phone }
Response: { success, email, email_verified: false, status: "pending", nextStep: "verify_email" }
```

### Step 2: Send Email OTP
```
POST /washer/auth/send-email-otp
Body: { email }
Response: { success, email, message: "OTP sent", otp: "1234" (dev only) }
```

### Step 3: Verify Email OTP
```
POST /washer/auth/verify-email-otp
Body: { email, otp }
Response (Pending): { success, email_verified: true, canLogin: false, status: "pending" }
Response (Active): { success, canLogin: true, token, refreshToken, user, washer }
```

### Step 4: Login (After Email Verified + Status Active)
```
POST /washer/auth/login
Body: { email, password }
Response: { success, token, refreshToken, user, washer }
```

### Step 5: Forgot Password
```
POST /washer/auth/forgot-password
Body: { email }
Response: { message: "Reset code sent" }
```

### Step 6: Reset Password
```
POST /washer/auth/reset-password
Body: { email, otp, newPassword }
Response: { success, message: "Password reset successfully" }
```

---

## 🚫 Login Restrictions Summary

**Cannot Login If:**
1. ❌ Email not verified (`email_verified = false`)
2. ❌ Status is pending (`status = "pending"`)
3. ❌ Status is suspended (`status = "suspended"`)
4. ❌ Status is inactive (`status = "inactive"`)

**Can Login Only If:**
1. ✅ Email verified (`email_verified = true`)
2. ✅ Status is active (`status = "active"`)

---

## 📝 Database Schema

**User Model:**
- `email_verified`: Boolean (default: false)
- `role`: "washer"
- `is_active`: Boolean
- `is_blocked`: Boolean

**Washer Model:**
- `status`: "pending" | "active" | "suspended" | "inactive"
- `email`: String
- `user_id`: ObjectId (reference to User)

**OTP Storage:**
- Stored in `User.otp` field (temporary)
- `otp.code`: String (4 digits)
- `otp.expiresAt`: Date (5 minutes from creation)

---

## 🔄 Migration Notes

**For Existing Users:**
- Existing washers with `email_verified = true` can still login
- Existing washers with `status = "pending"` cannot login until admin approves
- Admin must change status to `"active"` for login to work

**For New Registrations:**
- All new registrations start with `email_verified = false`
- All new registrations start with `status = "pending"`
- Must verify email via OTP first
- Must wait for admin approval before login

---

## ✅ Testing Checklist

- [x] Registration sets `email_verified = false`
- [x] Registration doesn't return tokens
- [x] OTP is 4 digits
- [x] OTP expires in 5 minutes
- [x] Login requires `email_verified = true`
- [x] Login requires `status = "active"`
- [x] Email verification handles pending status
- [x] Flutter app navigates correctly
- [x] Postman collection updated
- [x] Routes match UI flow

---

## 📚 Files Modified

### Backend
1. `backend/src/services/washerAuth.service.js`
2. `backend/src/routes/washerAuth.routes.js`
3. `backend/src/models/User.model.js` (sparse index fix)
4. `backend/CarWashPro_API_Collection.postman_collection.json`

### Flutter App
1. `car_wash_app/lib/features/auth/services/auth_service.dart`
2. `car_wash_app/lib/features/auth/controllers/auth_controller.dart`

---

## 🎯 Next Steps (Admin Panel)

The Admin Panel should be updated to:
1. Show `email_verified` status for washers
2. Show clear indication when washer cannot login (pending/suspended)
3. Allow admin to change washer status to `active` for approval
4. Display email verification status in washer list

---

## 📞 Support

If issues arise:
1. Check `email_verified` status in database
2. Check `washer.status` in database
3. Verify OTP expiry (5 minutes)
4. Check login restrictions are enforced
5. Verify routes match Postman collection

---

**Last Updated:** $(date)
**Version:** 2.0.0 (UI-Aligned)


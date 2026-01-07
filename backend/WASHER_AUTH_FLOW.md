# Washer Authentication Flow

## Overview
Washers use **email/password authentication** (NO Firebase). The authentication system includes:
- Email/Password Registration
- Email OTP Verification
- Email/Password Login
- Password Reset Flow

**Base URL:** `http://192.168.18.40:3000/api/v1/washer/auth`

---

## 🔐 Authentication Flow

### **Flow 1: Registration & Email Verification**

#### Step 1: Register Account
**Endpoint:** `POST /api/v1/washer/auth/register`

**Request Body:**
```json
{
  "email": "washer@example.com",
  "password": "password123",
  "name": "John Washer",
  "phone": "03286841038"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "message": "Registration successful. Please verify your email.",
    "user": {
      "id": "user_id",
      "email": "washer@example.com",
      "name": "John Washer",
      "phone": "03286841038",
      "email_verified": false,
      "status": "pending"
    }
  }
}
```

**Status After Registration:**
- ✅ User account created
- ❌ Email NOT verified (`email_verified: false`)
- ⏳ Washer status: `pending` (admin approval required)
- ❌ **Cannot login yet** (requires email verification + admin approval)

---

#### Step 2: Request Email OTP
**Endpoint:** `POST /api/v1/washer/auth/send-email-otp`

**Request Body:**
```json
{
  "email": "washer@example.com"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "email": "washer@example.com",
    "message": "OTP sent to your email",
    "status": "pending",
    "otp": "1234"  // Only in development mode
  }
}
```

**OTP Details:**
- 4-digit OTP code
- Expires in 5 minutes
- Sent via email

---

#### Step 3: Verify Email OTP
**Endpoint:** `POST /api/v1/washer/auth/verify-email-otp`

**Request Body:**
```json
{
  "email": "washer@example.com",
  "otp": "1234"
}
```

**Response (200) - If Account is Pending:**
```json
{
  "success": true,
  "data": {
    "email_verified": true,
    "message": "Email verified successfully. Your account is pending admin approval. You will be able to login once your account is activated.",
    "status": "pending",
    "canLogin": false
  }
}
```

**Response (200) - If Account is Active:**
```json
{
  "success": true,
  "data": {
    "token": "jwt_access_token",
    "refreshToken": "jwt_refresh_token",
    "user": { ... },
    "washer": { ... }
  }
}
```

**Status After Email Verification:**
- ✅ Email verified (`email_verified: true`)
- ⏳ Washer status: `pending` (still waiting for admin approval)
- ❌ **Cannot login yet** (admin must approve first)

---

### **Flow 2: Login (After Admin Approval)**

#### Step 1: Login with Email/Password
**Endpoint:** `POST /api/v1/washer/auth/login`

**Request Body:**
```json
{
  "email": "washer@example.com",
  "password": "password123"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "token": "jwt_access_token",
    "refreshToken": "jwt_refresh_token",
    "user": {
      "id": "user_id",
      "name": "John Washer",
      "phone": "03286841038",
      "email": "washer@example.com",
      "role": "washer",
      "email_verified": true,
      "wallet_balance": 0
    },
    "washer": {
      "id": "washer_id",
      "name": "John Washer",
      "status": "active",
      "online_status": false,
      "rating": 0,
      "total_jobs": 0,
      "completed_jobs": 0,
      "wallet_balance": 0,
      "total_earnings": 0
    }
  }
}
```

**Login Requirements:**
- ✅ Email must be verified (`email_verified: true`)
- ✅ Washer status must be `active` (admin approved)
- ✅ Account must not be blocked or inactive
- ✅ Password must be correct

**Error Responses:**

**Email Not Verified (403):**
```json
{
  "success": false,
  "message": "Please verify your email before logging in. Check your inbox for the verification OTP."
}
```

**Account Pending (403):**
```json
{
  "success": false,
  "message": "Your account is pending admin approval. You cannot login until your account is activated."
}
```

**Account Suspended (403):**
```json
{
  "success": false,
  "message": "Your washer account has been suspended. Please contact admin."
}
```

---

### **Flow 3: Password Reset**

#### Step 1: Request Password Reset OTP
**Endpoint:** `POST /api/v1/washer/auth/forgot-password`

**Request Body:**
```json
{
  "email": "washer@example.com"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "email": "washer@example.com",
    "message": "Password reset OTP sent to your email",
    "otp": "1234"  // Only in development mode
  }
}
```

---

#### Step 2: Reset Password with OTP
**Endpoint:** `POST /api/v1/washer/auth/reset-password`

**Request Body:**
```json
{
  "email": "washer@example.com",
  "otp": "1234",
  "newPassword": "newpassword123"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "message": "Password reset successfully"
  }
}
```

---

## 🔑 Protected Routes

### Get Current Washer Profile
**Endpoint:** `GET /api/v1/washer/auth/me`

**Headers:**
```
Authorization: Bearer {access_token}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "user_id",
      "name": "John Washer",
      "phone": "03286841038",
      "email": "washer@example.com",
      "role": "washer",
      "email_verified": true,
      "wallet_balance": 0
    },
    "washer": {
      "id": "washer_id",
      "name": "John Washer",
      "phone": "03286841038",
      "email": "washer@example.com",
      "status": "active",
      "online_status": false,
      "rating": 5.0,
      "total_jobs": 50,
      "completed_jobs": 48,
      "wallet_balance": 5000,
      "total_earnings": 25000
    }
  }
}
```

---

### Refresh Access Token
**Endpoint:** `POST /api/v1/washer/auth/refresh`

**Request Body:**
```json
{
  "refreshToken": "jwt_refresh_token"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "token": "new_jwt_access_token",
    "refreshToken": "new_jwt_refresh_token",
    "user": { ... },
    "washer": { ... }
  }
}
```

---

## 📊 Washer Status Flow

### Status Values:
1. **`pending`** - New registration, waiting for admin approval
2. **`active`** - Approved by admin, can work
3. **`suspended`** - Temporarily blocked by admin
4. **`inactive`** - Deactivated by admin

### Status Transitions:
```
Registration → pending → active → (suspended/inactive)
                              ↓
                         (can login)
```

---

## ✅ Complete Registration-to-Login Flow

```
1. POST /register
   ↓
   Account created (email_verified: false, status: pending)
   ↓
2. POST /send-email-otp
   ↓
   OTP sent to email
   ↓
3. POST /verify-email-otp
   ↓
   Email verified (email_verified: true, status: pending)
   ↓
   [WAIT FOR ADMIN APPROVAL]
   ↓
   Admin approves → status: active
   ↓
4. POST /login
   ↓
   Login successful ✅
```

---

## 🚫 Common Error Scenarios

### 1. Trying to Login Before Email Verification
```json
{
  "success": false,
  "message": "Please verify your email before logging in. Check your inbox for the verification OTP."
}
```

### 2. Trying to Login While Pending Approval
```json
{
  "success": false,
  "message": "Your account is pending admin approval. You cannot login until your account is activated."
}
```

### 3. Invalid Credentials
```json
{
  "success": false,
  "message": "Invalid email or password"
}
```

### 4. Account Blocked
```json
{
  "success": false,
  "message": "Your account has been blocked. Please contact support."
}
```

---

## 📝 Important Notes

1. **No Firebase**: Washers do NOT use Firebase authentication. Only email/password.

2. **Email Verification Required**: Washers must verify their email before they can login.

3. **Admin Approval Required**: Even after email verification, washers cannot login until admin approves their account (status = `active`).

4. **OTP Expiry**: Email OTP expires in 5 minutes.

5. **Password Requirements**: Minimum 6 characters.

6. **Email Normalization**: All emails are stored in lowercase.

7. **Development Mode**: In development, OTP is returned in response. In production, OTP is only sent via email.

---

## 🔄 Alternative Routes (Legacy Support)

- `POST /register-email` → Same as `/register`
- `POST /login-email` → Same as `/login`
- `POST /request-email-otp` → Same as `/send-email-otp`
- `POST /request-password-reset` → Same as `/forgot-password`

---

## 📞 Support

If a washer encounters issues:
1. Check email verification status
2. Check washer status (must be `active`)
3. Verify account is not blocked or inactive
4. Contact admin for account approval




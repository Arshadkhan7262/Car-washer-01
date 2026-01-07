# API Testing Guide - Postman Collection

## 📋 Prerequisites

1. **Backend server must be running**
   ```bash
   cd backend
   npm run dev
   ```
   Server should be running on: `http://localhost:3000`

2. **MongoDB must be running** (local or cloud)

3. **Import Postman Collection**
   - Open Postman
   - Click "Import" → Select `CarWashPro_API_Collection.postman_collection.json`
   - Collection will be imported with all endpoints

4. **Set Collection Variables**
   - In Postman, open the collection
   - Go to "Variables" tab
   - Verify `base_url` is set to: `http://localhost:3000/api/v1`

---

## 🧪 Testing Order (Step-by-Step)

### **Step 1: Health Check** ✅
**Purpose:** Verify server is running

**Endpoint:** `GET /health`

**Expected Response:**
```json
{
  "success": true,
  "message": "Server is running",
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

**✅ If successful:** Server is ready. Proceed to Step 2.

---

### **Step 2: Washer Registration** 📝
**Purpose:** Create a new washer account

**Endpoint:** `POST /washer/auth/register-email`

**Request Body:**
```json
{
  "email": "veer27420@gmail.com",
  "password": "password123",
  "name": "John Washer",
  "phone": "+1234567890"
}
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "refresh_token_here",
    "user": { ... },
    "washer": { ... },
    "message": "Account created successfully. Your account is pending admin approval."
  }
}
```

**⚠️ Important Actions:**
1. **Copy the `token`** from response
2. **Paste it into Postman collection variable:** `washer_token`
   - Collection → Variables → `washer_token` → Paste token value
3. **Copy the `refreshToken`** (if needed for refresh testing)

**✅ If successful:** Account created. Account status will be `pending`. Proceed to Step 3.

**❌ If "Email already registered":**
- The email already exists in database
- You can either:
  - Use a different email, OR
  - Test login with existing credentials (skip to Step 3)

---

### **Step 3: Washer Login** 🔐
**Purpose:** Login with existing credentials

**Endpoint:** `POST /washer/auth/login-email`

**Request Body:**
```json
{
  "email": "veer27420@gmail.com",
  "password": "password123"
}
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "refresh_token_here",
    "user": { ... },
    "washer": {
      "status": "pending" // or "active" if approved
    }
  }
}
```

**⚠️ Important Actions:**
1. **Update `washer_token`** in collection variables with new token
2. **Note the washer `status`**:
   - `pending` = Waiting for admin approval
   - `active` = Approved and can work

**✅ If successful:** Login works. Proceed to Step 4.

---

### **Step 4: Request Email OTP** 📧
**Purpose:** Request OTP for email verification

**Endpoint:** `POST /washer/auth/request-email-otp`

**Request Body:**
```json
{
  "email": "veer27420@gmail.com"
}
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "email": "veer27420@gmail.com",
    "message": "OTP sent to your email",
    "status": "pending",
    "otp": "1234" // Only shown in development mode
  }
}
```

**⚠️ Important Actions:**
1. **Check your email inbox** (`veer27420@gmail.com`)
2. **Look for email from Car Wash Pro** with subject: "Your Email Verification Code"
3. **Copy the 4-digit OTP** from the email (or use the `otp` field if in dev mode)
4. **Note the OTP** - you'll need it for Step 5

**✅ If successful:** OTP sent. Check email. Proceed to Step 5.

**❌ If email not received:**
- Check spam folder
- Verify SMTP configuration in `.env` file
- Check backend console for SMTP errors

---

### **Step 5: Verify Email OTP** ✅
**Purpose:** Verify the OTP received via email

**Endpoint:** `POST /washer/auth/verify-email-otp`

**Request Body:**
```json
{
  "email": "veer27420@gmail.com",
  "otp": "1234" // Use the OTP from email or dev response
}
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "message": "Email verified successfully",
    "email_verified": true,
    "token": "new_token_here",
    "refreshToken": "new_refresh_token_here"
  }
}
```

**⚠️ Important Actions:**
1. **Update `washer_token`** with new token from response
2. **Email is now verified** (`email_verified: true`)

**✅ If successful:** Email verified. Proceed to Step 6.

**❌ If "Invalid OTP" or "OTP expired":**
- OTP expires after 10 minutes
- Request a new OTP (go back to Step 4)

---

### **Step 6: Get Washer Profile** 👤
**Purpose:** Get current washer profile (requires authentication)

**Endpoint:** `GET /washer/auth/me`

**Headers:**
```
Authorization: Bearer {{washer_token}}
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "...",
      "email": "veer27420@gmail.com",
      "name": "John Washer",
      "email_verified": true
    },
    "washer": {
      "id": "...",
      "status": "pending", // or "active"
      "online_status": false
    }
  }
}
```

**✅ If successful:** Authentication works. Token is valid.

**❌ If "Unauthorized" or "Invalid token":**
- Token may have expired
- Re-login (Step 3) to get a new token

---

### **Step 7: Request Password Reset** 🔄
**Purpose:** Request OTP for password reset

**Endpoint:** `POST /washer/auth/request-password-reset`

**Request Body:**
```json
{
  "email": "veer27420@gmail.com"
}
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "email": "veer27420@gmail.com",
    "message": "Password reset OTP sent to your email"
  }
}
```

**⚠️ Important Actions:**
1. **Check email** for password reset OTP
2. **Copy the OTP** from email

**✅ If successful:** Reset OTP sent. Proceed to Step 8.

---

### **Step 8: Reset Password** 🔑
**Purpose:** Reset password using OTP

**Endpoint:** `POST /washer/auth/reset-password`

**Request Body:**
```json
{
  "email": "veer27420@gmail.com",
  "otp": "1234", // OTP from email
  "newPassword": "newpassword123"
}
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "message": "Password reset successfully"
  }
}
```

**✅ If successful:** Password reset. You can now login with new password.

**⚠️ Test the new password:**
- Go back to Step 3 (Login)
- Use new password: `newpassword123`

---

## 🎯 Quick Testing Checklist

- [ ] **Step 1:** Health Check
- [ ] **Step 2:** Register Washer
- [ ] **Step 3:** Login Washer
- [ ] **Step 4:** Request Email OTP
- [ ] **Step 5:** Verify Email OTP
- [ ] **Step 6:** Get Washer Profile
- [ ] **Step 7:** Request Password Reset
- [ ] **Step 8:** Reset Password

---

## 🔧 Troubleshooting

### **Server Not Responding**
- Check if server is running: `npm run dev`
- Verify port 3000 is not in use
- Check MongoDB connection

### **"Email already registered" Error**
- Email exists in database
- Either use different email OR test login instead

### **OTP Not Received**
- Check spam folder
- Verify SMTP settings in `.env`:
  ```env
  SMTP_HOST=smtp.gmail.com
  SMTP_PORT=587
  SMTP_USER=your_email@gmail.com
  SMTP_PASSWORD=your_app_password
  ```
- Check backend console for SMTP errors

### **"Invalid token" or "Unauthorized"**
- Token expired (default: 7 days)
- Re-login to get new token
- Update `washer_token` in collection variables

### **"Washer profile not found"**
- This should be auto-created during registration
- If error occurs, check backend logs
- Ensure `getOrCreateWasherProfile` helper is working

---

## 📝 Notes

1. **Token Management:**
   - Always update `washer_token` after login/register
   - Tokens expire after 7 days (configurable in `.env`)

2. **Email OTP:**
   - OTP expires after 10 minutes
   - In development mode, OTP is returned in API response
   - In production, OTP is only sent via email

3. **Account Status:**
   - New accounts start with `status: "pending"`
   - Admin must approve to change to `status: "active"`
   - Pending accounts can login but may have limited access

4. **Testing Email:**
   - All OTPs will be sent to: `veer27420@gmail.com`
   - Make sure you have access to this email inbox

---

## 🚀 Next Steps After Testing

Once all APIs are tested successfully:

1. **Test in Flutter App:**
   - Use the same email: `veer27420@gmail.com`
   - Test the complete authentication flow in the app

2. **Admin Panel Testing:**
   - Login as admin
   - Approve the washer account (change status from `pending` to `active`)
   - Verify washer can access full features

3. **Integration Testing:**
   - Test complete user journey: Register → Verify Email → Login → Dashboard

---

## 📞 Support

If you encounter issues:
1. Check backend console logs
2. Verify `.env` configuration
3. Check MongoDB connection
4. Review error messages in Postman response

---

**Happy Testing! 🎉**


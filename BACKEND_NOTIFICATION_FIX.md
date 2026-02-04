# Backend Push Notification Fix

## Changes Made

### 1. Fixed Firebase Admin Import
- **File**: `backend/src/services/notification.service.js`
- **Change**: Changed import from `import admin from '../config/firebase.config.js'` to `import admin from 'firebase-admin'`
- **Reason**: The config file exports `firebaseApp`, not `admin`. Admin should be imported directly.

### 2. Added Firebase Config Initialization
- **File**: `backend/server.js`
- **Change**: Added `import './src/config/firebase.config.js'` at the top
- **Reason**: Ensures Firebase Admin SDK is initialized before any services try to use it.

### 3. Enhanced Error Logging
- **File**: `backend/src/services/notification.service.js`
- **Changes**:
  - Added verification that Firebase Admin SDK is initialized
  - Added detailed error logging with error codes
  - Added token preview in logs
  - Added summary logging

### 4. Enhanced Firebase Config Logging
- **File**: `backend/src/config/firebase.config.js`
- **Changes**:
  - Added project ID logging
  - Added credential source logging
  - Added messaging API availability check

## What to Check in Backend

### Step 1: Verify Backend .env File

Check `backend/.env` has ONE of these configurations:

**Option 1: Service Account JSON (Recommended)**
```env
FIREBASE_SERVICE_ACCOUNT_KEY={"type":"service_account","project_id":"upwork-task-8f47c",...}
```

**Option 2: Individual Variables**
```env
FIREBASE_PROJECT_ID=upwork-task-8f47c
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@upwork-task-8f47c.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

### Step 2: Check Backend Startup Logs

When backend starts, you should see:
```
✅ Firebase Admin SDK initialized successfully
📱 [Firebase] Project ID: upwork-task-8f47c
📱 [Firebase] Service Account: Using JSON (or Using env vars)
✅ Firebase Cloud Messaging API is available
```

If you see errors:
- `❌ Firebase Admin SDK initialization error` → Check .env credentials
- `❌ Firebase Cloud Messaging API not available` → Check API is enabled

### Step 3: Test Notification Sending

When assigning a washer, check backend logs for:

**Expected Logs:**
```
📱 [Notification] ==========================================
📱 [Notification] Sending notification to user: 696a58319cbe1a8f53584229
📱 [Notification] Title: Washer Assigned, Body: Ramzan has been assigned to your booking
📱 [Notification] User 696a58319cbe1a8f53584229 (Aryan Ali) has 1 FCM token(s)
📱 [Notification] Token preview: cKOK_TfOQl6cb0sebGNkaa...
📤 [Notification] Attempting to send to token: cKOK_TfOQl6cb0sebGNkaa...
📤 [Notification] Title: Washer Assigned, Body: Ramzan has been assigned...
📤 [Notification] Data payload: {"type":"booking_status","booking_id":"CW-2026-8351",...}
✅ [Notification] Successfully sent! Message ID: projects/upwork-task-8f47c/messages/0:...
📱 [Notification] ==========================================
📱 [Notification] Summary: Sent=1, Failed=0
```

**Error Logs to Watch For:**
```
❌ [Notification] Firebase Admin SDK not initialized!
❌ [Notification] Failed to send notification: [error details]
❌ [Notification] Error code: messaging/invalid-registration-token
❌ [Notification] Error message: [specific error]
```

### Step 4: Common Backend Issues

#### Issue 1: Firebase Admin SDK Not Initialized
**Symptom**: `Firebase Admin SDK not initialized!`
**Fix**: 
1. Check `.env` file exists and has Firebase credentials
2. Verify credentials are valid JSON (if using FIREBASE_SERVICE_ACCOUNT_KEY)
3. Check project ID matches `upwork-task-8f47c`

#### Issue 2: Invalid Registration Token
**Symptom**: `messaging/invalid-registration-token` or `messaging/registration-token-not-registered`
**Fix**:
- Token is automatically removed from database
- User needs to restart app to get new token
- Check if token in database matches current app token

#### Issue 3: Permission Denied
**Symptom**: `messaging/permission-denied`
**Fix**:
- Check service account has "Firebase Cloud Messaging Admin" role
- Verify Cloud Messaging API is enabled
- Check Firebase project ID matches

#### Issue 4: Project Mismatch
**Symptom**: Errors about wrong project
**Fix**:
- Verify `FIREBASE_PROJECT_ID=upwork-task-8f47c` in .env
- Or verify service account JSON has `project_id: "upwork-task-8f47c"`

## Testing Steps

1. **Restart Backend Server**
   ```bash
   cd backend
   npm start
   # or
   node server.js
   ```

2. **Check Startup Logs**
   - Look for Firebase initialization success
   - Verify project ID is correct
   - Check messaging API is available

3. **Assign Washer to Booking**
   - Use admin panel to assign washer
   - Watch backend logs for notification attempts
   - Check for success/error messages

4. **Verify Notification Sent**
   - Backend logs should show "Successfully sent!"
   - Check app receives notification
   - If not received, check app logs for handler errors

## Next Steps

After restarting backend:
1. Check startup logs for Firebase initialization
2. Assign a washer to a booking
3. Check backend logs for detailed notification sending logs
4. Share the logs if notifications still don't work

The enhanced logging will show exactly where the issue is!

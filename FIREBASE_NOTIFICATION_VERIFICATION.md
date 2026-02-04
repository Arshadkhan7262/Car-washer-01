# Firebase Push Notification Configuration Verification

## ✅ Verified Configuration

### 1. Firebase Project Configuration
- **Project ID**: `upwork-task-8f47c` ✅
- **Project Number**: `91468661410` ✅
- **Storage Bucket**: `upwork-task-8f47c.firebasestorage.app` ✅

### 2. Android App Configuration
- **Package Name**: `com.example.wash_away` ✅
- **App ID**: `1:91468661410:android:bafba5ce45004cbcea4dfb` ✅
- **SHA-1 Fingerprint**: `4f:ae:6d:5d:40:79:96:7c:55:61:97:24:5f:71:dc:9b:84:5f:0d:a4` ✅
  - Matches certificate_hash in google-services.json: `4fae6d5d4079967c556197245f71dc9b845f0da4` ✅

### 3. File Locations
- **google-services.json**: `wash_away/android/app/google-services.json` ✅
- **firebase_options.dart**: `wash_away/lib/firebase_options.dart` ✅
- **build.gradle.kts**: `wash_away/android/app/build.gradle.kts` ✅

### 4. Configuration Matches
- ✅ google-services.json App ID matches firebase_options.dart
- ✅ Package name matches in all files
- ✅ SHA-1 fingerprint matches Firebase Console
- ✅ Project ID matches across all configurations

## 🔍 What to Check in Firebase Console

### Step 1: Verify Cloud Messaging API is Enabled
1. Go to: https://console.cloud.google.com/apis/library
2. Search for: "Firebase Cloud Messaging API"
3. Ensure it shows "API enabled" ✅

### Step 2: Verify Service Account Permissions
1. Go to: Firebase Console → Project Settings → Service Accounts
2. Ensure service account has "Firebase Cloud Messaging Admin" role
3. Download service account JSON (if not already done)
4. Verify backend `.env` has:
   ```
   FIREBASE_PROJECT_ID=upwork-task-8f47c
   FIREBASE_SERVICE_ACCOUNT_KEY={...JSON string...}
   ```
   OR
   ```
   FIREBASE_PROJECT_ID=upwork-task-8f47c
   FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@upwork-task-8f47c.iam.gserviceaccount.com
   FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
   ```

### Step 3: Test Notification from Firebase Console
1. Get FCM token from app logs:
   - Look for: `🔑 [FcmTokenController] FCM Token generated: ...`
   - Copy the full token
2. Go to: Firebase Console → Cloud Messaging → Send test message
3. Paste FCM token
4. Enter:
   - Title: `Test Notification`
   - Text: `Testing push notifications`
5. Click "Test"
6. **Expected**: Notification should appear in app

### Step 4: Verify Backend Can Send Notifications
1. Check backend logs when assigning washer
2. Look for: `✅ Sent washer assigned notification to customer`
3. If error appears, check:
   - Firebase Admin SDK initialization
   - Service account credentials
   - FCM token validity

## 🐛 Common Issues & Solutions

### Issue 1: Backend Sends But App Doesn't Receive
**Possible Causes:**
- FCM token mismatch (token in DB ≠ current app token)
- Notification handler not initialized
- App in wrong state (foreground/background/terminated)

**Solution:**
1. Check app logs for FCM token
2. Compare with token in database
3. If mismatch, refresh token on app startup
4. Ensure notification handler is initialized

### Issue 2: Firebase Admin SDK Errors
**Possible Causes:**
- Invalid service account credentials
- Wrong Firebase project ID
- Missing Cloud Messaging API permissions

**Solution:**
1. Verify service account JSON is valid
2. Check FIREBASE_PROJECT_ID matches `upwork-task-8f47c`
3. Ensure service account has proper IAM roles

### Issue 3: Token Invalid/Expired
**Possible Causes:**
- App reinstalled
- Firebase project changed
- Token not refreshed

**Solution:**
1. App automatically refreshes token on startup
2. Backend removes invalid tokens automatically
3. User needs to restart app to get new token

## 📋 Verification Checklist

- [ ] Cloud Messaging API enabled in Google Cloud Console
- [ ] Service account JSON downloaded and configured in backend
- [ ] Backend `.env` has correct Firebase credentials
- [ ] google-services.json is in `android/app/` directory
- [ ] Package name matches: `com.example.wash_away`
- [ ] SHA-1 fingerprint added to Firebase Console
- [ ] App can generate FCM token (check logs)
- [ ] FCM token saved to backend database
- [ ] Test notification from Firebase Console works
- [ ] Backend can send notifications (check logs)
- [ ] App receives test notification from Firebase Console
- [ ] App receives notification when washer assigned

## 🎯 Next Steps

1. **Test from Firebase Console first** - This isolates the issue
   - If works: Problem is in backend notification code or token mismatch
   - If doesn't work: Problem is in Firebase config or app notification handler

2. **Check backend logs** when assigning washer:
   - Look for notification sending attempts
   - Check for errors
   - Verify token is valid

3. **Check app logs** when notification should arrive:
   - Look for `FOREGROUND NOTIFICATION RECEIVED`
   - Look for `BACKGROUND NOTIFICATION RECEIVED`
   - Check for any errors

4. **Verify token match**:
   - Get token from app logs
   - Compare with token in database
   - If mismatch, refresh token

## 🔧 Quick Fixes

### Fix 1: Refresh FCM Token
App already refreshes token on startup in `InitialLoadingScreen`. If still not working:
1. Force app restart
2. Check logs for token refresh
3. Verify token saved to backend

### Fix 2: Reinitialize Notification Handler
Already done in `TrackOrderScreen`. If still not working:
1. Check permission status
2. Verify Firebase initialized
3. Check for initialization errors in logs

### Fix 3: Verify Backend Firebase Config
Check backend `.env` file has:
```
FIREBASE_PROJECT_ID=upwork-task-8f47c
FIREBASE_SERVICE_ACCOUNT_KEY={valid JSON}
```

## 📊 Current Status

Based on configuration files:
- ✅ All Firebase configs match correctly
- ✅ Package name is correct
- ✅ SHA-1 fingerprint matches
- ✅ google-services.json is in correct location
- ✅ firebase_options.dart matches google-services.json

**Most Likely Issue**: 
- Backend Firebase Admin SDK not properly configured
- OR FCM token mismatch between app and database
- OR Cloud Messaging API not enabled

**Recommended Action**: Test notification from Firebase Console first to isolate the issue.

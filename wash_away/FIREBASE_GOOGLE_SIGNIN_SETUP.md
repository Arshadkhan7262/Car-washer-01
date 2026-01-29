# Firebase Google Sign-In Configuration Guide

## Current Issue
Error code 10 (DEVELOPER_ERROR) - Android OAuth client not configured in Firebase.

## Your App Details
- **Package Name:** `com.example.wash_away`
- **SHA-1 Fingerprint:** `4F:AE:6D:5D:40:79:96:7C:55:61:97:24:5F:71:DC:9B:84:5F:0D:A4`
- **Project ID:** `upwork-task-8f47c`
- **Project Number:** `91468661410`

## Steps to Fix

### Step 1: Add SHA-1 to Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **upwork-task-8f47c**
3. Click the gear icon ⚙️ → **Project Settings**
4. Scroll down to **Your apps** section
5. Find your Android app: **com.example.wash_away**
6. Click **Add fingerprint**
7. Paste this SHA-1: `4F:AE:6D:5D:40:79:96:7C:55:61:97:24:5F:71:DC:9B:84:5F:0D:A4`
8. Click **Save**

### Step 2: Download Updated google-services.json
1. After adding SHA-1, Firebase will automatically create an Android OAuth client
2. Click **Download google-services.json** button
3. Replace the file at: `wash_away/android/app/google-services.json`

### Step 3: Verify in Google Cloud Console (Optional)
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: **upwork-task-8f47c**
3. Navigate to: **APIs & Services** → **Credentials**
4. Look for an **OAuth 2.0 Client ID** with:
   - Type: **Android**
   - Package name: `com.example.wash_away`
   - SHA-1: `4F:AE:6D:5D:40:79:96:7C:55:61:97:24:5F:71:DC:9B:84:5F:0D:A4`

### Step 4: Rebuild the App
After updating `google-services.json`, rebuild your app:
```bash
cd wash_away
flutter clean
flutter pub get
flutter run
```

## What Should Be in google-services.json

After adding SHA-1, your `com.example.wash_away` section should have:
```json
{
  "client_info": {
    "mobilesdk_app_id": "1:91468661410:android:bafba5ce45004cbcea4dfb",
    "android_client_info": {
      "package_name": "com.example.wash_away"
    }
  },
  "oauth_client": [
    {
      "client_id": "YOUR_ANDROID_CLIENT_ID.apps.googleusercontent.com",
      "client_type": 1,  // ← This is the Android OAuth client
      "android_info": {
        "package_name": "com.example.wash_away",
        "certificate_hash": "4fae6d5d4079967c556197245f71dc9b845f0da4"  // ← Your SHA-1 (lowercase, no colons)
      }
    },
    {
      "client_id": "YOUR_WEB_CLIENT_ID.apps.googleusercontent.com",
      "client_type": 3  // Web client
    }
  ]
}
```

## Notes
- The SHA-1 in `google-services.json` will be lowercase without colons
- You may need to wait a few minutes after adding SHA-1 for changes to propagate
- Make sure you're using the debug keystore (for development) or add release keystore SHA-1 for production














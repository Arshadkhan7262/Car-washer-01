# How to Download Updated google-services.json

## Steps:

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com/
   - Select project: **upwork-task-8f47c**

2. **Navigate to Project Settings**
   - Click the gear icon ⚙️ (top left)
   - Click **Project Settings**

3. **Find Your Android App**
   - Scroll down to **Your apps** section
   - Find: **com.example.wash_away** (Android app)

4. **Download google-services.json**
   - Click the **google-services.json** download button
   - Or click the **Download** icon next to the app

5. **Replace the File**
   - Save the downloaded file
   - Replace: `wash_away/android/app/google-services.json`
   - Make sure to overwrite the existing file

## What to Verify in the New File:

After downloading, check that the `com.example.wash_away` section has:

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
      "client_id": "SOME_NEW_CLIENT_ID.apps.googleusercontent.com",
      "client_type": 1,  // ← MUST BE 1 (Android OAuth client)
      "android_info": {
        "package_name": "com.example.wash_away",
        "certificate_hash": "4fae6d5d4079967c556197245f71dc9b845f0da4"  // ← Your SHA-1 (lowercase)
      }
    },
    {
      "client_id": "91468661410-57tg402nos5tf94jvc56ckina69tabkb.apps.googleusercontent.com",
      "client_type": 3  // Web client
    }
  ]
}
```

**Key Point:** You should see a `client_type: 1` entry with `android_info` containing your SHA-1 hash.

## After Replacing the File:

1. Clean and rebuild:
   ```bash
   cd wash_away
   flutter clean
   flutter pub get
   flutter run
   ```

2. Test Google Sign-In again














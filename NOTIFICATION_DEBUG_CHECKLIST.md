# Notification Debug Checklist

## Issue: No notification logs in app

Based on your logs, I don't see any notification-related logs. This means either:
1. FCM token isn't registered
2. Notification handler isn't initialized
3. Notifications aren't being received

## What Logs Should Appear

### When App Starts:
```
✅ Firebase initialized successfully
📱 [NotificationHandler] Initializing notification handlers...
📱 [NotificationHandler] Permission status: AuthorizationStatus.authorized
✅ [NotificationHandler] Local notifications initialized
✅ [NotificationHandler] Notification handlers initialized
```

### When User Logs In:
```
🔑 [FcmTokenController] FCM Token generated: [token]...
✅ [FcmTokenController] FCM token saved to backend
✅ [FcmTokenController] Notification handler initialized
```

### When Notification is Received (Foreground):
```
📱 [NotificationHandler] ==========================================
📱 [NotificationHandler] FOREGROUND NOTIFICATION RECEIVED
📱 [NotificationHandler] Message ID: [messageId]
📱 [NotificationHandler] Title: [title]
📱 [NotificationHandler] Body: [body]
📱 [NotificationHandler] Data: [data]
✅ [NotificationHandler] System notification displayed
```

### When Notification is Received (Background):
```
📱 [Background] ==========================================
📱 [Background] BACKGROUND NOTIFICATION RECEIVED
📱 [Background] Message ID: [messageId]
📱 [Background] Title: [title]
📱 [Background] Body: [body]
📱 [Background] Data: [data]
```

## Diagnostic Steps

### Step 1: Check FCM Token Registration
Look for these logs when app starts or user logs in:
- `🔑 [FcmTokenController] FCM Token generated`
- `✅ [FcmTokenController] FCM token saved to backend`

**If missing:** FCM token isn't being registered. Check:
- Notification permission is granted
- User is logged in
- Backend is accessible

### Step 2: Check Notification Handler Initialization
Look for these logs when app starts:
- `📱 [NotificationHandler] Initializing notification handlers...`
- `✅ [NotificationHandler] Notification handlers initialized`

**If missing:** Notification handler isn't initialized. Check:
- Permission is granted
- Firebase is initialized
- No errors in initialization

### Step 3: Check Backend Notification Sending
Look in backend logs for:
- `📱 [Notification] Sending notification to user: [userId]`
- `📤 [Notification] Sending to token: [token]...`
- `✅ [Notification] Successfully sent. Message ID: [messageId]`

**If missing:** Backend isn't sending notifications. Check:
- Backend code is updated
- Backend server restarted
- User has FCM tokens in database

### Step 4: Test Notification Reception
When a notification is sent, you should see:
- **Foreground:** `📱 [NotificationHandler] FOREGROUND NOTIFICATION RECEIVED`
- **Background:** `📱 [Background] BACKGROUND NOTIFICATION RECEIVED`
- **Terminated:** Check when app opens

**If missing:** App isn't receiving notifications. Check:
- FCM token is valid
- Firebase configuration is correct
- Notification handler is initialized

## Quick Fix

1. **Restart the app completely** (not just hot reload)
2. **Login again** to register FCM token
3. **Check logs** for FCM token registration
4. **Test notification** by assigning washer or updating status
5. **Check logs** for notification reception

## Expected Flow

1. App starts → Firebase initialized
2. User logs in → FCM token requested → Token saved to backend
3. Notification handler initialized → Handlers set up
4. Backend sends notification → App receives → Shows notification
5. User taps notification → Navigates to track order screen

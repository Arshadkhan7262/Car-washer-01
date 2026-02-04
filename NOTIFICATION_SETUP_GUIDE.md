# Push Notification Setup Guide

## Issue Fixed: FCM Token Registration

### Problem
Notifications were not being sent to customer app because FCM tokens were not being registered properly. The app was waiting for location permission before requesting notification permission, which could delay or prevent token registration.

### Solution Applied

1. **Fixed FCM Token Initialization** (`wash_away/lib/features/auth/controllers/auth_controller.dart`):
   - Changed from `initializeFcmTokenWithoutPermission()` to `initializeFcmToken()`
   - Now requests notification permission immediately during login/auth flow
   - No longer waits for location permission

2. **Updated HomeController** (`wash_away/lib/controllers/home_controller.dart`):
   - Removed redundant notification permission request
   - Only refreshes FCM token if not already registered

## How Push Notifications Work

### Customer App (wash_away)

1. **FCM Token Registration**:
   - Token is requested immediately after login/registration
   - Saved to backend via `/api/v1/customer/notifications/fcm-token`
   - Token is refreshed automatically when it changes

2. **Notification States**:
   - **Foreground**: Shows system notification using `flutter_local_notifications`
   - **Background**: Handled by `firebaseMessagingBackgroundHandler`
   - **Terminated**: Handled by `getInitialMessage()` when app opens

3. **Navigation**:
   - Tapping notification navigates to `track_order` screen
   - Booking ID is passed in notification data

### Backend Notification Sending

1. **When Admin Assigns Washer**:
   - Customer receives: "Washer Assigned" notification
   - Washer receives: "New Job Assigned" notification

2. **When Washer Updates Status**:
   - Customer receives status update notifications:
     - "Washer Accepted"
     - "Washer On The Way"
     - "Washer Arrived"
     - "Washing Started"
     - "Service Completed"
     - "Booking Cancelled"

## Testing Notifications

### 1. Verify FCM Token Registration

Check app logs for:
```
✅ [FcmTokenController] FCM token saved to backend
```

Check backend logs when user logs in:
```
📱 [Notification] User [userId] has X FCM token(s)
```

### 2. Test Notification Sending

**From Admin Panel:**
1. Assign washer to a booking
2. Check backend logs:
   ```
   ✅ Sent washer assigned notification to customer for booking [bookingId]
   ✅ Sent job assigned notification to washer [washerName] for booking [bookingId]
   ```

**From Washer App:**
1. Update job status (accepted, on_the_way, etc.)
2. Check backend logs:
   ```
   ✅ Sent [status] notification to customer for booking [bookingId]
   ```

### 3. Test Notification Reception

**Foreground State:**
- App is open and visible
- Should show system notification banner
- Tapping should navigate to track order screen

**Background State:**
- App is minimized but running
- Should show notification in system tray
- Tapping should open app and navigate to track order screen

**Terminated State:**
- App is completely closed
- Should show notification in system tray
- Tapping should open app and navigate to track order screen

## Troubleshooting

### Notifications Not Received

1. **Check FCM Token Registration**:
   - Verify token is saved: Check app logs for "FCM token saved to backend"
   - Verify token in database: Check user's `fcm_tokens` array in MongoDB

2. **Check Backend Logs**:
   - Look for: `📱 [Notification] Sending notification to user: [userId]`
   - Check for errors: `❌ Failed to send notification`
   - Verify user has tokens: `⚠️ User has no FCM tokens registered`

3. **Check Firebase Configuration**:
   - Verify Firebase Admin SDK is initialized: `✅ Firebase Admin SDK initialized successfully`
   - Check Firebase service account credentials in `.env`

4. **Check Notification Permission**:
   - Android: Settings > Apps > [App Name] > Notifications
   - Ensure notifications are enabled

5. **Check Notification Channel**:
   - Android requires notification channels
   - Channel ID: `high_importance_channel`
   - Should be created automatically on app start

### Common Issues

1. **"User has no FCM tokens registered"**:
   - User hasn't logged in yet or token registration failed
   - Solution: Ensure user logs in and grants notification permission

2. **"Invalid registration token"**:
   - Token expired or app was reinstalled
   - Solution: Backend automatically removes invalid tokens, user needs to login again

3. **Notifications work in foreground but not background**:
   - Check background message handler is registered
   - Verify `firebaseMessagingBackgroundHandler` is top-level function

4. **Notifications received but navigation doesn't work**:
   - Check notification data payload includes `booking_id` and `screen`
   - Verify GetX context is available when navigating

## Next Steps

1. **Restart Backend**: Apply notification service changes
2. **Reinstall App**: Users need to login again to register FCM tokens
3. **Test Flow**: 
   - Login → Verify token saved
   - Assign washer → Verify notification received
   - Update status → Verify notification received

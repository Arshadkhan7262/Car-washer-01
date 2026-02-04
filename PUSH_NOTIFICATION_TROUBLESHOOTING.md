# Push Notification Troubleshooting Guide

## Issue: Push notifications not working for customer app

### Changes Made

1. **Fixed FCM Token Initialization** (`wash_away/lib/features/auth/controllers/auth_controller.dart`):
   - Now requests notification permission immediately during login
   - Initializes notification handler after FCM token is saved

2. **Updated Notification Handler** (`wash_away/lib/features/notifications/services/notification_handler_service.dart`):
   - Checks permission status instead of requesting again
   - Can be re-initialized if needed

3. **Updated FCM Token Controller** (`wash_away/lib/features/notifications/controllers/fcm_token_controller.dart`):
   - Initializes notification handler after token is saved
   - Ensures handlers are set up to receive notifications

## Testing Steps

### 1. Verify FCM Token Registration

**In Customer App (wash_away):**
- Login to the app
- Check logs for:
  ```
  ✅ [FcmTokenController] FCM token saved to backend
  ✅ [FcmTokenController] Notification handler initialized
  ```

**In Backend:**
- Check logs when user logs in:
  ```
  📱 [Notification] User [userId] has X FCM token(s)
  ```

### 2. Test Notification Sending

**From Admin Panel:**
1. Assign washer to a booking
2. Check backend logs:
   ```
   📱 [Notification] Sending notification to user: [userId]
   📤 [Notification] Sending to token: [token]...
   ✅ [Notification] Successfully sent. Message ID: [messageId]
   ```

**From Washer App:**
1. Update job status (accepted, on_the_way, arrived, in_progress, completed)
2. Check backend logs for notification sending

### 3. Test Notification Reception

**Foreground (App Open):**
- Should see system notification banner
- Check app logs:
  ```
  📱 [NotificationHandler] Foreground notification received
  ✅ [NotificationHandler] System notification shown: [title]
  ```

**Background (App Minimized):**
- Should see notification in system tray
- Tapping should open app and navigate to track order

**Terminated (App Closed):**
- Should see notification in system tray
- Tapping should open app and navigate to track order

## Common Issues & Solutions

### Issue 1: "User has no FCM tokens registered"
**Solution:**
- User needs to login again to register FCM token
- Check notification permission is granted
- Verify token is saved: Check logs for "FCM token saved to backend"

### Issue 2: Notifications not received in foreground
**Solution:**
- Check notification handler is initialized: Look for "Notification handler initialized"
- Verify local notifications plugin is initialized
- Check Android notification channel is created

### Issue 3: Notifications received but not displayed
**Solution:**
- Check notification permission in device settings
- Verify notification channel exists (Android)
- Check app logs for errors in `_showSystemNotification`

### Issue 4: Backend sends but app doesn't receive
**Solution:**
- Verify FCM token is valid (check backend logs for errors)
- Check Firebase configuration
- Verify app is using correct Firebase project

## Debug Commands

### Check FCM Token in Database
```javascript
// In MongoDB
db.users.findOne({_id: ObjectId("userId")}, {fcm_tokens: 1})
```

### Test Notification Manually (Backend)
```javascript
const { sendNotificationToUser } = require('./src/services/notification.service.js');
await sendNotificationToUser(
  'userId',
  'Test Notification',
  'This is a test notification',
  { type: 'test', booking_id: 'test123' }
);
```

## Next Steps

1. **Restart Backend**: Apply notification service changes
2. **Reinstall App**: Users need to login again to register FCM tokens
3. **Test Flow**:
   - Login → Verify token saved
   - Assign washer → Verify notification received
   - Update status → Verify notification received
   - Test in all states (foreground, background, terminated)

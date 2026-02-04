import admin from 'firebase-admin';
import User from '../models/User.model.js';
import Notification from '../models/Notification.model.js';

/**
 * Notification Service
 * Handles sending push notifications via Firebase Cloud Messaging
 */

/**
 * Send notification to a single user by user ID
 * @param {string} userId - User ID
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {Object} data - Additional data payload (optional)
 * @returns {Promise<Object>} Result with success status and message
 */
export const sendNotificationToUser = async (userId, title, body, data = {}) => {
  try {
    console.log(`📱 [Notification] ==========================================`);
    console.log(`📱 [Notification] Sending notification to user: ${userId}`);
    console.log(`📱 [Notification] Title: ${title}, Body: ${body}`);
    
    // Verify Firebase Admin SDK is initialized
    if (!admin.apps || admin.apps.length === 0) {
      console.error('❌ [Notification] Firebase Admin SDK not initialized!');
      throw new Error('Firebase Admin SDK not initialized');
    }
    
    // Find user and get FCM tokens
    const user = await User.findById(userId).select('fcm_tokens name');
    
    if (!user) {
      console.error(`❌ [Notification] User not found: ${userId}`);
      throw new Error('User not found');
    }

    if (!user.fcm_tokens || user.fcm_tokens.length === 0) {
      console.warn(`⚠️ [Notification] User ${userId} (${user.name}) has no FCM tokens registered`);
      return {
        success: false,
        message: 'User has no FCM tokens registered',
        sent: 0,
        failed: 0
      };
    }
    
    console.log(`📱 [Notification] User ${userId} (${user.name}) has ${user.fcm_tokens.length} FCM token(s)`);
    console.log(`📱 [Notification] Token preview: ${user.fcm_tokens[0].token.substring(0, 30)}...`);

    // Prepare notification message
    // IMPORTANT: Firebase Admin SDK requires all data values to be strings
    const dataPayload = {};
    for (const [key, value] of Object.entries(data)) {
      dataPayload[key] = String(value);
    }
    dataPayload.click_action = 'FLUTTER_NOTIFICATION_CLICK';
    // Always include title/body in data so app can show when notification payload is missing (e.g. some Android cases)
    dataPayload.title = String(title);
    dataPayload.body = String(body);
    
    const message = {
      notification: {
        title: title,
        body: body
      },
      data: dataPayload,
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'high_importance_channel'
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1
          }
        }
      }
    };

    // Send to all user's devices
    const results = [];
    let successCount = 0;
    let failCount = 0;

    for (const tokenData of user.fcm_tokens) {
      try {
        console.log(`📤 [Notification] Attempting to send to token: ${tokenData.token.substring(0, 30)}...`);
        console.log(`📤 [Notification] Title: ${title}, Body: ${body}`);
        console.log(`📤 [Notification] Data payload:`, JSON.stringify(dataPayload));
        
        // Verify messaging is available
        if (!admin.messaging) {
          throw new Error('Firebase Admin messaging() is not available');
        }
        
        const messaging = admin.messaging();
        const response = await messaging.send({
          ...message,
          token: tokenData.token
        });
        
        console.log(`✅ [Notification] Successfully sent! Message ID: ${response}`);
        
        results.push({
          token: tokenData.token.substring(0, 20) + '...',
          success: true,
          messageId: response
        });
        successCount++;
      } catch (error) {
        console.error(`❌ [Notification] Failed to send notification:`, error);
        console.error(`❌ [Notification] Error code: ${error.code}, Message: ${error.message}`);
        
        // If token is invalid, remove it from user's tokens
        if (error.code === 'messaging/invalid-registration-token' || 
            error.code === 'messaging/registration-token-not-registered') {
          console.log(`🗑️ [Notification] Removing invalid token: ${tokenData.token.substring(0, 20)}...`);
          // Remove invalid token
          await User.findByIdAndUpdate(userId, {
            $pull: { fcm_tokens: { token: tokenData.token } }
          });
        }
        
        results.push({
          token: tokenData.token.substring(0, 20) + '...',
          success: false,
          error: error.message,
          errorCode: error.code
        });
        failCount++;
        console.log(`📱 [Notification] Failed token reason: ${error.code || 'unknown'} - ${error.message}`);
      }
    }

    console.log(`📱 [Notification] ==========================================`);
    console.log(`📱 [Notification] Summary: Sent=${successCount}, Failed=${failCount}`);
    
    return {
      success: successCount > 0,
      message: `Sent to ${successCount} device(s), failed: ${failCount}`,
      sent: successCount,
      failed: failCount,
      results
    };
  } catch (error) {
    console.error('❌ [Notification] ==========================================');
    console.error('❌ [Notification] Error sending notification to user:', error);
    console.error('❌ [Notification] Error code:', error.code);
    console.error('❌ [Notification] Error message:', error.message);
    console.error('❌ [Notification] Stack:', error.stack);
    console.error('❌ [Notification] ==========================================');
    throw error;
  }
};

/**
 * Send notification to multiple users
 * @param {Array<string>} userIds - Array of user IDs
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {Object} data - Additional data payload (optional)
 * @param {string} adminId - Admin user ID who sent the notification
 * @param {string} targetAudience - Target audience type
 * @returns {Promise<Object>} Result with success status and summary
 */
export const sendNotificationToUsers = async (userIds, title, body, data = {}, adminId = null, targetAudience = 'specific') => {
  try {
    // Create notification record in database
    let notificationRecord = null;
    if (adminId) {
      notificationRecord = new Notification({
        title,
        message: body,
        target_audience: targetAudience,
        user_ids: userIds,
        data,
        sent_by: adminId,
        status: 'sending'
      });
      await notificationRecord.save();
    }

    const results = [];
    let totalSent = 0;
    let totalFailed = 0;
    const sentToUsers = [];

    for (const userId of userIds) {
      try {
        const result = await sendNotificationToUser(userId, title, body, data);
        results.push({
          userId,
          ...result
        });
        totalSent += result.sent || 0;
        totalFailed += result.failed || 0;
        
        // Track which users received the notification
        if (result.sent > 0) {
          sentToUsers.push({
            user_id: userId,
            device_count: result.sent,
            sent_at: new Date()
          });
        }
      } catch (error) {
        results.push({
          userId,
          success: false,
          error: error.message,
          sent: 0,
          failed: 0
        });
        totalFailed++;
      }
    }

    // Update notification record with results
    if (notificationRecord) {
      notificationRecord.status = totalSent > 0 ? 'completed' : 'failed';
      notificationRecord.total_sent = totalSent;
      notificationRecord.total_failed = totalFailed;
      notificationRecord.sent_to = sentToUsers;
      notificationRecord.sent_at = new Date();
      await notificationRecord.save();
    }

    return {
      success: totalSent > 0,
      message: `Sent to ${totalSent} device(s) across ${userIds.length} user(s), failed: ${totalFailed}`,
      totalUsers: userIds.length,
      totalSent,
      totalFailed,
      notificationId: notificationRecord?._id,
      results
    };
  } catch (error) {
    console.error('Error sending notifications to users:', error);
    throw error;
  }
};

/**
 * Send notification to all active customers
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {Object} data - Additional data payload (optional)
 * @param {Object} filters - Additional filters (optional)
 * @param {string} adminId - Admin user ID who sent the notification
 * @param {string} targetAudience - Target audience type
 * @returns {Promise<Object>} Result with success status and summary
 */
export const sendNotificationToAllCustomers = async (title, body, data = {}, filters = {}, adminId = null, targetAudience = 'all') => {
  try {
    // Build query
    const query = {
      role: 'customer',
      is_active: true,
      'fcm_tokens.0': { $exists: true } // Has at least one FCM token
    };

    // Apply filters
    if (filters.activeOnly) {
      // Active customers (logged in within last 30 days)
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      query.lastLogin = { $gte: thirtyDaysAgo };
    }

    if (filters.newOnly) {
      // New customers (created within last 7 days)
      const sevenDaysAgo = new Date();
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
      query.created_date = { $gte: sevenDaysAgo };
    }

    if (filters.inactiveOnly) {
      // Inactive customers (not logged in for 30+ days)
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      query.$or = [
        { lastLogin: { $lt: thirtyDaysAgo } },
        { lastLogin: null }
      ];
    }

    // Get all matching users
    const users = await User.find(query).select('_id');
    const userIds = users.map(user => user._id.toString());

    if (userIds.length === 0) {
      return {
        success: false,
        message: 'No users found matching the criteria',
        totalUsers: 0,
        totalSent: 0,
        totalFailed: 0
      };
    }

    // Send notifications
    return await sendNotificationToUsers(userIds, title, body, data, adminId, targetAudience);
  } catch (error) {
    console.error('Error sending notifications to all customers:', error);
    throw error;
  }
};


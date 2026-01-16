import admin from '../config/firebase.config.js';
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
    // Find user and get FCM tokens
    const user = await User.findById(userId).select('fcm_tokens name');
    
    if (!user) {
      throw new Error('User not found');
    }

    if (!user.fcm_tokens || user.fcm_tokens.length === 0) {
      return {
        success: false,
        message: 'User has no FCM tokens registered',
        sent: 0,
        failed: 0
      };
    }

    // Prepare notification message
    const message = {
      notification: {
        title: title,
        body: body
      },
      data: {
        ...data,
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      },
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
        const response = await admin.messaging().send({
          ...message,
          token: tokenData.token
        });
        
        results.push({
          token: tokenData.token.substring(0, 20) + '...',
          success: true,
          messageId: response
        });
        successCount++;
      } catch (error) {
        // If token is invalid, remove it from user's tokens
        if (error.code === 'messaging/invalid-registration-token' || 
            error.code === 'messaging/registration-token-not-registered') {
          // Remove invalid token
          await User.findByIdAndUpdate(userId, {
            $pull: { fcm_tokens: { token: tokenData.token } }
          });
        }
        
        results.push({
          token: tokenData.token.substring(0, 20) + '...',
          success: false,
          error: error.message
        });
        failCount++;
      }
    }

    return {
      success: successCount > 0,
      message: `Sent to ${successCount} device(s), failed: ${failCount}`,
      sent: successCount,
      failed: failCount,
      results
    };
  } catch (error) {
    console.error('Error sending notification to user:', error);
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


import * as notificationService from '../services/notification.service.js';
import User from '../models/User.model.js';
import Notification from '../models/Notification.model.js';
import mongoose from 'mongoose';

/**
 * Save or update FCM token for washer
 * POST /api/v1/washer/notifications/fcm-token
 */
export const saveFcmToken = async (req, res) => {
  try {
    const { token, device_type } = req.body;
    const washerId = req.washer.id; // User ID from washer token

    if (!token) {
      return res.status(400).json({
        success: false,
        message: 'FCM token is required'
      });
    }

    // Find user
    const user = await User.findById(washerId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Check if token already exists
    const existingTokenIndex = user.fcm_tokens.findIndex(
      t => t.token === token
    );

    if (existingTokenIndex >= 0) {
      // Update existing token
      user.fcm_tokens[existingTokenIndex].device_type = device_type || 'android';
      user.fcm_tokens[existingTokenIndex].updated_at = new Date();
    } else {
      // Add new token
      user.fcm_tokens.push({
        token,
        device_type: device_type || 'android',
        created_at: new Date(),
        updated_at: new Date()
      });
    }

    await user.save();

    return res.status(200).json({
      success: true,
      message: 'FCM token saved successfully',
      data: {
        token_count: user.fcm_tokens.length
      }
    });
  } catch (error) {
    console.error('Error saving FCM token:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to save FCM token'
    });
  }
};

/**
 * Remove FCM token for washer
 * DELETE /api/v1/washer/notifications/fcm-token
 */
export const removeFcmToken = async (req, res) => {
  try {
    const { token } = req.body;
    const washerId = req.washer.id; // User ID from washer token

    const user = await User.findById(washerId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    if (token) {
      // Remove specific token
      user.fcm_tokens = user.fcm_tokens.filter(t => t.token !== token);
    } else {
      // Remove all tokens
      user.fcm_tokens = [];
    }

    await user.save();

    return res.status(200).json({
      success: true,
      message: 'FCM token(s) removed successfully'
    });
  } catch (error) {
    console.error('Error removing FCM token:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to remove FCM token'
    });
  }
};

/**
 * Get all notifications for washer
 * GET /api/v1/washer/notifications
 */
export const getWasherNotifications = async (req, res) => {
  try {
    const { page = 1, limit = 50, sort = '-created_at' } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const washerId = req.washer.id; // User ID from washer token

    // Build query - get notifications sent to this washer
    const query = {
      is_deleted: { $ne: true },
      user_ids: new mongoose.Types.ObjectId(washerId)
    };

    const notifications = await Notification.find(query)
      .sort(sort)
      .skip(skip)
      .limit(parseInt(limit))
      .lean();

    const total = await Notification.countDocuments(query);

    // Check which notifications are read
    const notificationIds = notifications.map(n => n._id);
    const readNotifications = await Notification.find({
      _id: { $in: notificationIds },
      read_by_users: new mongoose.Types.ObjectId(washerId)
    }).select('_id').lean();
    const readIds = new Set(readNotifications.map(n => n._id.toString()));

    // Add is_read flag to each notification
    const notificationsWithReadStatus = notifications.map(notification => ({
      ...notification,
      is_read: readIds.has(notification._id.toString())
    }));

    return res.status(200).json({
      success: true,
      data: {
        notifications: notificationsWithReadStatus,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / parseInt(limit))
        }
      }
    });
  } catch (error) {
    console.error('Error fetching washer notifications:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch notifications'
    });
  }
};

/**
 * Get unread notification count for washer
 * GET /api/v1/washer/notifications/unread-count
 */
export const getWasherUnreadCount = async (req, res) => {
  try {
    const washerId = req.washer.id; // User ID from washer token

    // Get all notifications sent to this washer
    const allNotifications = await Notification.find({
      is_deleted: { $ne: true },
      user_ids: new mongoose.Types.ObjectId(washerId)
    }).select('_id').lean();

    const notificationIds = allNotifications.map(n => n._id);

    // Count read notifications
    const readCount = await Notification.countDocuments({
      _id: { $in: notificationIds },
      read_by_users: new mongoose.Types.ObjectId(washerId)
    });

    const unreadCount = allNotifications.length - readCount;

    return res.status(200).json({
      success: true,
      data: {
        count: unreadCount
      }
    });
  } catch (error) {
    console.error('Error getting unread count:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to get unread count'
    });
  }
};

/**
 * Mark notification as read for washer
 * PUT /api/v1/washer/notifications/:id/read
 */
export const markWasherNotificationAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const washerId = req.washer.id; // User ID from washer token

    if (!id || id === ':id' || !/^[0-9a-fA-F]{24}$/.test(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid notification ID format.'
      });
    }

    const notification = await Notification.findById(id);
    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }

    // Check if notification is for this washer
    const isForWasher = notification.user_ids.some(
      userId => userId.toString() === washerId
    );

    if (!isForWasher) {
      return res.status(403).json({
        success: false,
        message: 'You do not have permission to mark this notification as read'
      });
    }

    // Add washer to read_by_users if not already there
    const washerObjectId = new mongoose.Types.ObjectId(washerId);
    if (!notification.read_by_users.includes(washerObjectId)) {
      notification.read_by_users.push(washerObjectId);
      await notification.save();
    }

    return res.status(200).json({
      success: true,
      message: 'Notification marked as read'
    });
  } catch (error) {
    console.error('Error marking notification as read:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to mark notification as read'
    });
  }
};

/**
 * Mark all notifications as read for washer
 * PUT /api/v1/washer/notifications/read-all
 */
export const markAllWasherNotificationsAsRead = async (req, res) => {
  try {
    const washerId = req.washer.id; // User ID from washer token

    // Get all notifications sent to this washer
    const notifications = await Notification.find({
      is_deleted: { $ne: true },
      user_ids: new mongoose.Types.ObjectId(washerId)
    });

    const washerObjectId = new mongoose.Types.ObjectId(washerId);
    let updatedCount = 0;

    // Update each notification
    for (const notification of notifications) {
      if (!notification.read_by_users.includes(washerObjectId)) {
        notification.read_by_users.push(washerObjectId);
        await notification.save();
        updatedCount++;
      }
    }

    return res.status(200).json({
      success: true,
      message: `Marked ${updatedCount} notification(s) as read`,
      data: {
        updated_count: updatedCount
      }
    });
  } catch (error) {
    console.error('Error marking all notifications as read:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to mark all notifications as read'
    });
  }
};

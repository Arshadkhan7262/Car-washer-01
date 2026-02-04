import mongoose from 'mongoose';
import * as notificationService from '../services/notification.service.js';
import User from '../models/User.model.js';
import Notification from '../models/Notification.model.js';

/**
 * Save or update FCM token for customer
 * POST /api/v1/customer/notifications/fcm-token
 */
export const saveFcmToken = async (req, res) => {
  try {
    const { token, device_type } = req.body;
    const customerId = req.customer.id;

    if (!token) {
      return res.status(400).json({
        success: false,
        message: 'FCM token is required'
      });
    }

    // Find user
    const user = await User.findById(customerId);
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
 * Remove FCM token for customer
 * DELETE /api/v1/customer/notifications/fcm-token
 */
export const removeFcmToken = async (req, res) => {
  try {
    const { token } = req.body;
    const customerId = req.customer.id;

    const user = await User.findById(customerId);
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
 * Save or update FCM token for washer
 * POST /api/v1/washer/notifications/fcm-token
 */
export const saveWasherFcmToken = async (req, res) => {
  try {
    const { token, device_type } = req.body;
    const washerId = req.washer.id;

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
    console.error('Error saving washer FCM token:', error);
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
export const removeWasherFcmToken = async (req, res) => {
  try {
    const { token } = req.body;
    const washerId = req.washer.id;

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
    console.error('Error removing washer FCM token:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to remove FCM token'
    });
  }
};

/**
 * Send notification to users (Admin only)
 * POST /api/v1/admin/notifications/send
 */
export const sendNotification = async (req, res) => {
  try {
    if (mongoose.connection.readyState !== 1) {
      return res.status(503).json({
        success: false,
        message: 'Database is not connected. Please check MongoDB connection and try again.'
      });
    }

    const { target_audience, user_ids, title, message, data } = req.body;
    const adminId = req.admin?._id?.toString() || req.admin?.id;

    if (!title || !message) {
      return res.status(400).json({
        success: false,
        message: 'Title and message are required'
      });
    }

    let result;

    if (target_audience === 'all') {
      // Send Firebase push to all active customers who have at least one FCM token
      result = await notificationService.sendNotificationToAllCustomers(
        title,
        message,
        data || {},
        {},
        adminId,
        'all'
      );
    } else if (target_audience === 'active') {
      // Send to active customers
      result = await notificationService.sendNotificationToAllCustomers(
        title,
        message,
        data || {},
        { activeOnly: true },
        adminId,
        'active'
      );
    } else if (target_audience === 'inactive') {
      // Send to inactive customers
      result = await notificationService.sendNotificationToAllCustomers(
        title,
        message,
        data || {},
        { inactiveOnly: true },
        adminId,
        'inactive'
      );
    } else if (target_audience === 'new') {
      // Send to new customers
      result = await notificationService.sendNotificationToAllCustomers(
        title,
        message,
        data || {},
        { newOnly: true },
        adminId,
        'new'
      );
    } else if (target_audience === 'specific' && user_ids && Array.isArray(user_ids)) {
      // Send to specific users
      result = await notificationService.sendNotificationToUsers(
        user_ids,
        title,
        message,
        data || {},
        adminId,
        'specific'
      );
    } else {
      return res.status(400).json({
        success: false,
        message: 'Invalid target_audience or missing user_ids for specific audience'
      });
    }

    return res.status(200).json({
      success: result.success,
      message: result.message,
      data: result
    });
  } catch (error) {
    console.error('Error sending notification:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to send notification'
    });
  }
};

/**
 * Get all notifications (Admin only)
 * GET /api/v1/admin/notifications
 */
export const getNotifications = async (req, res) => {
  try {
    const { page = 1, limit = 20, sort = '-created_at' } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const notifications = await Notification.find()
      .populate('sent_by', 'name email')
      .populate('user_ids', 'name email phone')
      .sort(sort)
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Notification.countDocuments();

    return res.status(200).json({
      success: true,
      data: {
        notifications,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / parseInt(limit))
        }
      }
    });
  } catch (error) {
    console.error('Error fetching notifications:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch notifications'
    });
  }
};


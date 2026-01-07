/**
 * Customer Profile Screen Controller
 * Handles HTTP requests for customer profile management (wash_away app)
 */

import * as customerProfileService from '../services/customerProfile.service.js';

/**
 * @desc    Get customer profile with stats
 * @route   GET /api/v1/customer/profile
 * @access  Private (Customer)
 */
export const getCustomerProfile = async (req, res, next) => {
  try {
    const customerId = req.customer.id; // Customer ID from token

    if (!customerId) {
      return res.status(400).json({
        success: false,
        message: 'Customer ID not found in token'
      });
    }

    const profile = await customerProfileService.getCustomerProfile(customerId);

    res.status(200).json({
      success: true,
      data: profile
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Update customer profile
 * @route   PUT /api/v1/customer/profile
 * @access  Private (Customer)
 */
export const updateCustomerProfile = async (req, res, next) => {
  try {
    const customerId = req.customer.id;

    if (!customerId) {
      return res.status(400).json({
        success: false,
        message: 'Customer ID not found in token'
      });
    }

    const { name, phone, email } = req.body;

    // Validate at least one field is provided
    if (!name && !phone && !email) {
      return res.status(400).json({
        success: false,
        message: 'At least one field (name, phone, email) must be provided'
      });
    }

    const updateData = {};
    if (name) updateData.name = name;
    if (phone) updateData.phone = phone;
    if (email) updateData.email = email;

    const updatedProfile = await customerProfileService.updateCustomerProfile(customerId, updateData);

    res.status(200).json({
      success: true,
      data: updatedProfile,
      message: 'Profile updated successfully'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get customer stats
 * @route   GET /api/v1/customer/profile/stats
 * @access  Private (Customer)
 */
export const getCustomerStats = async (req, res, next) => {
  try {
    const customerId = req.customer.id;

    if (!customerId) {
      return res.status(400).json({
        success: false,
        message: 'Customer ID not found in token'
      });
    }

    const stats = await customerProfileService.getCustomerStats(customerId);

    res.status(200).json({
      success: true,
      data: stats
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get customer preferences
 * @route   GET /api/v1/customer/profile/preferences
 * @access  Private (Customer)
 */
export const getCustomerPreferences = async (req, res, next) => {
  try {
    const customerId = req.customer.id;

    if (!customerId) {
      return res.status(400).json({
        success: false,
        message: 'Customer ID not found in token'
      });
    }

    const preferences = await customerProfileService.getCustomerPreferences(customerId);

    res.status(200).json({
      success: true,
      data: preferences
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Update customer preferences
 * @route   PUT /api/v1/customer/profile/preferences
 * @access  Private (Customer)
 */
export const updateCustomerPreferences = async (req, res, next) => {
  try {
    const customerId = req.customer.id;

    if (!customerId) {
      return res.status(400).json({
        success: false,
        message: 'Customer ID not found in token'
      });
    }

    const { push_notification_enabled, two_factor_auth_enabled } = req.body;

    // Validate at least one preference is provided
    if (push_notification_enabled === undefined && two_factor_auth_enabled === undefined) {
      return res.status(400).json({
        success: false,
        message: 'At least one preference must be provided'
      });
    }

    const preferences = {};
    if (push_notification_enabled !== undefined) {
      preferences.push_notification_enabled = push_notification_enabled;
    }
    if (two_factor_auth_enabled !== undefined) {
      preferences.two_factor_auth_enabled = two_factor_auth_enabled;
    }

    const updatedPreferences = await customerProfileService.updateCustomerPreferences(customerId, preferences);

    res.status(200).json({
      success: true,
      data: updatedPreferences,
      message: 'Preferences updated successfully'
    });
  } catch (error) {
    next(error);
  }
};




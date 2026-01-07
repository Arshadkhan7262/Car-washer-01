/**
 * Washer Profile Screen Controller
 * Handles HTTP requests for profile management
 */

import * as washerProfileService from '../services/washerProfile.service.js';

/**
 * @desc    Get washer profile
 * @route   GET /api/v1/washer/profile
 * @access  Private (Washer)
 */
export const getWasherProfile = async (req, res, next) => {
  try {
    const userId = req.washer.id; // User ID from token
    
    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'User ID not found in token'
      });
    }

    const profile = await washerProfileService.getWasherProfile(userId);

    res.status(200).json({
      success: true,
      data: profile
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Update washer profile
 * @route   PUT /api/v1/washer/profile
 * @access  Private (Washer)
 */
export const updateWasherProfile = async (req, res, next) => {
  try {
    const userId = req.washer.id; // User ID from token
    
    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'User ID not found in token'
      });
    }

    const profile = await washerProfileService.updateWasherProfile(userId, req.body);

    res.status(200).json({
      success: true,
      data: profile,
      message: 'Profile updated successfully'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Toggle online status
 * @route   PUT /api/v1/washer/profile/online-status
 * @access  Private (Washer)
 */
export const toggleOnlineStatus = async (req, res, next) => {
  try {
    const userId = req.washer.id; // User ID from token
    const { online_status } = req.body;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'User ID not found in token'
      });
    }

    if (typeof online_status !== 'boolean') {
      return res.status(400).json({
        success: false,
        message: 'online_status must be a boolean value'
      });
    }

    const result = await washerProfileService.toggleOnlineStatus(userId, online_status);

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};


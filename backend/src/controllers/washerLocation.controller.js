/**
 * Washer Location Controller
 * Handles HTTP requests for location updates
 */

import * as washerLocationService from '../services/washerLocation.service.js';

/**
 * @desc    Update washer's current location
 * @route   PUT /api/v1/washer/location
 * @access  Private (Washer)
 */
export const updateLocation = async (req, res, next) => {
  try {
    const userId = req.washer.id; // User ID from token
    
    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'User ID not found in token'
      });
    }

    const { latitude, longitude, heading, speed } = req.body;

    if (latitude === undefined || longitude === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Latitude and longitude are required'
      });
    }

    const location = await washerLocationService.updateWasherLocation(userId, {
      latitude,
      longitude,
      heading,
      speed
    });

    res.status(200).json({
      success: true,
      data: location,
      message: 'Location updated successfully'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get washer's current location
 * @route   GET /api/v1/washer/location
 * @access  Private (Washer)
 */
export const getLocation = async (req, res, next) => {
  try {
    const userId = req.washer.id; // User ID from token
    
    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'User ID not found in token'
      });
    }

    const location = await washerLocationService.getWasherLocationByUserId(userId);

    if (!location) {
      return res.status(200).json({
        success: true,
        data: null,
        message: 'Location not available'
      });
    }

    res.status(200).json({
      success: true,
      data: location
    });
  } catch (error) {
    next(error);
  }
};














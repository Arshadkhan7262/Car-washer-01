/**
 * Washer Location Service
 * Handles washer location updates and retrieval
 */

import Washer from '../models/Washer.model.js';
import AppError from '../errors/AppError.js';

/**
 * Update washer's current location
 */
export const updateWasherLocation = async (userId, locationData) => {
  try {
    const washer = await Washer.findOne({ user_id: userId });
    
    if (!washer) {
      throw new AppError('Washer not found', 404);
    }

    // Validate location data
    const { latitude, longitude, heading, speed } = locationData;

    if (latitude === undefined || longitude === undefined) {
      throw new AppError('Latitude and longitude are required', 400);
    }

    if (latitude < -90 || latitude > 90) {
      throw new AppError('Latitude must be between -90 and 90', 400);
    }

    if (longitude < -180 || longitude > 180) {
      throw new AppError('Longitude must be between -180 and 180', 400);
    }

    // Update location
    washer.current_location = {
      latitude,
      longitude,
      last_updated: new Date(),
      heading: heading !== undefined ? heading : null,
      speed: speed !== undefined ? speed : null
    };

    await washer.save();

    return {
      latitude: washer.current_location.latitude,
      longitude: washer.current_location.longitude,
      heading: washer.current_location.heading,
      speed: washer.current_location.speed,
      last_updated: washer.current_location.last_updated
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to update location', 500);
  }
};

/**
 * Get washer's current location
 */
export const getWasherLocation = async (washerId) => {
  try {
    const washer = await Washer.findById(washerId).lean();

    if (!washer) {
      throw new AppError('Washer not found', 404);
    }

    if (!washer.current_location || !washer.current_location.latitude) {
      return null; // No location available
    }

    return {
      washer_id: washer._id.toString(),
      washer_name: washer.name,
      latitude: washer.current_location.latitude,
      longitude: washer.current_location.longitude,
      heading: washer.current_location.heading,
      speed: washer.current_location.speed,
      last_updated: washer.current_location.last_updated
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to get washer location', 500);
  }
};

/**
 * Get washer location by user ID
 */
export const getWasherLocationByUserId = async (userId) => {
  try {
    const washer = await Washer.findOne({ user_id: userId }).lean();

    if (!washer) {
      throw new AppError('Washer not found', 404);
    }

    if (!washer.current_location || !washer.current_location.latitude) {
      return null; // No location available
    }

    return {
      washer_id: washer._id.toString(),
      washer_name: washer.name,
      latitude: washer.current_location.latitude,
      longitude: washer.current_location.longitude,
      heading: washer.current_location.heading,
      speed: washer.current_location.speed,
      last_updated: washer.current_location.last_updated
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to get washer location', 500);
  }
};







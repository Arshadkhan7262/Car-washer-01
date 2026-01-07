/**
 * Washer Profile Screen Service
 * Handles profile data and profile updates
 */

import Washer from '../models/Washer.model.js';
import User from '../models/User.model.js';
import AppError from '../errors/AppError.js';

/**
 * Get washer profile with full details
 */
export const getWasherProfile = async (userId) => {
  try {
    const washer = await Washer.findOne({ user_id: userId })
      .populate('user_id', 'name email phone email_verified phone_verified')
      .lean();

    if (!washer) {
      throw new AppError('Washer not found', 404);
    }

    const user = washer.user_id;

    return {
      user: {
        id: user._id.toString(),
        name: user.name,
        email: user.email,
        phone: user.phone,
        email_verified: user.email_verified,
        phone_verified: user.phone_verified,
        wallet_balance: user.wallet_balance || 0
      },
      washer: {
        id: washer._id.toString(),
        name: washer.name,
        phone: washer.phone,
        email: washer.email,
        status: washer.status,
        online_status: washer.online_status,
        rating: washer.rating || 0,
        total_jobs: washer.total_jobs || 0,
        completed_jobs: washer.completed_jobs || 0,
        wallet_balance: washer.wallet_balance || 0,
        total_earnings: washer.total_earnings || 0
      }
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to fetch profile', 500);
  }
};

/**
 * Update washer profile
 */
export const updateWasherProfile = async (userId, updateData) => {
  try {
    const washer = await Washer.findOne({ user_id: userId });
    
    if (!washer) {
      throw new AppError('Washer not found', 404);
    }

    // Allowed fields for update
    const allowedFields = ['name', 'phone', 'email'];
    const updates = {};

    allowedFields.forEach(field => {
      if (updateData[field] !== undefined) {
        updates[field] = updateData[field];
      }
    });

    // Update washer profile
    Object.assign(washer, updates);
    await washer.save();

    // Also update user profile if needed
    if (Object.keys(updates).length > 0) {
      const user = await User.findById(washer.user_id);
      if (user) {
        if (updates.name) user.name = updates.name;
        if (updates.phone) user.phone = updates.phone;
        if (updates.email) user.email = updates.email.toLowerCase();
        await user.save();
      }
    }

    return await getWasherProfile(userId);
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to update profile', 500);
  }
};

/**
 * Toggle online status
 */
export const toggleOnlineStatus = async (userId, onlineStatus) => {
  try {
    const washer = await Washer.findOne({ user_id: userId });
    
    if (!washer) {
      throw new AppError('Washer not found', 404);
    }

    // Check if washer is active
    if (washer.status !== 'active') {
      throw new AppError('Only active washers can change online status', 403);
    }

    washer.online_status = onlineStatus === true;
    await washer.save();

    return {
      online_status: washer.online_status,
      message: washer.online_status ? 'You are now online' : 'You are now offline'
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to update online status', 500);
  }
};


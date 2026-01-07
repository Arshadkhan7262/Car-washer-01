/**
 * Customer Profile Screen Service
 * Handles profile data, stats, and preferences for wash_away app
 */

import User from '../models/User.model.js';
import Booking from '../models/Booking.model.js';
import AppError from '../errors/AppError.js';

/**
 * Get customer profile with stats
 */
export const getCustomerProfile = async (customerId) => {
  try {
    const user = await User.findById(customerId).lean();

    if (!user) {
      throw new AppError('Customer not found', 404);
    }

    if (user.role !== 'customer') {
      throw new AppError('User is not a customer', 400);
    }

    // Calculate stats from bookings
    const stats = await getCustomerStats(customerId);

    // Get user initial for avatar
    const userInitial = user.name ? user.name.charAt(0).toUpperCase() : 'U';

    return {
      user: {
        id: user._id.toString(),
        name: user.name,
        email: user.email,
        phone: user.phone,
        userInitial: userInitial,
        email_verified: user.email_verified || false,
        phone_verified: user.phone_verified || false,
        is_gold_member: user.is_gold_member || false,
        wallet_balance: user.wallet_balance || 0
      },
      stats: {
        total_washes: stats.total_washes,
        total_spent: stats.total_spent,
        wallet_balance: user.wallet_balance || 0
      },
      preferences: {
        push_notification_enabled: user.preferences?.push_notification_enabled || false,
        two_factor_auth_enabled: user.preferences?.two_factor_auth_enabled || false
      }
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to fetch customer profile', 500);
  }
};

/**
 * Get customer stats (total washes, total spent)
 */
export const getCustomerStats = async (customerId) => {
  try {
    // Count total completed bookings
    const totalWashes = await Booking.countDocuments({
      customer_id: customerId,
      status: 'completed'
    });

    // Calculate total spent from completed bookings
    const completedBookings = await Booking.find({
      customer_id: customerId,
      status: 'completed',
      payment_status: { $in: ['paid', 'unpaid'] } // Include both paid and unpaid completed bookings
    }).select('total').lean();

    const totalSpent = completedBookings.reduce((sum, booking) => {
      return sum + (booking.total || 0);
    }, 0);

    return {
      total_washes: totalWashes,
      total_spent: totalSpent
    };
  } catch (error) {
    throw new AppError('Failed to fetch customer stats', 500);
  }
};

/**
 * Update customer profile
 */
export const updateCustomerProfile = async (customerId, updateData) => {
  try {
    const user = await User.findById(customerId);

    if (!user) {
      throw new AppError('Customer not found', 404);
    }

    if (user.role !== 'customer') {
      throw new AppError('User is not a customer', 400);
    }

    // Allowed fields for update
    const allowedFields = ['name', 'phone', 'email'];
    const updates = {};

    allowedFields.forEach(field => {
      if (updateData[field] !== undefined) {
        updates[field] = updateData[field];
      }
    });

    // Normalize email if provided
    if (updates.email) {
      updates.email = updates.email.toLowerCase().trim();
    }

    // Update user profile
    Object.assign(user, updates);
    await user.save();

    return await getCustomerProfile(customerId);
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to update customer profile', 500);
  }
};

/**
 * Get customer preferences
 */
export const getCustomerPreferences = async (customerId) => {
  try {
    const user = await User.findById(customerId).select('preferences').lean();

    if (!user) {
      throw new AppError('Customer not found', 404);
    }

    if (user.role !== 'customer') {
      throw new AppError('User is not a customer', 400);
    }

    return {
      push_notification_enabled: user.preferences?.push_notification_enabled || false,
      two_factor_auth_enabled: user.preferences?.two_factor_auth_enabled || false
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to fetch customer preferences', 500);
  }
};

/**
 * Update customer preferences
 */
export const updateCustomerPreferences = async (customerId, preferences) => {
  try {
    const user = await User.findById(customerId);

    if (!user) {
      throw new AppError('Customer not found', 404);
    }

    if (user.role !== 'customer') {
      throw new AppError('User is not a customer', 400);
    }

    // Initialize preferences if not exists
    if (!user.preferences) {
      user.preferences = {};
    }

    // Update preferences
    if (preferences.push_notification_enabled !== undefined) {
      user.preferences.push_notification_enabled = preferences.push_notification_enabled === true;
    }

    if (preferences.two_factor_auth_enabled !== undefined) {
      user.preferences.two_factor_auth_enabled = preferences.two_factor_auth_enabled === true;
    }

    await user.save();

    return {
      push_notification_enabled: user.preferences.push_notification_enabled,
      two_factor_auth_enabled: user.preferences.two_factor_auth_enabled
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to update customer preferences', 500);
  }
};




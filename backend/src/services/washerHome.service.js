/**
 * Washer Home Screen Service
 * Handles dashboard statistics and home screen data for washer app
 */

import Booking from '../models/Booking.model.js';
import Washer from '../models/Washer.model.js';
import User from '../models/User.model.js';
import AppError from '../errors/AppError.js';

/**
 * Get dashboard stats for home screen
 * Returns: today's jobs, today's earnings, total stats
 */
export const getDashboardStats = async (userId) => {
  try {
    // Get washer profile by user_id
    const washer = await Washer.findOne({ user_id: userId });
    if (!washer) {
      throw new AppError('Washer not found', 404);
    }
    
    const washerId = washer._id.toString();

    // Get today's date range
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    // Get today's completed jobs
    const todayJobs = await Booking.countDocuments({
      washer_id: washerId,
      status: 'completed',
      created_date: {
        $gte: today,
        $lt: tomorrow
      }
    });

    // Get today's earnings from ALL assigned bookings (not just completed)
    // This includes: pending, accepted, on_the_way, arrived, in_progress, completed
    // Only count paid bookings
    const todayEarningsData = await Booking.aggregate([
      {
        $match: {
          washer_id: washerId,
          payment_status: 'paid', // Only count paid bookings
          created_date: {
            $gte: today,
            $lt: tomorrow
          },
          // Include all statuses where washer is assigned (not cancelled)
          status: {
            $in: ['pending', 'accepted', 'on_the_way', 'arrived', 'in_progress', 'completed']
          }
        }
      },
      {
        $group: {
          _id: null,
          total: { $sum: '$total' }
        }
      }
    ]);

    const todayEarnings = todayEarningsData.length > 0 ? todayEarningsData[0].total : 0;

    // Get total stats
    const totalCompletedJobs = washer.completed_jobs || 0;
    const totalEarnings = washer.total_earnings || 0;
    const rating = washer.rating || 0;
    const onlineStatus = washer.online_status || false;

    return {
      today: {
        jobs: todayJobs,
        earnings: todayEarnings
      },
      total: {
        jobs: totalCompletedJobs,
        earnings: totalEarnings,
        rating: rating
      },
      online_status: onlineStatus
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to fetch dashboard stats', 500);
  }
};

/**
 * Get period-based stats (today, week, month)
 */
export const getPeriodStats = async (userId, period = 'today') => {
  try {
    const washer = await Washer.findOne({ user_id: userId });
    if (!washer) {
      throw new AppError('Washer not found', 404);
    }
    
    const washerId = washer._id.toString();

    // Calculate date range based on period
    const now = new Date();
    let startDate = new Date();
    
    switch (period) {
      case 'today':
        startDate.setHours(0, 0, 0, 0);
        break;
      case 'week':
        startDate.setDate(startDate.getDate() - 7);
        startDate.setHours(0, 0, 0, 0);
        break;
      case 'month':
        startDate.setMonth(startDate.getMonth() - 1);
        startDate.setHours(0, 0, 0, 0);
        break;
      default:
        startDate.setHours(0, 0, 0, 0);
    }

    // Get jobs count for period
    const jobsCount = await Booking.countDocuments({
      washer_id: washerId,
      status: 'completed',
      created_date: {
        $gte: startDate,
        $lte: now
      }
    });

    // Get earnings for period
    const earningsData = await Booking.aggregate([
      {
        $match: {
          washer_id: washerId,
          status: 'completed',
          payment_status: 'paid',
          created_date: {
            $gte: startDate,
            $lte: now
          }
        }
      },
      {
        $group: {
          _id: null,
          total: { $sum: '$total' }
        }
      }
    ]);

    const earnings = earningsData.length > 0 ? earningsData[0].total : 0;

    return {
      period,
      jobs: jobsCount,
      earnings: earnings
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to fetch period stats', 500);
  }
};


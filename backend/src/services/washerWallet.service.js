/**
 * Washer Wallet Screen Service
 * Handles wallet balance, transactions, and period-based stats
 */

import Washer from '../models/Washer.model.js';
import Booking from '../models/Booking.model.js';
import AppError from '../errors/AppError.js';

/**
 * Get wallet balance
 */
export const getWalletBalance = async (userId) => {
  try {
    const washer = await Washer.findOne({ user_id: userId });
    
    if (!washer) {
      throw new AppError('Washer not found', 404);
    }

    return {
      balance: washer.wallet_balance || 0,
      total_earnings: washer.total_earnings || 0
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to fetch wallet balance', 500);
  }
};

/**
 * Get wallet stats by period (today, week, month)
 */
export const getWalletStats = async (userId, period = 'today') => {
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

    // Get completed jobs count for period
    const jobsCompleted = await Booking.countDocuments({
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
      balance: washer.wallet_balance || 0,
      earnings: earnings,
      jobs_completed: jobsCompleted
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to fetch wallet stats', 500);
  }
};

/**
 * Get transaction history (from completed bookings)
 */
export const getTransactions = async (userId, filters = {}) => {
  try {
    // Get washer by user_id
    const washer = await Washer.findOne({ user_id: userId });
    if (!washer) {
      throw new AppError('Washer not found', 404);
    }
    
    const washerId = washer._id.toString();
    
    const {
      period = 'all', // today, week, month, all
      page = 1,
      limit = 20,
      sort = '-created_date'
    } = filters;

    const query = {
      washer_id: washerId,
      status: 'completed',
      payment_status: 'paid'
    };

    // Add date filter if period is specified
    if (period !== 'all') {
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
      }
      
      query.created_date = {
        $gte: startDate,
        $lte: now
      };
    }

    // Parse sort
    const sortField = sort.startsWith('-') ? sort.substring(1) : sort;
    const sortOrder = sort.startsWith('-') ? -1 : 1;
    const sortObj = { [sortField]: sortOrder };

    // Calculate pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const transactions = await Booking.find(query)
      .select('booking_id customer_name service_name total payment_method created_date status')
      .sort(sortObj)
      .skip(skip)
      .limit(parseInt(limit))
      .lean();

    const total = await Booking.countDocuments(query);

    // Transform to transaction format
    const formattedTransactions = transactions.map(tx => ({
      id: tx._id.toString(),
      booking_id: tx.booking_id,
      customer_name: tx.customer_name,
      service_name: tx.service_name,
      amount: tx.total,
      type: 'earning', // All transactions are earnings for washer
      payment_method: tx.payment_method,
      date: tx.created_date,
      status: tx.status
    }));

    return {
      transactions: formattedTransactions,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        totalPages: Math.ceil(total / parseInt(limit))
      }
    };
  } catch (error) {
    throw new AppError('Failed to fetch transactions', 500);
  }
};

/**
 * Request withdrawal
 */
export const requestWithdrawal = async (userId, amount) => {
  try {
    const washer = await Washer.findOne({ user_id: userId });
    
    if (!washer) {
      throw new AppError('Washer not found', 404);
    }

    const currentBalance = washer.wallet_balance || 0;

    if (amount > currentBalance) {
      throw new AppError('Insufficient balance', 400);
    }

    if (amount <= 0) {
      throw new AppError('Invalid withdrawal amount', 400);
    }

    // TODO: Create withdrawal request record in database
    // For now, just return success message
    // In future, implement withdrawal request model and approval flow

    return {
      message: 'Withdrawal request submitted successfully',
      requested_amount: amount,
      current_balance: currentBalance,
      remaining_balance: currentBalance - amount
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to process withdrawal request', 500);
  }
};


/**
 * Washer Home Screen Controller
 * Handles HTTP requests for home screen dashboard stats
 */

import * as washerHomeService from '../services/washerHome.service.js';

/**
 * @desc    Get dashboard stats for home screen
 * @route   GET /api/v1/washer/home/stats
 * @access  Private (Washer)
 */
export const getDashboardStats = async (req, res, next) => {
  try {
    const userId = req.washer.id; // User ID from token
    
    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'User ID not found in token'
      });
    }

    const stats = await washerHomeService.getDashboardStats(userId);

    res.status(200).json({
      success: true,
      data: stats
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get period-based stats (today, week, month)
 * @route   GET /api/v1/washer/home/stats/:period
 * @access  Private (Washer)
 */
export const getPeriodStats = async (req, res, next) => {
  try {
    const userId = req.washer.id; // User ID from token
    const { period } = req.params;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'User ID not found in token'
      });
    }

    const validPeriods = ['today', 'week', 'month'];
    if (!validPeriods.includes(period)) {
      return res.status(400).json({
        success: false,
        message: `Invalid period. Must be one of: ${validPeriods.join(', ')}`
      });
    }

    const stats = await washerHomeService.getPeriodStats(userId, period);

    res.status(200).json({
      success: true,
      data: stats
    });
  } catch (error) {
    next(error);
  }
};


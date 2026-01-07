/**
 * Washer Wallet Screen Controller
 * Handles HTTP requests for wallet management
 */

import * as washerWalletService from '../services/washerWallet.service.js';

/**
 * @desc    Get wallet balance
 * @route   GET /api/v1/washer/wallet/balance
 * @access  Private (Washer)
 */
export const getWalletBalance = async (req, res, next) => {
  try {
    const userId = req.washer.id; // User ID from token
    
    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'User ID not found in token'
      });
    }

    const balance = await washerWalletService.getWalletBalance(userId);

    res.status(200).json({
      success: true,
      data: balance
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get wallet stats by period
 * @route   GET /api/v1/washer/wallet/stats
 * @access  Private (Washer)
 */
export const getWalletStats = async (req, res, next) => {
  try {
    const userId = req.washer.id; // User ID from token
    const { period = 'today' } = req.query;

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

    const stats = await washerWalletService.getWalletStats(userId, period);

    res.status(200).json({
      success: true,
      data: stats
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get transaction history
 * @route   GET /api/v1/washer/wallet/transactions
 * @access  Private (Washer)
 */
export const getTransactions = async (req, res, next) => {
  try {
    const userId = req.washer.id; // User ID from token
    
    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'User ID not found in token'
      });
    }

    const filters = {
      period: req.query.period || 'all',
      page: req.query.page || 1,
      limit: req.query.limit || 20,
      sort: req.query.sort || '-created_date'
    };

    const result = await washerWalletService.getTransactions(userId, filters);

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Request withdrawal
 * @route   POST /api/v1/washer/wallet/withdraw
 * @access  Private (Washer)
 */
export const requestWithdrawal = async (req, res, next) => {
  try {
    const userId = req.washer.id; // User ID from token
    const { amount } = req.body;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'User ID not found in token'
      });
    }

    if (!amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Valid withdrawal amount is required'
      });
    }

    const result = await washerWalletService.requestWithdrawal(userId, amount);

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};


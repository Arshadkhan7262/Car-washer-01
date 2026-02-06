import * as withdrawalService from '../services/withdrawal.service.js';
import AppError from '../errors/AppError.js';

/**
 * @desc    Create withdrawal request
 * @route   POST /api/v1/washer/withdrawal/request
 * @access  Private (Washer)
 */
export const createWithdrawalRequest = async (req, res, next) => {
  try {
    // protectWasher sets req.washer with user_id (from User model)
    // The service expects userId which is the User._id (not Washer._id)
    const userId = req.washer?.user_id || req.washer?._id || req.washer?.id || req.user?._id;
    
    if (!userId) {
      throw new AppError('User ID not found. Please log in again.', 401);
    }
    
    const { amount, currency = 'usd' } = req.body;

    if (!amount || amount <= 0) {
      throw new AppError('Valid withdrawal amount is required', 400);
    }

    const withdrawal = await withdrawalService.createWithdrawalRequest(
      userId,
      parseFloat(amount),
      currency
    );

    res.status(201).json({
      success: true,
      message: 'Withdrawal request created successfully',
      data: withdrawal
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get washer withdrawal requests
 * @route   GET /api/v1/washer/withdrawal
 * @access  Private (Washer)
 */
export const getWasherWithdrawals = async (req, res, next) => {
  try {
    const userId = req.washer?._id || req.washer?.id || req.user?._id;
    const { status, limit, page } = req.query;

    const filters = {
      status,
      limit: parseInt(limit) || 50,
      skip: ((parseInt(page) || 1) - 1) * (parseInt(limit) || 50)
    };

    const withdrawals = await withdrawalService.getWasherWithdrawals(userId, filters);

    res.status(200).json({
      success: true,
      data: withdrawals
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get minimum withdrawal limit
 * @route   GET /api/v1/washer/withdrawal/limit
 * @access  Private (Washer)
 */
export const getWithdrawalLimit = async (req, res, next) => {
  try {
    const limit = await withdrawalService.getMinimumWithdrawalLimit();

    res.status(200).json({
      success: true,
      data: {
        minimum_limit: limit
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get all withdrawal requests (Admin)
 * @route   GET /api/v1/admin/withdrawals
 * @access  Private (Admin)
 */
export const getAllWithdrawals = async (req, res, next) => {
  try {
    const { status, washer_id, limit, page } = req.query;

    const filters = {
      status,
      washer_id,
      limit: parseInt(limit) || 100,
      page: parseInt(page) || 1,
      skip: ((parseInt(page) || 1) - 1) * (parseInt(limit) || 100)
    };

    const result = await withdrawalService.getAllWithdrawals(filters);

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Approve withdrawal request (Admin)
 * @route   PUT /api/v1/admin/withdrawal/:id/approve
 * @access  Private (Admin)
 */
export const approveWithdrawal = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { note } = req.body;
    const adminId = req.user?._id || req.admin?._id;

    if (!adminId) {
      throw new AppError('Admin authentication required', 401);
    }

    const withdrawal = await withdrawalService.approveWithdrawal(id, adminId, note);

    res.status(200).json({
      success: true,
      message: 'Withdrawal request approved successfully',
      data: withdrawal
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Process withdrawal (Admin)
 * @route   PUT /api/v1/admin/withdrawal/:id/process
 * @access  Private (Admin)
 */
export const processWithdrawal = async (req, res, next) => {
  try {
    const { id } = req.params;
    const adminId = req.user?._id || req.admin?._id;

    if (!adminId) {
      throw new AppError('Admin authentication required', 401);
    }

    const withdrawal = await withdrawalService.processWithdrawal(id, adminId);

    res.status(200).json({
      success: true,
      message: 'Withdrawal processed successfully',
      data: withdrawal
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Reject withdrawal request (Admin)
 * @route   PUT /api/v1/admin/withdrawal/:id/reject
 * @access  Private (Admin)
 */
export const rejectWithdrawal = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    const adminId = req.user?._id || req.admin?._id;

    if (!adminId) {
      throw new AppError('Admin authentication required', 401);
    }

    if (!reason) {
      throw new AppError('Rejection reason is required', 400);
    }

    const withdrawal = await withdrawalService.rejectWithdrawal(id, adminId, reason);

    res.status(200).json({
      success: true,
      message: 'Withdrawal request rejected',
      data: withdrawal
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Cancel withdrawal request (Washer)
 * @route   PUT /api/v1/washer/withdrawal/:id/cancel
 * @access  Private (Washer)
 */
export const cancelWithdrawal = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.washer?._id || req.washer?.id || req.user?._id;

    const withdrawal = await withdrawalService.cancelWithdrawal(id, userId);

    res.status(200).json({
      success: true,
      message: 'Withdrawal request cancelled',
      data: withdrawal
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get withdrawal details
 * @route   GET /api/v1/washer/withdrawal/:id
 * @access  Private (Washer)
 */
export const getWithdrawalDetails = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.washer?._id || req.washer?.id || req.user?._id;

    const result = await withdrawalService.getWithdrawalDetails(id, userId);

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Process approved withdrawal via Stripe (Washer)
 * @route   POST /api/v1/washer/withdrawal/:id/process
 * @access  Private (Washer)
 */
export const processApprovedWithdrawal = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.washer?._id || req.washer?.id || req.user?._id;

    const withdrawal = await withdrawalService.processApprovedWithdrawal(id, userId);

    res.status(200).json({
      success: true,
      message: 'Withdrawal processed successfully',
      data: withdrawal
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get minimum withdrawal limit (Admin)
 * @route   GET /api/v1/admin/withdrawal/limit
 * @access  Private (Admin)
 */
export const getWithdrawalLimitAdmin = async (req, res, next) => {
  try {
    const limit = await withdrawalService.getMinimumWithdrawalLimit();

    res.status(200).json({
      success: true,
      data: {
        minimum_limit: limit
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Set minimum withdrawal limit (Admin)
 * @route   PUT /api/v1/admin/withdrawal/limit
 * @access  Private (Admin)
 */
export const setWithdrawalLimit = async (req, res, next) => {
  try {
    const { limit } = req.body;
    const adminId = req.user?._id || req.admin?._id;

    if (!adminId) {
      throw new AppError('Admin authentication required', 401);
    }

    if (limit === undefined || limit === null) {
      throw new AppError('Withdrawal limit is required', 400);
    }

    const setting = await withdrawalService.setMinimumWithdrawalLimit(
      parseFloat(limit),
      adminId
    );

    res.status(200).json({
      success: true,
      message: 'Withdrawal limit updated successfully',
      data: {
        minimum_limit: setting.value
      }
    });
  } catch (error) {
    next(error);
  }
};

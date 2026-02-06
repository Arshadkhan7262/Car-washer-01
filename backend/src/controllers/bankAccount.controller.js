import * as bankAccountService from '../services/bankAccount.service.js';
import Washer from '../models/Washer.model.js';
import AppError from '../errors/AppError.js';

/**
 * @desc    Add or update bank account
 * @route   POST /api/v1/washer/bank-account
 * @access  Private (Washer)
 */
export const saveBankAccount = async (req, res, next) => {
  try {
    const userId = req.washer.id;
    const washer = await Washer.findOne({ user_id: userId });
    
    if (!washer) {
      return res.status(404).json({
        success: false,
        message: 'Washer not found'
      });
    }

    const bankAccount = await bankAccountService.saveBankAccount(
      userId,
      washer._id,
      req.body
    );

    res.status(200).json({
      success: true,
      message: 'Bank account saved successfully',
      data: {
        account_holder_name: bankAccount.account_holder_name,
        account_number_last4: bankAccount.account_number_last4,
        account_type: bankAccount.account_type,
        bank_name: bankAccount.bank_name,
        is_verified: bankAccount.is_verified,
        status: bankAccount.status,
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get bank account
 * @route   GET /api/v1/washer/bank-account
 * @access  Private (Washer)
 */
export const getBankAccount = async (req, res, next) => {
  try {
    const userId = req.washer.id;
    const washer = await Washer.findOne({ user_id: userId });
    
    if (!washer) {
      return res.status(404).json({
        success: false,
        message: 'Washer not found'
      });
    }

    const bankAccount = await bankAccountService.getBankAccount(userId, washer._id);

    if (!bankAccount) {
      return res.status(200).json({
        success: true,
        data: null,
        message: 'No bank account found'
      });
    }

    res.status(200).json({
      success: true,
      data: bankAccount
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Delete bank account
 * @route   DELETE /api/v1/washer/bank-account
 * @access  Private (Washer)
 */
export const deleteBankAccount = async (req, res, next) => {
  try {
    const userId = req.washer.id;
    const washer = await Washer.findOne({ user_id: userId });
    
    if (!washer) {
      return res.status(404).json({
        success: false,
        message: 'Washer not found'
      });
    }

    await bankAccountService.deleteBankAccount(userId, washer._id);

    res.status(200).json({
      success: true,
      message: 'Bank account deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

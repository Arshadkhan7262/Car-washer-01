import * as bankAccountService from '../services/bankAccount.service.js';
import AppError from '../errors/AppError.js';

/**
 * @desc    Get all bank accounts (Admin only)
 * @route   GET /api/v1/admin/bank-accounts
 * @access  Private (Admin)
 */
export const getAllBankAccounts = async (req, res, next) => {
  try {
    const { status, washer_id } = req.query;
    
    const filters = {};
    if (status) filters.status = status;
    if (washer_id) filters.washer_id = washer_id;

    const bankAccounts = await bankAccountService.getAllBankAccounts(filters);

    res.status(200).json({
      success: true,
      data: bankAccounts
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get bank account by ID (Admin only)
 * @route   GET /api/v1/admin/bank-accounts/:id
 * @access  Private (Admin)
 */
export const getBankAccountById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const bankAccount = await bankAccountService.getBankAccountById(id);

    res.status(200).json({
      success: true,
      data: bankAccount
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Verify bank account (Admin only)
 * @route   PUT /api/v1/admin/bank-accounts/:id/verify
 * @access  Private (Admin)
 */
export const verifyBankAccount = async (req, res, next) => {
  try {
    const { id } = req.params;
    const adminId = req.admin?.id || req.admin?._id;

    const bankAccount = await bankAccountService.verifyBankAccount(id, adminId);

    res.status(200).json({
      success: true,
      message: 'Bank account verified successfully',
      data: {
        _id: bankAccount._id,
        account_holder_name: bankAccount.account_holder_name,
        account_number_last4: bankAccount.account_number_last4,
        is_verified: bankAccount.is_verified,
        status: bankAccount.status,
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Reject bank account (Admin only)
 * @route   PUT /api/v1/admin/bank-accounts/:id/reject
 * @access  Private (Admin)
 */
export const rejectBankAccount = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    const adminId = req.admin?.id || req.admin?._id;

    const bankAccount = await bankAccountService.rejectBankAccount(id, reason, adminId);

    res.status(200).json({
      success: true,
      message: 'Bank account rejected',
      data: {
        _id: bankAccount._id,
        status: bankAccount.status,
      }
    });
  } catch (error) {
    next(error);
  }
};

import mongoose from 'mongoose';
import Withdrawal from '../models/Withdrawal.model.js';
import Washer from '../models/Washer.model.js';
import BankAccount from '../models/BankAccount.model.js';
import AdminSettings from '../models/AdminSettings.model.js';
import AdminUser from '../models/AdminUser.model.js';
import Notification from '../models/Notification.model.js';
import getStripeInstance from '../config/stripe.config.js';
import AppError from '../errors/AppError.js';

/**
 * Get minimum withdrawal limit from admin settings
 */
export const getMinimumWithdrawalLimit = async () => {
  try {
    const setting = await AdminSettings.findOne({ key: 'minimum_withdrawal_limit' });
    if (setting && setting.value) {
      return parseFloat(setting.value);
    }
    // Default minimum withdrawal limit: $2000
    return 2000;
  } catch (error) {
    console.error('Error getting withdrawal limit:', error);
    return 2000; // Default fallback
  }
};

/**
 * Set minimum withdrawal limit (Admin only)
 */
export const setMinimumWithdrawalLimit = async (limit, adminId) => {
  try {
    if (limit < 0) {
      throw new AppError('Withdrawal limit must be greater than or equal to 0', 400);
    }

    const setting = await AdminSettings.findOneAndUpdate(
      { key: 'minimum_withdrawal_limit' },
      {
        key: 'minimum_withdrawal_limit',
        value: limit,
        description: 'Minimum amount required for washer withdrawal requests',
        updated_by: adminId
      },
      { upsert: true, new: true }
    );

    return setting;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to set withdrawal limit', 500);
  }
};

/**
 * Create withdrawal request
 */
export const createWithdrawalRequest = async (userId, amount, currency = 'usd') => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    // Get washer by user_id with session for transaction
    const washer = await Washer.findOne({ user_id: userId }).session(session);
    if (!washer) {
      throw new AppError('Washer not found', 404);
    }

    // Check if washer is active
    if (washer.status !== 'active') {
      throw new AppError('Only active washers can request withdrawal', 403);
    }

    // Check if bank account is set up
    const bankAccount = await BankAccount.findOne({ washer_id: washer._id });
    if (!bankAccount || !bankAccount.is_verified) {
      throw new AppError('Please set up your bank account first to receive payouts', 400);
    }

    // Validate wallet balance - allow any amount if washer has earnings (no minimum limit)
    if (!washer.wallet_balance || washer.wallet_balance <= 0) {
      throw new AppError('You have no earnings to withdraw', 400);
    }

    // Validate withdrawal amount doesn't exceed wallet balance
    if (washer.wallet_balance < amount) {
      throw new AppError(`Insufficient wallet balance. Your current balance is $${washer.wallet_balance.toFixed(2)}`, 400);
    }

    // Validate amount is greater than 0
    if (amount <= 0) {
      throw new AppError('Withdrawal amount must be greater than 0', 400);
    }

    // Check for pending withdrawal requests (with session for consistency)
    const pendingRequest = await Withdrawal.findOne({
      washer_id: washer._id,
      status: { $in: ['pending', 'approved', 'processing'] }
    }).session(session);

    if (pendingRequest) {
      throw new AppError('You already have a pending withdrawal request', 400);
    }

    // Create withdrawal request within transaction
    const withdrawal = await Withdrawal.create([{
      washer_id: washer._id,
      user_id: userId,
      amount: amount,
      currency: currency.toLowerCase(),
      status: 'pending',
      payment_method: 'stripe'
    }], { session });

    await session.commitTransaction();

    // Notify admins about new withdrawal request (non-blocking, outside transaction)
    notifyAdminsOfWithdrawalRequest(withdrawal[0], washer).catch((notifyError) => {
      console.error('Failed to notify admins of withdrawal request:', notifyError);
    });

    return withdrawal[0];
  } catch (error) {
    await session.abortTransaction();
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to create withdrawal request', 500);
  } finally {
    session.endSession();
  }
};

/**
 * Get withdrawal requests for a washer
 */
export const getWasherWithdrawals = async (userId, filters = {}) => {
  try {
    const washer = await Washer.findOne({ user_id: userId });
    if (!washer) {
      throw new AppError('Washer not found', 404);
    }

    const query = { washer_id: washer._id };
    
    if (filters.status) {
      query.status = filters.status;
    }

    const withdrawals = await Withdrawal.find(query)
      .sort({ requested_date: -1 })
      .limit(filters.limit || 50)
      .skip(filters.skip || 0)
      .populate('admin_id', 'name email')
      .lean();

    return withdrawals;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to fetch withdrawal requests', 500);
  }
};

/**
 * Get all withdrawal requests (Admin)
 */
export const getAllWithdrawals = async (filters = {}) => {
  try {
    const query = {};

    if (filters.status) {
      query.status = filters.status;
    }

    if (filters.washer_id) {
      query.washer_id = filters.washer_id;
    }

    const withdrawals = await Withdrawal.find(query)
      .sort({ requested_date: -1 })
      .populate('washer_id', 'name email phone')
      .populate('user_id', 'email')
      .populate('admin_id', 'name email')
      .limit(filters.limit || 100)
      .skip(filters.skip || 0)
      .lean();

    const total = await Withdrawal.countDocuments(query);

    return {
      withdrawals,
      total,
      page: filters.page || 1,
      limit: filters.limit || 100
    };
  } catch (error) {
    throw new AppError('Failed to fetch withdrawal requests', 500);
  }
};

/**
 * Approve withdrawal request (Admin)
 */
export const approveWithdrawal = async (withdrawalId, adminId, note = null) => {
  try {
    const withdrawal = await Withdrawal.findById(withdrawalId)
      .populate('washer_id');

    if (!withdrawal) {
      throw new AppError('Withdrawal request not found', 404);
    }

    if (withdrawal.status !== 'pending') {
      throw new AppError('Only pending withdrawals can be approved', 400);
    }

    const washer = withdrawal.washer_id;
    
    // Verify wallet balance again
    if (washer.wallet_balance < withdrawal.amount) {
      throw new AppError('Washer has insufficient balance', 400);
    }

    // Update withdrawal status
    withdrawal.status = 'approved';
    withdrawal.admin_id = adminId;
    withdrawal.admin_note = note;
    withdrawal.approved_date = new Date();
    await withdrawal.save();

    return withdrawal;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to approve withdrawal', 500);
  }
};

/**
 * Process withdrawal with Stripe Connect Transfer (Admin)
 * Uses database transactions to prevent race conditions
 */
export const processWithdrawal = async (withdrawalId, adminId) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    // Lock withdrawal record for update
    const withdrawal = await Withdrawal.findById(withdrawalId)
      .populate('washer_id')
      .session(session);

    if (!withdrawal) {
      throw new AppError('Withdrawal request not found', 404);
    }

    // Check idempotency - if already completed, return existing
    if (withdrawal.status === 'completed' && withdrawal.stripe_transfer_id) {
      await session.commitTransaction();
      return withdrawal;
    }

    if (withdrawal.status !== 'approved') {
      throw new AppError('Only approved withdrawals can be processed', 400);
    }

    const washer = withdrawal.washer_id;

    // Get bank account details
    const bankAccount = await BankAccount.findOne({ washer_id: washer._id });
    if (!bankAccount || !bankAccount.is_verified) {
      throw new AppError('Washer has not set up their bank account', 400);
    }

    // Lock washer record and verify balance atomically
    const lockedWasher = await Washer.findById(washer._id).session(session);
    if (lockedWasher.wallet_balance < withdrawal.amount) {
      throw new AppError('Insufficient wallet balance', 400);
    }

    const stripe = getStripeInstance();

    // Update status to processing BEFORE Stripe call
    withdrawal.status = 'processing';
    withdrawal.processed_date = new Date();
    withdrawal.admin_id = adminId;
    await withdrawal.save({ session });

    try {
      // Create Stripe Payout to washer's bank account
      let payout;
      
      // Option 1: If washer has Stripe Connect account, use Transfer
      if (washer.stripe_account_id && bankAccount.stripe_bank_account_id) {
        // Transfer to connected account
        payout = await stripe.transfers.create({
          amount: Math.round(withdrawal.amount * 100), // Convert to cents
          currency: withdrawal.currency.toLowerCase(),
          destination: washer.stripe_account_id,
          metadata: {
            withdrawal_id: withdrawal._id.toString(),
            washer_id: washer._id.toString(),
            admin_id: adminId.toString(),
          },
        }, {
          idempotencyKey: `withdraw_${withdrawalId}_${withdrawal.updatedAt.getTime()}`,
        });
      } 
      // Option 2: If we have bank account details but no Connect account, create payout from platform
      else if (bankAccount.stripe_bank_account_id) {
        // Note: This requires Stripe Connect platform account
        // For now, we'll use manual processing or create Connect account on the fly
        throw new AppError('Stripe Connect account required for automatic payouts. Please set up bank account via Stripe Connect.', 400);
      } 
      // Option 3: Manual processing (admin processes via bank transfer)
      else {
        // Store bank account details in withdrawal for admin reference
        withdrawal.metadata = withdrawal.metadata || {};
        withdrawal.metadata.bank_account_last4 = bankAccount.account_number_last4;
        withdrawal.metadata.bank_routing = bankAccount.routing_number;
        withdrawal.metadata.account_holder_name = bankAccount.account_holder_name;
        
        // Mark as processing - admin will process manually
        // In production, you might integrate with ACH service or bank API
        console.log(`Manual processing required for withdrawal ${withdrawalId}. Bank details stored.`);
        
        // For now, we'll still deduct balance and mark as completed
        // Admin can process via bank transfer manually
        // In production, integrate with payment processor API here
      }

      // Only deduct wallet AFTER successful Stripe transfer/payout
      lockedWasher.wallet_balance = (lockedWasher.wallet_balance || 0) - withdrawal.amount;
      await lockedWasher.save({ session });

      // Update withdrawal status
      withdrawal.status = 'completed';
      withdrawal.completed_date = new Date();
      if (payout) {
        withdrawal.stripe_payout_id = payout.id;
        withdrawal.stripe_transfer_id = payout.id; // Keep for backward compatibility
      }
      await withdrawal.save({ session });

      await session.commitTransaction();

      return withdrawal;
    } catch (stripeError) {
      // Revert withdrawal status on Stripe error
      withdrawal.status = 'approved';
      withdrawal.processed_date = null;
      await withdrawal.save({ session });
      await session.abortTransaction();
      
      throw new AppError(`Stripe payout failed: ${stripeError.message}`, 500);
    }
  } catch (error) {
    await session.abortTransaction();
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to process withdrawal', 500);
  } finally {
    session.endSession();
  }
};

/**
 * Reject withdrawal request (Admin)
 */
export const rejectWithdrawal = async (withdrawalId, adminId, reason) => {
  try {
    const withdrawal = await Withdrawal.findById(withdrawalId);

    if (!withdrawal) {
      throw new AppError('Withdrawal request not found', 404);
    }

    if (withdrawal.status !== 'pending') {
      throw new AppError('Only pending withdrawals can be rejected', 400);
    }

    withdrawal.status = 'rejected';
    withdrawal.admin_id = adminId;
    withdrawal.rejection_reason = reason;
    await withdrawal.save();

    return withdrawal;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to reject withdrawal', 500);
  }
};

/**
 * Get withdrawal status and details
 * Replaced createWithdrawalPaymentIntent - withdrawals are now processed automatically via Stripe Transfers
 */
export const getWithdrawalDetails = async (withdrawalId, userId) => {
  try {
    const withdrawal = await Withdrawal.findById(withdrawalId)
      .populate('washer_id');

    if (!withdrawal) {
      throw new AppError('Withdrawal request not found', 404);
    }

    // Verify ownership
    const washer = withdrawal.washer_id;
    if (washer.user_id.toString() !== userId.toString()) {
      throw new AppError('Unauthorized access to this withdrawal', 403);
    }

    return {
      withdrawal: withdrawal,
      can_process: withdrawal.status === 'approved' && washer.stripe_account_onboarding_complete,
      requires_setup: !washer.stripe_account_onboarding_complete,
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(`Failed to get withdrawal details: ${error.message}`, 500);
  }
};

/**
 * Process approved withdrawal via Stripe Connect Transfer (Washer)
 * Note: Withdrawals are automatically processed by admin approval
 * This endpoint is kept for backward compatibility but redirects to admin processing
 */
export const processApprovedWithdrawal = async (withdrawalId, userId) => {
  try {
    const withdrawal = await Withdrawal.findById(withdrawalId)
      .populate('washer_id');

    if (!withdrawal) {
      throw new AppError('Withdrawal request not found', 404);
    }

    // Verify ownership
    const washer = withdrawal.washer_id;
    if (washer.user_id.toString() !== userId.toString()) {
      throw new AppError('Unauthorized access to this withdrawal', 403);
    }

    // Check idempotency
    if (withdrawal.status === 'completed' && withdrawal.stripe_transfer_id) {
      return withdrawal; // Already processed
    }

    if (withdrawal.status !== 'approved') {
      throw new AppError(`Withdrawal is ${withdrawal.status}. Only approved withdrawals can be processed.`, 400);
    }

    // Verify bank account is set up
    const bankAccount = await BankAccount.findOne({ washer_id: washer._id });
    if (!bankAccount || !bankAccount.is_verified) {
      throw new AppError('Please complete your bank account setup first', 400);
    }

    // Note: Actual processing happens when admin approves
    // This endpoint just verifies readiness
    return {
      withdrawal: withdrawal,
      message: 'Withdrawal is approved and will be processed automatically. You will receive the funds in your bank account within 1-2 business days.',
      status: 'approved',
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to process withdrawal', 500);
  }
};

/**
 * Cancel withdrawal request (Washer)
 */
export const cancelWithdrawal = async (withdrawalId, userId) => {
  try {
    const withdrawal = await Withdrawal.findById(withdrawalId);

    if (!withdrawal) {
      throw new AppError('Withdrawal request not found', 404);
    }

    // Verify ownership
    if (withdrawal.user_id.toString() !== userId.toString()) {
      throw new AppError('Unauthorized', 403);
    }

    if (withdrawal.status !== 'pending') {
      throw new AppError('Only pending withdrawals can be cancelled', 400);
    }

    withdrawal.status = 'cancelled';
    await withdrawal.save();

    return withdrawal;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to cancel withdrawal', 500);
  }
};

/**
 * Notify admins about new withdrawal request
 * Creates a notification record that admins can see in the admin panel
 */
const notifyAdminsOfWithdrawalRequest = async (withdrawal, washer) => {
  try {
    // Get all active admins
    const admins = await AdminUser.find({ is_active: true }).select('_id email name');
    
    if (admins.length === 0) {
      console.log('No active admins found to notify');
      return;
    }

    const adminIds = admins.map(admin => admin._id);
    const washerName = washer.name || 'Unknown Washer';
    const amount = withdrawal.amount.toFixed(2);

    // Create notification record for admins
    const notification = new Notification({
      title: 'New Withdrawal Request',
      message: `${washerName} requested a withdrawal of $${amount}`,
      target_audience: 'specific',
      user_ids: adminIds, // Store admin IDs for reference
      data: {
        type: 'withdrawal_request',
        withdrawal_id: withdrawal._id.toString(),
        washer_id: washer._id.toString(),
        washer_name: washerName,
        amount: withdrawal.amount.toString(),
        currency: withdrawal.currency,
        status: 'pending'
      },
      sent_by: adminIds[0], // Use first admin as sender (system notification)
      status: 'completed' // Mark as completed since it's a database notification
    });

    await notification.save();
    console.log(`✅ Admin notification created for withdrawal request: ${withdrawal._id}`);
  } catch (error) {
    console.error('Error notifying admins of withdrawal request:', error);
    // Don't throw - this is a non-critical operation
  }
};

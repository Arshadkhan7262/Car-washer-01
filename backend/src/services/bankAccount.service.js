import BankAccount from '../models/BankAccount.model.js';
import Washer from '../models/Washer.model.js';
import User from '../models/User.model.js';
import AdminUser from '../models/AdminUser.model.js';
import Notification from '../models/Notification.model.js';
import getStripeInstance from '../config/stripe.config.js';
import AppError from '../errors/AppError.js';

/**
 * Add or update bank account for washer
 */
export const saveBankAccount = async (userId, washerId, bankAccountData) => {
  try {
    const washer = await Washer.findById(washerId);
    if (!washer) {
      throw new AppError('Washer not found', 404);
    }

    // Verify ownership
    if (washer.user_id.toString() !== userId.toString()) {
      throw new AppError('Unauthorized access', 403);
    }

    const {
      account_holder_name,
      account_number,
      routing_number,
      account_type,
      bank_name
    } = bankAccountData;

    // Validate required fields
    if (!account_holder_name || !account_number || !routing_number || !account_type) {
      throw new AppError('All bank account fields are required', 400);
    }

    // Validate routing number (must be 9 digits)
    if (!/^\d{9}$/.test(routing_number)) {
      throw new AppError('Routing number must be 9 digits', 400);
    }

    // Validate account number (must be at least 4 digits)
    if (account_number.length < 4) {
      throw new AppError('Account number must be at least 4 digits', 400);
    }

    // Get last 4 digits for display
    const account_number_last4 = account_number.slice(-4);

    // For now, we'll just store the bank account details
    // In production, you can integrate with Stripe.js on frontend to create tokens securely
    // Or use Stripe Connect Express accounts for automatic payouts
    // For simplicity like other apps, we store details and verify manually/admin processes
    
    // Note: In a real app, you'd use Stripe.js on frontend to create bank account tokens
    // Server-side token creation is not recommended for security reasons
    // For now, we'll mark as verified after admin review or use Stripe Connect
    
    let stripeBankAccountId = null;
    let isVerified = false;

    // If Stripe Connect account exists, we can link bank account there
    // Otherwise, admin will process withdrawals manually or via ACH
    if (washer.stripe_account_id) {
      try {
        const stripe = getStripeInstance();
        // Create external account for Stripe Connect account
        const externalAccount = await stripe.accounts.createExternalAccount(
          washer.stripe_account_id,
          {
            external_account: {
              object: 'bank_account',
              country: 'US',
              currency: 'usd',
              account_holder_name: account_holder_name,
              account_holder_type: 'individual',
              routing_number: routing_number,
              account_number: account_number,
            },
          }
        );
        stripeBankAccountId = externalAccount.id;
        isVerified = true;
      } catch (stripeError) {
        console.error('Stripe bank account creation error:', stripeError);
        // Still save the account details for manual processing
      }
    }

    // Check if bank account already exists
    let bankAccount = await BankAccount.findOne({ washer_id: washerId });

    if (bankAccount) {
      // Update existing account
      bankAccount.account_holder_name = account_holder_name;
      bankAccount.account_number = account_number; // Store encrypted in production
      bankAccount.account_number_last4 = account_number_last4;
      bankAccount.routing_number = routing_number;
      bankAccount.account_type = account_type;
      bankAccount.bank_name = bank_name || null;
      bankAccount.stripe_bank_account_id = stripeBankAccountId;
      bankAccount.status = isVerified ? 'verified' : 'pending';
      bankAccount.is_verified = isVerified;
      await bankAccount.save();
    } else {
      // Create new account
      bankAccount = await BankAccount.create({
        washer_id: washerId,
        user_id: userId,
        account_holder_name,
        account_number, // Store encrypted in production
        account_number_last4,
        routing_number,
        account_type,
        bank_name: bank_name || null,
        stripe_bank_account_id: stripeBankAccountId,
        status: isVerified ? 'verified' : 'pending',
        is_verified: isVerified,
        is_default: true,
      });
    }

    // Update washer to indicate bank account is set up
    washer.stripe_account_onboarding_complete = isVerified;
    await washer.save();

    // Notify admins about new bank account (only for new accounts)
    if (!bankAccount._id || bankAccount.status === 'pending') {
      await notifyAdminsOfBankAccount(bankAccount, washer);
    }

    return bankAccount;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(`Failed to save bank account: ${error.message}`, 500);
  }
};

/**
 * Get bank account for washer
 */
export const getBankAccount = async (userId, washerId) => {
  try {
    const washer = await Washer.findById(washerId);
    if (!washer) {
      throw new AppError('Washer not found', 404);
    }

    // Verify ownership
    if (washer.user_id.toString() !== userId.toString()) {
      throw new AppError('Unauthorized access', 403);
    }

    const bankAccount = await BankAccount.findOne({ washer_id: washerId });

    if (!bankAccount) {
      return null;
    }

    // Return safe data (don't expose full account number)
    return {
      _id: bankAccount._id,
      account_holder_name: bankAccount.account_holder_name,
      account_number_last4: bankAccount.account_number_last4,
      routing_number: bankAccount.routing_number ? '****' + bankAccount.routing_number.slice(-4) : null,
      account_type: bankAccount.account_type,
      bank_name: bankAccount.bank_name,
      is_verified: bankAccount.is_verified,
      status: bankAccount.status,
      created_date: bankAccount.created_date,
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(`Failed to get bank account: ${error.message}`, 500);
  }
};

/**
 * Delete bank account
 */
export const deleteBankAccount = async (userId, washerId) => {
  try {
    const washer = await Washer.findById(washerId);
    if (!washer) {
      throw new AppError('Washer not found', 404);
    }

    // Verify ownership
    if (washer.user_id.toString() !== userId.toString()) {
      throw new AppError('Unauthorized access', 403);
    }

    const bankAccount = await BankAccount.findOne({ washer_id: washerId });
    if (!bankAccount) {
      throw new AppError('Bank account not found', 404);
    }

    // Delete from Stripe if exists
    if (bankAccount.stripe_bank_account_id) {
      try {
        const stripe = getStripeInstance();
        // Note: You'll need to get the customer ID first
        // For now, we'll just delete from database
      } catch (stripeError) {
        console.error('Error deleting Stripe bank account:', stripeError);
      }
    }

    await BankAccount.deleteOne({ _id: bankAccount._id });

    // Update washer
    washer.stripe_account_onboarding_complete = false;
    await washer.save();

    return { success: true };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(`Failed to delete bank account: ${error.message}`, 500);
  }
};

/**
 * Notify admins about new bank account request
 * Creates a notification record that admins can see in the admin panel
 */
const notifyAdminsOfBankAccount = async (bankAccount, washer) => {
  try {
    // Get all active admins
    const admins = await AdminUser.find({ is_active: true }).select('_id email name');
    
    if (admins.length === 0) {
      console.log('No active admins found to notify');
      return;
    }

    const adminIds = admins.map(admin => admin._id);
    const washerName = washer.name || 'Unknown Washer';
    const accountLast4 = bankAccount.account_number_last4 || '****';

    // Create notification record for admins
    const notification = new Notification({
      title: 'New Bank Account Request',
      message: `${washerName} added a bank account ending in ${accountLast4} - requires verification`,
      target_audience: 'specific',
      user_ids: adminIds, // Store admin IDs for reference
      data: {
        type: 'bank_account_request',
        bank_account_id: bankAccount._id.toString(),
        washer_id: washer._id.toString(),
        washer_name: washerName,
        account_last4: accountLast4,
        status: bankAccount.status || 'pending'
      },
      sent_by: adminIds[0], // Use first admin as sender (system notification)
      status: 'completed' // Mark as completed since it's a database notification
    });

    await notification.save();
    console.log(`✅ Admin notification created for bank account: ${bankAccount._id}`);
  } catch (error) {
    console.error('Error notifying admins of bank account:', error);
    // Don't throw - this is a non-critical operation
  }
};

/**
 * Get all bank accounts (Admin only)
 */
export const getAllBankAccounts = async (filters = {}) => {
  try {
    const query = {};
    
    if (filters.status) {
      query.status = filters.status;
    }
    
    if (filters.washer_id) {
      query.washer_id = filters.washer_id;
    }

    const bankAccounts = await BankAccount.find(query)
      .populate('washer_id', 'name email phone status')
      .populate('user_id', 'name email phone')
      .sort('-created_date');

    return bankAccounts.map(account => ({
      _id: account._id,
      washer_id: account.washer_id,
      user_id: account.user_id,
      account_holder_name: account.account_holder_name,
      account_number_last4: account.account_number_last4,
      routing_number: account.routing_number,
      account_type: account.account_type,
      bank_name: account.bank_name,
      is_verified: account.is_verified,
      status: account.status,
      created_date: account.created_date,
      updated_date: account.updated_date,
    }));
  } catch (error) {
    throw new AppError(`Failed to get bank accounts: ${error.message}`, 500);
  }
};

/**
 * Get bank account by ID (Admin only)
 */
export const getBankAccountById = async (bankAccountId) => {
  try {
    const bankAccount = await BankAccount.findById(bankAccountId)
      .populate('washer_id', 'name email phone status')
      .populate('user_id', 'name email phone');

    if (!bankAccount) {
      throw new AppError('Bank account not found', 404);
    }

    return {
      _id: bankAccount._id,
      washer_id: bankAccount.washer_id,
      user_id: bankAccount.user_id,
      account_holder_name: bankAccount.account_holder_name,
      account_number: bankAccount.account_number, // Full number for admin
      account_number_last4: bankAccount.account_number_last4,
      routing_number: bankAccount.routing_number,
      account_type: bankAccount.account_type,
      bank_name: bankAccount.bank_name,
      is_verified: bankAccount.is_verified,
      status: bankAccount.status,
      created_date: bankAccount.created_date,
      updated_date: bankAccount.updated_date,
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(`Failed to get bank account: ${error.message}`, 500);
  }
};

/**
 * Verify bank account (Admin only)
 */
export const verifyBankAccount = async (bankAccountId, adminId) => {
  try {
    const bankAccount = await BankAccount.findById(bankAccountId);
    
    if (!bankAccount) {
      throw new AppError('Bank account not found', 404);
    }

    bankAccount.is_verified = true;
    bankAccount.status = 'verified';
    await bankAccount.save();

    // Update washer
    const washer = await Washer.findById(bankAccount.washer_id);
    if (washer) {
      washer.stripe_account_onboarding_complete = true;
      await washer.save();
    }

    return bankAccount;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(`Failed to verify bank account: ${error.message}`, 500);
  }
};

/**
 * Reject bank account (Admin only)
 */
export const rejectBankAccount = async (bankAccountId, reason, adminId) => {
  try {
    const bankAccount = await BankAccount.findById(bankAccountId);
    
    if (!bankAccount) {
      throw new AppError('Bank account not found', 404);
    }

    bankAccount.is_verified = false;
    bankAccount.status = 'rejected';
    await bankAccount.save();

    // Optionally delete the bank account
    // await BankAccount.deleteOne({ _id: bankAccountId });

    return bankAccount;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(`Failed to reject bank account: ${error.message}`, 500);
  }
};

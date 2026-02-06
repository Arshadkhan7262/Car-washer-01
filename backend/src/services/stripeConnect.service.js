import Washer from '../models/Washer.model.js';
import getStripeInstance from '../config/stripe.config.js';
import AppError from '../errors/AppError.js';

/**
 * Create Stripe Connect Express account for washer
 * This allows washers to receive payouts directly to their bank account
 */
export const createStripeConnectAccount = async (userId, washerId) => {
  try {
    const washer = await Washer.findById(washerId);
    if (!washer) {
      throw new AppError('Washer not found', 404);
    }

    // Verify ownership
    if (washer.user_id.toString() !== userId.toString()) {
      throw new AppError('Unauthorized access', 403);
    }

    // If account already exists, return existing account link
    if (washer.stripe_account_id && washer.stripe_account_status !== 'none') {
      return await getAccountOnboardingLink(washerId, userId);
    }

    const stripe = getStripeInstance();

    // Create Stripe Connect Express account
    const account = await stripe.accounts.create({
      type: 'express',
      country: 'US', // TODO: Get from washer profile or make configurable
      email: washer.email,
      capabilities: {
        transfers: { requested: true },
      },
      metadata: {
        washer_id: washer._id.toString(),
        user_id: userId.toString(),
      },
    });

    // Save account ID to washer
    washer.stripe_account_id = account.id;
    washer.stripe_account_status = account.details_submitted ? 'pending' : 'pending';
    washer.stripe_account_onboarding_complete = false;
    await washer.save();

    // Create account link for onboarding
    const accountLink = await stripe.accountLinks.create({
      account: account.id,
      refresh_url: `${process.env.FRONTEND_URL || 'https://yourapp.com'}/wallet/reauth`,
      return_url: `${process.env.FRONTEND_URL || 'https://yourapp.com'}/wallet/success`,
      type: 'account_onboarding',
    });

    return {
      account_id: account.id,
      onboarding_url: accountLink.url,
      expires_at: accountLink.expires_at,
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(`Failed to create Stripe Connect account: ${error.message}`, 500);
  }
};

/**
 * Get account onboarding link for existing Stripe Connect account
 */
export const getAccountOnboardingLink = async (washerId, userId) => {
  try {
    const washer = await Washer.findById(washerId);
    if (!washer) {
      throw new AppError('Washer not found', 404);
    }

    // Verify ownership
    if (washer.user_id.toString() !== userId.toString()) {
      throw new AppError('Unauthorized access', 403);
    }

    if (!washer.stripe_account_id) {
      throw new AppError('Stripe account not found. Please create one first.', 404);
    }

    const stripe = getStripeInstance();

    // Check account status
    const account = await stripe.accounts.retrieve(washer.stripe_account_id);

    // If account is fully onboarded, return success
    if (account.details_submitted && account.charges_enabled && account.payouts_enabled) {
      washer.stripe_account_status = 'enabled';
      washer.stripe_account_onboarding_complete = true;
      await washer.save();

      return {
        account_id: account.id,
        status: 'complete',
        onboarding_url: null,
        message: 'Account is already set up and ready to receive payouts',
      };
    }

    // Create new onboarding link
    const accountLink = await stripe.accountLinks.create({
      account: washer.stripe_account_id,
      refresh_url: `${process.env.FRONTEND_URL || 'https://yourapp.com'}/wallet/reauth`,
      return_url: `${process.env.FRONTEND_URL || 'https://yourapp.com'}/wallet/success`,
      type: account.details_submitted ? 'account_update' : 'account_onboarding',
    });

    // Update status
    washer.stripe_account_status = account.details_submitted ? 'restricted' : 'pending';
    await washer.save();

    return {
      account_id: account.id,
      onboarding_url: accountLink.url,
      expires_at: accountLink.expires_at,
      status: washer.stripe_account_status,
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(`Failed to get onboarding link: ${error.message}`, 500);
  }
};

/**
 * Check Stripe Connect account status
 */
export const getAccountStatus = async (washerId, userId) => {
  try {
    const washer = await Washer.findById(washerId);
    if (!washer) {
      throw new AppError('Washer not found', 404);
    }

    // Verify ownership
    if (washer.user_id.toString() !== userId.toString()) {
      throw new AppError('Unauthorized access', 403);
    }

    if (!washer.stripe_account_id) {
      return {
        has_account: false,
        status: 'none',
        can_withdraw: false,
        message: 'Please set up your bank account to receive payouts',
      };
    }

    const stripe = getStripeInstance();
    const account = await stripe.accounts.retrieve(washer.stripe_account_id);

    // Update washer status based on Stripe account status
    let status = 'pending';
    let canWithdraw = false;

    if (account.details_submitted && account.charges_enabled && account.payouts_enabled) {
      status = 'enabled';
      canWithdraw = true;
    } else if (account.details_submitted) {
      status = 'restricted';
      canWithdraw = false;
    }

    washer.stripe_account_status = status;
    washer.stripe_account_onboarding_complete = canWithdraw;
    await washer.save();

    return {
      has_account: true,
      account_id: account.id,
      status: status,
      can_withdraw: canWithdraw,
      details_submitted: account.details_submitted,
      charges_enabled: account.charges_enabled,
      payouts_enabled: account.payouts_enabled,
      message: canWithdraw
        ? 'Your account is ready to receive payouts'
        : 'Please complete your account setup to receive payouts',
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(`Failed to get account status: ${error.message}`, 500);
  }
};

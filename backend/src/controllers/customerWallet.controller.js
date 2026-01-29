import User from '../models/User.model.js';
import AppError from '../errors/AppError.js';
import Stripe from 'stripe';

const stripe = process.env.STRIPE_SECRET_KEY ? new Stripe(process.env.STRIPE_SECRET_KEY) : null;

/**
 * Get customer wallet balance
 * GET /api/v1/customer/wallet/balance
 */
export const getWalletBalance = async (req, res, next) => {
  try {
    const userId = req.customer?.id;
    if (!userId) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }
    const user = await User.findById(userId).select('wallet_balance').lean();
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    const balance = user.wallet_balance ?? 0;
    return res.status(200).json({
      success: true,
      data: { wallet_balance: balance },
    });
  } catch (error) {
    console.error('❌ [Wallet Controller] getWalletBalance error:', error);
    next(error);
  }
};

/**
 * Add funds to customer wallet
 * POST /api/v1/customer/wallet/add-funds
 * Body: { amount: number, payment_intent_id?: string, transaction_id?: string, is_dummy?: boolean }
 * - For real Stripe: send amount + payment_intent_id (and optionally transaction_id).
 * - For dummy/test: send amount + is_dummy: true (no Stripe; credits wallet for testing).
 */
export const addFundsToWallet = async (req, res, next) => {
  try {
    const { amount, payment_intent_id, transaction_id, is_dummy } = req.body;
    const userId = req.customer?.id;
    if (!userId) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    console.log('🔄 [Wallet Controller] Adding funds to wallet:', {
      amount,
      payment_intent_id: payment_intent_id || 'none',
      transaction_id: transaction_id || 'none',
      is_dummy: !!is_dummy,
      userId,
    });

    // Validate amount
    const numAmount = typeof amount === 'string' ? parseFloat(amount) : Number(amount);
    if (numAmount == null || isNaN(numAmount) || numAmount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid amount. Amount must be greater than 0',
      });
    }
    if (numAmount < 5) {
      return res.status(400).json({
        success: false,
        message: 'Minimum amount to add is $5.00',
      });
    }

    // Verify payment intent with Stripe only when not dummy and payment_intent_id is provided
    if (!is_dummy && payment_intent_id && stripe) {
      try {
        const paymentIntent = await stripe.paymentIntents.retrieve(payment_intent_id);

        if (paymentIntent.status !== 'succeeded') {
          return res.status(400).json({
            success: false,
            message: 'Payment not completed. Payment status: ' + paymentIntent.status,
          });
        }

        const paidAmount = paymentIntent.amount / 100;
        if (Math.abs(paidAmount - numAmount) > 0.01) {
          return res.status(400).json({
            success: false,
            message: `Payment amount mismatch. Paid: $${paidAmount.toFixed(2)}, Requested: $${numAmount.toFixed(2)}`,
          });
        }

        console.log('✅ [Wallet Controller] Payment intent verified:', {
          payment_intent_id,
          paidAmount,
          status: paymentIntent.status,
        });
      } catch (stripeError) {
        console.error('❌ [Wallet Controller] Stripe verification error:', stripeError);
        return res.status(400).json({
          success: false,
          message: 'Payment verification failed. Please try again.',
        });
      }
    }

    if (is_dummy) {
      console.log('📌 [Wallet Controller] Dummy add-funds: crediting wallet without Stripe');
    }

    // Get user
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    // Add funds to wallet
    const currentBalance = user.wallet_balance || 0;
    const newBalance = currentBalance + numAmount;
    user.wallet_balance = newBalance;
    await user.save();

    // Generate transaction ID if not provided
    const finalTransactionId = transaction_id || `ADD_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    console.log('✅ [Wallet Controller] Funds added to wallet:', {
      transactionId: finalTransactionId,
      amount: numAmount,
      previousBalance: currentBalance,
      newBalance,
      is_dummy: !!is_dummy,
    });

    res.status(200).json({
      success: true,
      message: 'Funds added to wallet successfully',
      data: {
        amount: numAmount,
        wallet_balance: newBalance,
        previous_balance: currentBalance,
        transaction_id: finalTransactionId,
      },
    });
  } catch (error) {
    console.error('❌ [Wallet Controller] Error:', error);
    next(error);
  }
};


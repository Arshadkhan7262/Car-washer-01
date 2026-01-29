import * as paymentService from '../services/payment.service.js';
import AppError from '../errors/AppError.js';
import User from '../models/User.model.js';

/**
 * Create a payment intent
 * POST /api/v1/customer/payment/create-intent
 */
export const createPaymentIntent = async (req, res, next) => {
  try {
    const { amount, currency, customerId, metadata } = req.body;
    
    console.log('🔄 [Payment Controller] Creating payment intent request:', {
      amount,
      currency,
      customerId: customerId || 'none',
    });
    
    // Validate required fields
    if (!amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Amount is required and must be greater than 0'
      });
    }
    
    // Amount from Flutter is already in cents (amount * 100)
    const paymentIntent = await paymentService.createPaymentIntent({
      amount: parseFloat(amount), // Already in cents from Flutter
      currency: currency || 'usd',
      customerId,
      metadata: {
        ...metadata,
        user_id: req.user?.id || req.user?._id,
      },
    });
    
    res.status(201).json({
      success: true,
      message: 'Payment intent created successfully',
      data: paymentIntent,
    });
  } catch (error) {
    console.error('❌ [Payment Controller] Error:', error);
    next(error);
  }
};

/**
 * Confirm a payment intent
 * POST /api/v1/customer/payment/confirm
 */
export const confirmPayment = async (req, res, next) => {
  try {
    const { payment_intent_id, paymentIntentId } = req.body;
    
    // Support both naming conventions
    const intentId = payment_intent_id || paymentIntentId;
    
    if (!intentId) {
      return res.status(400).json({
        success: false,
        message: 'Payment intent ID is required'
      });
    }
    
    console.log('🔄 [Payment Controller] Confirming payment:', intentId);
    
    const paymentIntent = await paymentService.confirmPaymentIntent(intentId);
    
    res.status(200).json({
      success: true,
      message: 'Payment confirmed successfully',
      data: paymentIntent,
    });
  } catch (error) {
    console.error('❌ [Payment Controller] Error:', error);
    next(error);
  }
};

/**
 * Get payment intent details
 * GET /api/v1/customer/payment/intent/:id
 */
export const getPaymentIntent = async (req, res, next) => {
  try {
    const { id } = req.params;
    
    if (!id) {
      return res.status(400).json({
        success: false,
        message: 'Payment intent ID is required'
      });
    }
    
    const paymentIntent = await paymentService.getPaymentIntent(id);
    
    res.status(200).json({
      success: true,
      message: 'Payment intent retrieved successfully',
      data: paymentIntent,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Process wallet payment - deduct from customer wallet
 * POST /api/v1/customer/payment/wallet
 */
export const processWalletPayment = async (req, res, next) => {
  try {
    const { amount, currency = 'USD', booking_id } = req.body;
    const userId = req.user.id;

    console.log('🔄 [Payment Controller] Processing wallet payment:', {
      amount,
      currency,
      booking_id: booking_id || 'none',
      userId,
    });

    // Validate amount
    if (!amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid payment amount. Amount must be greater than 0',
      });
    }

    // Get user with wallet balance
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    const currentBalance = user.wallet_balance || 0;

    // Check sufficient balance
    if (currentBalance < amount) {
      return res.status(400).json({
        success: false,
        message: `Insufficient wallet balance. Current balance: $${currentBalance.toFixed(2)}, Required: $${amount.toFixed(2)}`,
      });
    }

    // Deduct amount from wallet
    const newBalance = currentBalance - amount;
    user.wallet_balance = newBalance;
    await user.save();

    // Generate transaction ID
    const transactionId = `WLT_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    console.log('✅ [Payment Controller] Wallet payment processed:', {
      transactionId,
      amount,
      previousBalance: currentBalance,
      newBalance,
    });

    res.status(200).json({
      success: true,
      message: 'Wallet payment processed successfully',
      data: {
        transaction_id: transactionId,
        amount: amount,
        currency: currency,
        wallet_balance: newBalance,
        previous_balance: currentBalance,
        booking_id: booking_id || null,
      },
    });
  } catch (error) {
    console.error('❌ [Payment Controller] Wallet payment error:', error);
    next(error);
  }
};


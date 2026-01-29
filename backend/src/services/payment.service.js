import getStripeInstance, { getStripeAccountIdPrefix } from '../config/stripe.config.js';
import AppError from '../errors/AppError.js';

/**
 * Create a payment intent for Stripe
 */
export const createPaymentIntent = async (params) => {
  try {
    const stripe = getStripeInstance();
    
    const { amount, currency = 'usd', customerId, metadata = {} } = params;
    
    // Validate amount
    if (amount <= 0) {
      throw new AppError('Amount must be greater than 0', 400);
    }
    
    // Amount from Flutter is already in cents (Flutter sends amount * 100)
    // So we use it directly as Stripe expects cents
    const amountInCents = Math.round(amount);
    
    // Ensure minimum amount (Stripe requires at least $0.50 or equivalent)
    if (amountInCents < 50) {
      throw new AppError('Amount must be at least $0.50', 400);
    }
    
    console.log('🔄 [Payment Service] Creating payment intent:', {
      amount: amountInCents,
      currency: currency.toLowerCase(),
      customerId: customerId || 'none',
    });
    
    // Create payment intent with Payment Sheet support
    // Note: Use automatic_payment_methods OR payment_method_types, not both
    // automatic_payment_methods enables all available methods (card, Apple Pay, Google Pay, etc.)
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amountInCents,
      currency: currency.toLowerCase(),
      customer: customerId || undefined,
      metadata: {
        ...metadata,
        created_at: new Date().toISOString(),
        source: 'mobile_app',
      },
      // Enable automatic payment methods for Payment Sheet
      // This will automatically enable card, Apple Pay, Google Pay, and other available methods
      automatic_payment_methods: {
        enabled: true,
      },
    });
    
    console.log('✅ [Payment Service] Payment intent created:', {
      id: paymentIntent.id,
      status: paymentIntent.status,
      amount: paymentIntent.amount,
    });
    
    const result = {
      client_secret: paymentIntent.client_secret,
      payment_intent_id: paymentIntent.id,
      amount: paymentIntent.amount / 100, // Convert back to dollars
      currency: paymentIntent.currency,
      status: paymentIntent.status,
      // So app can show which Stripe account backend used (fix "No such payment_intent" key mismatch)
      _stripe_account: getStripeAccountIdPrefix(),
    };
    return result;
  } catch (error) {
    console.error('❌ [Payment Service] Error creating payment intent:', error);
    
    if (error instanceof AppError) {
      throw error;
    }
    
    // Handle Stripe-specific errors
    if (error.type === 'StripeCardError') {
      throw new AppError(error.message || 'Card error occurred', 400);
    }
    
    throw new AppError(
      error.message || 'Failed to create payment intent',
      error.statusCode || 500
    );
  }
};

/**
 * Confirm a payment intent
 */
export const confirmPaymentIntent = async (paymentIntentId) => {
  try {
    const stripe = getStripeInstance();
    
    console.log('🔄 [Payment Service] Confirming payment intent:', paymentIntentId);
    
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);
    
    console.log('✅ [Payment Service] Payment intent status:', paymentIntent.status);
    
    return {
      id: paymentIntent.id,
      status: paymentIntent.status,
      amount: paymentIntent.amount / 100,
      currency: paymentIntent.currency,
      payment_method: paymentIntent.payment_method,
    };
  } catch (error) {
    console.error('❌ [Payment Service] Error confirming payment intent:', error);
    throw new AppError(
      error.message || 'Failed to confirm payment intent',
      error.statusCode || 500
    );
  }
};

/**
 * Retrieve payment intent details
 */
export const getPaymentIntent = async (paymentIntentId) => {
  try {
    const stripe = getStripeInstance();
    
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);
    
    return {
      id: paymentIntent.id,
      status: paymentIntent.status,
      amount: paymentIntent.amount / 100,
      currency: paymentIntent.currency,
      client_secret: paymentIntent.client_secret,
      metadata: paymentIntent.metadata,
    };
  } catch (error) {
    console.error('Error retrieving payment intent:', error);
    throw new AppError(
      error.message || 'Failed to retrieve payment intent',
      error.statusCode || 500
    );
  }
};


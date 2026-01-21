import getStripeInstance from '../config/stripe.config.js';
import { AppError } from '../errors/AppError.js';

export interface CreatePaymentIntentParams {
  amount: number; // Amount in cents
  currency?: string;
  customerId?: string;
  metadata?: Record<string, string>;
}

export interface PaymentIntentResponse {
  client_secret: string;
  payment_intent_id: string;
  amount: number;
  currency: string;
  status: string;
}

/**
 * Create a payment intent for Stripe
 */
export const createPaymentIntent = async (
  params: CreatePaymentIntentParams
): Promise<PaymentIntentResponse> => {
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
    
    // Create payment intent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amountInCents,
      currency: currency.toLowerCase(),
      customer: customerId,
      metadata: {
        ...metadata,
        created_at: new Date().toISOString(),
      },
      automatic_payment_methods: {
        enabled: true,
      },
    });
    
    return {
      client_secret: paymentIntent.client_secret!,
      payment_intent_id: paymentIntent.id,
      amount: paymentIntent.amount / 100, // Convert back to dollars
      currency: paymentIntent.currency,
      status: paymentIntent.status,
    };
  } catch (error: any) {
    console.error('Error creating payment intent:', error);
    
    if (error instanceof AppError) {
      throw error;
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
export const confirmPaymentIntent = async (
  paymentIntentId: string
): Promise<any> => {
  try {
    const stripe = getStripeInstance();
    
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);
    
    return {
      id: paymentIntent.id,
      status: paymentIntent.status,
      amount: paymentIntent.amount / 100,
      currency: paymentIntent.currency,
    };
  } catch (error: any) {
    console.error('Error confirming payment intent:', error);
    throw new AppError(
      error.message || 'Failed to confirm payment intent',
      error.statusCode || 500
    );
  }
};

/**
 * Retrieve payment intent details
 */
export const getPaymentIntent = async (
  paymentIntentId: string
): Promise<any> => {
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
  } catch (error: any) {
    console.error('Error retrieving payment intent:', error);
    throw new AppError(
      error.message || 'Failed to retrieve payment intent',
      error.statusCode || 500
    );
  }
};


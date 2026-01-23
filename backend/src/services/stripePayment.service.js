/**
 * Stripe Payment Service
 * Handles all Stripe payment operations
 */

import Stripe from 'stripe';
import Payment from '../models/Payment.model.js';
import User from '../models/User.model.js';
import Booking from '../models/Booking.model.js';
import Washer from '../models/Washer.model.js';
import AppError from '../errors/AppError.js';

// Initialize Stripe with secret key from environment
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || '', {
  apiVersion: '2024-12-18.acacia',
});

/**
 * Get Stripe Publishable Key
 * Returns the publishable key for Flutter app
 */
export const getPublishableKey = () => {
  const publishableKey = process.env.STRIPE_PUBLISHABLE_KEY;
  
  if (!publishableKey) {
    throw new AppError('Stripe publishable key not configured', 500);
  }
  
  return {
    publishableKey
  };
};

/**
 * Create Stripe Customer
 * Creates a customer in Stripe and saves the ID to MongoDB
 */
export const createStripeCustomer = async (userId, email, name, role = 'customer') => {
  try {
    // Validate inputs
    if (!userId || !email || !name) {
      throw new AppError('userId, email, and name are required', 400);
    }

    // Check if user already has a Stripe customer ID
    const user = await User.findById(userId);
    if (!user) {
      throw new AppError('User not found', 404);
    }

    if (user.stripeCustomerId) {
      return {
        stripeCustomerId: user.stripeCustomerId,
        message: 'Customer already exists in Stripe'
      };
    }

    // Create customer in Stripe
    const customer = await stripe.customers.create({
      email: email.toLowerCase(),
      name: name,
      metadata: {
        userId: userId.toString(),
        role: role
      }
    });

    // Save Stripe customer ID to user
    user.stripeCustomerId = customer.id;
    await user.save();

    return {
      stripeCustomerId: customer.id,
      message: 'Stripe customer created successfully'
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    
    // Handle Stripe errors
    if (error.type === 'StripeInvalidRequestError') {
      throw new AppError(`Stripe error: ${error.message}`, 400);
    }
    
    throw new AppError(`Failed to create Stripe customer: ${error.message}`, 500);
  }
};

/**
 * Create Payment Intent
 * Creates a Stripe PaymentIntent for a booking
 */
export const createPaymentIntent = async ({
  stripeCustomerId,
  amount,
  currency = 'usd',
  bookingId,
  washerId = null,
  metadata = {}
}) => {
  try {
    // Validate inputs
    if (!stripeCustomerId || !amount || !bookingId) {
      throw new AppError('stripeCustomerId, amount, and bookingId are required', 400);
    }

    // Validate amount (must be positive integer in smallest currency unit)
    if (amount <= 0 || !Number.isInteger(amount)) {
      throw new AppError('Amount must be a positive integer (in cents)', 400);
    }

    // Get booking details
    const booking = await Booking.findById(bookingId)
      .populate('customer_id', 'name email')
      .populate('washer_id', 'name')
      .lean();

    if (!booking) {
      throw new AppError('Booking not found', 404);
    }

    // Get customer info
    const customer = booking.customer_id;
    const washer = booking.washer_id;

    // Create PaymentIntent in Stripe
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: currency.toLowerCase(),
      customer: stripeCustomerId,
      automatic_payment_methods: {
        enabled: true,
      },
      metadata: {
        bookingId: bookingId.toString(),
        bookingReference: booking.booking_id || '',
        customerId: customer._id.toString(),
        customerName: customer.name || '',
        washerId: washerId ? washerId.toString() : (washer?._id?.toString() || ''),
        ...metadata
      },
      description: `Payment for booking ${booking.booking_id || bookingId}`,
    });

    // Create payment record in MongoDB
    const payment = await Payment.create({
      stripePaymentIntentId: paymentIntent.id,
      stripeCustomerId: stripeCustomerId,
      booking_id: bookingId,
      booking_reference: booking.booking_id || '',
      customer_id: customer._id,
      customer_name: customer.name || '',
      customer_email: customer.email || '',
      washer_id: washerId || (washer?._id || null),
      washer_name: washer?.name || null,
      amount: amount,
      currency: currency.toLowerCase(),
      payment_method: 'card',
      status: 'pending',
      metadata: new Map(Object.entries(metadata))
    });

    return {
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
      paymentId: payment._id.toString()
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    
    // Handle Stripe errors
    if (error.type === 'StripeInvalidRequestError') {
      throw new AppError(`Stripe error: ${error.message}`, 400);
    }
    
    throw new AppError(`Failed to create payment intent: ${error.message}`, 500);
  }
};

/**
 * Confirm Payment Success
 * Updates payment status and triggers wallet updates
 */
export const confirmPaymentSuccess = async (paymentIntentId) => {
  try {
    // Find payment by Stripe PaymentIntent ID
    const payment = await Payment.findOne({ stripePaymentIntentId: paymentIntentId });
    
    if (!payment) {
      throw new AppError('Payment not found', 404);
    }

    // Get payment intent from Stripe to verify status
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

    if (paymentIntent.status !== 'succeeded') {
      throw new AppError(`Payment not succeeded. Status: ${paymentIntent.status}`, 400);
    }

    // Update payment record
    payment.status = 'succeeded';
    payment.stripeChargeId = paymentIntent.latest_charge || null;
    payment.paid_at = new Date();
    await payment.save();

    // Update booking payment status
    const booking = await Booking.findById(payment.booking_id);
    if (booking) {
      booking.payment_status = 'paid';
      booking.payment_method = 'card';
      await booking.save();
    }

    // If washer is assigned, update washer wallet when job is completed
    // (Wallet is updated when job status changes to 'completed' in washerJobs.service.js)
    
    return {
      success: true,
      payment: payment,
      booking: booking
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(`Failed to confirm payment: ${error.message}`, 500);
  }
};

/**
 * Handle Payment Failure
 * Updates payment status to failed
 */
export const handlePaymentFailure = async (paymentIntentId, errorMessage) => {
  try {
    const payment = await Payment.findOne({ stripePaymentIntentId: paymentIntentId });
    
    if (!payment) {
      throw new AppError('Payment not found', 404);
    }

    payment.status = 'failed';
    payment.error_message = errorMessage || 'Payment failed';
    await payment.save();

    return payment;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError(`Failed to handle payment failure: ${error.message}`, 500);
  }
};

/**
 * Get Payment History for Customer
 * Returns all payments for a Stripe customer
 */
export const getCustomerPaymentHistory = async (stripeCustomerId, filters = {}) => {
  try {
    const {
      page = 1,
      limit = 20,
      sort = '-created_date'
    } = filters;

    const query = { stripeCustomerId };

    // Parse sort
    const sortField = sort.startsWith('-') ? sort.substring(1) : sort;
    const sortOrder = sort.startsWith('-') ? -1 : 1;
    const sortObj = { [sortField]: sortOrder };

    // Calculate pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const payments = await Payment.find(query)
      .select('stripePaymentIntentId amount currency status booking_reference created_date paid_at')
      .sort(sortObj)
      .skip(skip)
      .limit(parseInt(limit))
      .lean();

    const total = await Payment.countDocuments(query);

    // Format response
    const formattedPayments = payments.map(payment => ({
      paymentId: payment.stripePaymentIntentId,
      amount: payment.amount,
      currency: payment.currency,
      status: payment.status,
      bookingId: payment.booking_reference,
      createdAt: payment.created_date,
      paidAt: payment.paid_at
    }));

    return {
      payments: formattedPayments,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        totalPages: Math.ceil(total / parseInt(limit))
      }
    };
  } catch (error) {
    throw new AppError(`Failed to fetch payment history: ${error.message}`, 500);
  }
};

/**
 * Get Washer Earnings History
 * Returns all payments where washer received earnings
 */
export const getWasherEarningsHistory = async (washerId, filters = {}) => {
  try {
    const {
      page = 1,
      limit = 20,
      sort = '-created_date'
    } = filters;

    const query = { 
      washer_id: washerId,
      status: 'succeeded'
    };

    // Parse sort
    const sortField = sort.startsWith('-') ? sort.substring(1) : sort;
    const sortOrder = sort.startsWith('-') ? -1 : 1;
    const sortObj = { [sortField]: sortOrder };

    // Calculate pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const payments = await Payment.find(query)
      .populate('customer_id', 'name')
      .select('amount currency customer_name booking_reference created_date paid_at')
      .sort(sortObj)
      .skip(skip)
      .limit(parseInt(limit))
      .lean();

    const total = await Payment.countDocuments(query);

    // Format response
    const formattedEarnings = payments.map(payment => ({
      paymentId: payment.stripePaymentIntentId,
      amount: payment.amount,
      currency: payment.currency,
      customerName: payment.customer_name,
      bookingId: payment.booking_reference,
      createdAt: payment.created_date,
      paidAt: payment.paid_at
    }));

    return {
      earnings: formattedEarnings,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        totalPages: Math.ceil(total / parseInt(limit))
      }
    };
  } catch (error) {
    throw new AppError(`Failed to fetch washer earnings: ${error.message}`, 500);
  }
};

/**
 * Get All Payments (Admin)
 * Returns all payments with filters
 */
export const getAllPayments = async (filters = {}) => {
  try {
    const {
      status,
      paymentMethod,
      customerId,
      washerId,
      dateFrom,
      dateTo,
      page = 1,
      limit = 50,
      sort = '-created_date'
    } = filters;

    const query = {};

    if (status) {
      query.status = status;
    }

    if (paymentMethod) {
      query.payment_method = paymentMethod;
    }

    if (customerId) {
      query.customer_id = customerId;
    }

    if (washerId) {
      query.washer_id = washerId;
    }

    if (dateFrom || dateTo) {
      query.created_date = {};
      if (dateFrom) {
        query.created_date.$gte = new Date(dateFrom);
      }
      if (dateTo) {
        const endDate = new Date(dateTo);
        endDate.setHours(23, 59, 59, 999);
        query.created_date.$lte = endDate;
      }
    }

    // Parse sort
    const sortField = sort.startsWith('-') ? sort.substring(1) : sort;
    const sortOrder = sort.startsWith('-') ? -1 : 1;
    const sortObj = { [sortField]: sortOrder };

    // Calculate pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const payments = await Payment.find(query)
      .populate('customer_id', 'name email')
      .populate('washer_id', 'name')
      .populate('booking_id', 'booking_id service_name')
      .sort(sortObj)
      .skip(skip)
      .limit(parseInt(limit))
      .lean();

    const total = await Payment.countDocuments(query);

    return {
      payments,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        totalPages: Math.ceil(total / parseInt(limit))
      }
    };
  } catch (error) {
    throw new AppError(`Failed to fetch payments: ${error.message}`, 500);
  }
};

/**
 * Process Stripe Webhook
 * Handles Stripe webhook events
 */
export const processWebhook = async (event) => {
  try {
    switch (event.type) {
      case 'payment_intent.succeeded':
        await confirmPaymentSuccess(event.data.object.id);
        break;
      
      case 'payment_intent.payment_failed':
        await handlePaymentFailure(
          event.data.object.id,
          event.data.object.last_payment_error?.message || 'Payment failed'
        );
        break;
      
      case 'payment_intent.canceled':
        const payment = await Payment.findOne({ 
          stripePaymentIntentId: event.data.object.id 
        });
        if (payment) {
          payment.status = 'canceled';
          await payment.save();
        }
        break;
      
      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    return { received: true };
  } catch (error) {
    throw new AppError(`Webhook processing failed: ${error.message}`, 500);
  }
};

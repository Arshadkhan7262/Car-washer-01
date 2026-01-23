/**
 * Stripe Payment Controller
 * Handles all payment-related HTTP requests
 */

import * as stripePaymentService from '../services/stripePayment.service.js';
import AppError from '../errors/AppError.js';
import User from '../models/User.model.js';

/**
 * @desc    Get Stripe Publishable Key
 * @route   GET /api/stripe/publishable-key
 * @access  Public
 */
export const getPublishableKey = async (req, res, next) => {
  try {
    const result = stripePaymentService.getPublishableKey();
    
    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Create Stripe Customer
 * @route   POST /api/stripe/customer
 * @access  Private (Customer)
 */
export const createStripeCustomer = async (req, res, next) => {
  try {
    const { userId, email, name, role } = req.body;
    const authenticatedUserId = req.customer?._id || req.user?._id;

    // Use authenticated user ID if not provided in body
    const targetUserId = userId || authenticatedUserId?.toString();

    if (!targetUserId) {
      throw new AppError('User ID is required', 400);
    }

    // Get user details if not provided
    let userEmail = email;
    let userName = name;
    let userRole = role || 'customer';

    if (!userEmail || !userName) {
      const user = await User.findById(targetUserId);
      if (!user) {
        throw new AppError('User not found', 404);
      }
      userEmail = userEmail || user.email;
      userName = userName || user.name;
      userRole = user.role || 'customer';
    }

    if (!userEmail || !userName) {
      throw new AppError('Email and name are required', 400);
    }

    const result = await stripePaymentService.createStripeCustomer(
      targetUserId,
      userEmail,
      userName,
      userRole
    );

    res.status(201).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Create Payment Intent
 * @route   POST /api/stripe/create-payment-intent
 * @access  Private (Customer)
 */
export const createPaymentIntent = async (req, res, next) => {
  try {
    const { stripeCustomerId, amount, currency, bookingId, washerId, adminId } = req.body;
    const authenticatedCustomer = req.customer;

    // Validate required fields
    if (!stripeCustomerId || !amount || !bookingId) {
      throw new AppError('stripeCustomerId, amount, and bookingId are required', 400);
    }

    // Validate amount (must be positive integer)
    if (amount <= 0 || !Number.isInteger(amount)) {
      throw new AppError('Amount must be a positive integer (in cents)', 400);
    }

    // Get customer's Stripe ID if not provided
    let customerStripeId = stripeCustomerId;
    if (!customerStripeId && authenticatedCustomer) {
      const user = await User.findById(authenticatedCustomer._id);
      if (user && user.stripeCustomerId) {
        customerStripeId = user.stripeCustomerId;
      } else {
        throw new AppError('Stripe customer ID not found. Please create a Stripe customer first.', 400);
      }
    }

    const result = await stripePaymentService.createPaymentIntent({
      stripeCustomerId: customerStripeId,
      amount: parseInt(amount),
      currency: currency || 'usd',
      bookingId,
      washerId: washerId || null,
      metadata: {
        adminId: adminId || '',
        ...req.body.metadata
      }
    });

    res.status(201).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get Customer Payment History
 * @route   GET /api/stripe/payment-history/:stripeCustomerId
 * @access  Private (Customer)
 */
export const getCustomerPaymentHistory = async (req, res, next) => {
  try {
    const { stripeCustomerId } = req.params;
    const authenticatedCustomer = req.customer;

    // Get customer's Stripe ID if not provided in params
    let customerStripeId = stripeCustomerId;
    if (!customerStripeId && authenticatedCustomer) {
      const user = await User.findById(authenticatedCustomer._id);
      if (user && user.stripeCustomerId) {
        customerStripeId = user.stripeCustomerId;
      } else {
        throw new AppError('Stripe customer ID not found', 404);
      }
    }

    if (!customerStripeId) {
      throw new AppError('Stripe customer ID is required', 400);
    }

    const { page, limit, sort } = req.query;
    const result = await stripePaymentService.getCustomerPaymentHistory(customerStripeId, {
      page,
      limit,
      sort
    });

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get Washer Earnings History
 * @route   GET /api/washer/earnings/:washerId
 * @access  Private (Washer)
 */
export const getWasherEarningsHistory = async (req, res, next) => {
  try {
    const { washerId } = req.params;
    const authenticatedWasher = req.washer;

    // Use authenticated washer ID if not provided
    const targetWasherId = washerId || authenticatedWasher?.washer_id;

    if (!targetWasherId) {
      throw new AppError('Washer ID is required', 400);
    }

    const { page, limit, sort } = req.query;
    const result = await stripePaymentService.getWasherEarningsHistory(targetWasherId, {
      page,
      limit,
      sort
    });

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get All Payments (Admin)
 * @route   GET /api/admin/payments
 * @access  Private (Admin)
 */
export const getAllPayments = async (req, res, next) => {
  try {
    const {
      status,
      paymentMethod,
      customerId,
      washerId,
      dateFrom,
      dateTo,
      page,
      limit,
      sort
    } = req.query;

    const result = await stripePaymentService.getAllPayments({
      status,
      paymentMethod,
      customerId,
      washerId,
      dateFrom,
      dateTo,
      page,
      limit,
      sort
    });

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Handle Stripe Webhook
 * @route   POST /api/stripe/webhook
 * @access  Public (Stripe)
 */
export const handleWebhook = async (req, res, next) => {
  try {
    const sig = req.headers['stripe-signature'];
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

    let event;

    try {
      // Verify webhook signature if webhook secret is configured
      if (webhookSecret) {
        const stripe = (await import('stripe')).default;
        const stripeInstance = new stripe(process.env.STRIPE_SECRET_KEY || '', {
          apiVersion: '2024-12-18.acacia',
        });
        event = stripeInstance.webhooks.constructEvent(req.body, sig, webhookSecret);
      } else {
        // In development, parse event without verification
        event = req.body;
      }
    } catch (err) {
      console.error('Webhook signature verification failed:', err.message);
      return res.status(400).json({ error: `Webhook Error: ${err.message}` });
    }

    // Process webhook event
    await stripePaymentService.processWebhook(event);

    res.status(200).json({ received: true });
  } catch (error) {
    next(error);
  }
};

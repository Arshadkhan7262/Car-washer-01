import express from 'express';
import * as stripePaymentController from '../controllers/stripePayment.controller.js';
import { protectCustomer } from '../middleware/auth.middleware.js';
import { protectWasher } from '../middleware/auth.middleware.js';
import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

/**
 * Stripe Payment Routes
 * 
 * Public Routes:
 * - GET /publishable-key - Get Stripe publishable key
 * - POST /webhook - Stripe webhook handler (uses raw body)
 * 
 * Customer Routes (require authentication):
 * - POST /customer - Create Stripe customer
 * - POST /create-payment-intent - Create payment intent
 * - GET /payment-history/:stripeCustomerId - Get payment history
 * 
 * Washer Routes (require authentication):
 * - GET /washer/earnings/:washerId - Get earnings history
 * 
 * Admin Routes (require authentication):
 * - GET /admin/payments - Get all payments
 */

// Public routes
router.get('/publishable-key', stripePaymentController.getPublishableKey);

// Webhook route (must be before body parser middleware in server.js)
// This route should use express.raw() middleware for body parsing
router.post('/webhook', stripePaymentController.handleWebhook);

// Customer routes (require customer authentication)
router.post('/customer', protectCustomer, stripePaymentController.createStripeCustomer);
router.post('/create-payment-intent', protectCustomer, stripePaymentController.createPaymentIntent);
router.get('/payment-history/:stripeCustomerId', protectCustomer, stripePaymentController.getCustomerPaymentHistory);

// Washer routes (require washer authentication)
router.get('/washer/earnings/:washerId', protectWasher, stripePaymentController.getWasherEarningsHistory);

// Admin routes (require admin authentication)
router.get('/admin/payments', protect, stripePaymentController.getAllPayments);

export default router;

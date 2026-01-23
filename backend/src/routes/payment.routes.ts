import express from 'express';
import * as paymentController from '../controllers/payment.controller.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = express.Router();

/**
 * @route   POST /api/v1/payments/create-intent
 * @desc    Create a payment intent for Stripe
 * @access  Private (requires authentication)
 * @body    { amount: number, currency?: string, customerId?: string, metadata?: object }
 */
router.post(
  '/create-intent',
  authenticate,
  paymentController.createPaymentIntent
);

/**
 * @route   POST /api/v1/payments/confirm
 * @desc    Confirm a payment intent
 * @access  Private (requires authentication)
 * @body    { paymentIntentId: string }
 */
router.post(
  '/confirm',
  authenticate,
  paymentController.confirmPayment
);

/**
 * @route   GET /api/v1/payments/intent/:id
 * @desc    Get payment intent details
 * @access  Private (requires authentication)
 */
router.get(
  '/intent/:id',
  authenticate,
  paymentController.getPaymentIntent
);

export default router;


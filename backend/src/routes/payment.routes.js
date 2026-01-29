import express from 'express';
import * as paymentController from '../controllers/payment.controller.js';
import { protectCustomer } from '../middleware/auth.middleware.js';

const router = express.Router();

/**
 * @route   POST /api/v1/customer/payment/create-intent
 * @desc    Create a payment intent for Stripe
 * @access  Private (requires authentication)
 * @body    { amount: number, currency?: string, customerId?: string, metadata?: object }
 */
router.post(
  '/create-intent',
  protectCustomer,
  paymentController.createPaymentIntent
);

/**
 * @route   POST /api/v1/customer/payment/confirm
 * @desc    Confirm a payment intent
 * @access  Private (requires authentication)
 * @body    { paymentIntentId: string }
 */
router.post(
  '/confirm',
  protectCustomer,
  paymentController.confirmPayment
);

/**
 * @route   GET /api/v1/customer/payment/intent/:id
 * @desc    Get payment intent details
 * @access  Private (requires authentication)
 */
router.get(
  '/intent/:id',
  protectCustomer,
  paymentController.getPaymentIntent
);

/**
 * @route   POST /api/v1/customer/payment/wallet
 * @desc    Process payment from wallet balance
 * @access  Private (requires authentication)
 * @body    { amount: number, currency?: string, booking_id?: string }
 */
router.post(
  '/wallet',
  protectCustomer,
  paymentController.processWalletPayment
);

export default router;


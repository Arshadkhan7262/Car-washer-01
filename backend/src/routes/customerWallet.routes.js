import express from 'express';
import * as walletController from '../controllers/customerWallet.controller.js';
import { protectCustomer } from '../middleware/auth.middleware.js';

const router = express.Router();

/**
 * @route   GET /api/v1/customer/wallet/balance
 * @desc    Get current wallet balance
 * @access  Private (customer)
 */
router.get('/balance', protectCustomer, walletController.getWalletBalance);

/**
 * @route   POST /api/v1/customer/wallet/add-funds
 * @desc    Add funds to customer wallet (Stripe or dummy)
 * @access  Private (customer)
 * @body    { amount: number, payment_intent_id?: string, transaction_id?: string, is_dummy?: boolean }
 */
router.post(
  '/add-funds',
  protectCustomer,
  walletController.addFundsToWallet
);

export default router;


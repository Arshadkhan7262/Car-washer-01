/**
 * Washer Wallet Screen Routes
 * Handles wallet balance, transactions, and withdrawal requests
 */

import express from 'express';
import * as washerWalletController from '../controllers/washerWallet.controller.js';
import { protectWasher } from '../middleware/auth.middleware.js';

const router = express.Router();

// All routes require washer authentication
router.use(protectWasher);

// Wallet routes
router.get('/balance', washerWalletController.getWalletBalance);
router.get('/stats', washerWalletController.getWalletStats);
router.get('/transactions', washerWalletController.getTransactions);
router.post('/withdraw', washerWalletController.requestWithdrawal);

export default router;


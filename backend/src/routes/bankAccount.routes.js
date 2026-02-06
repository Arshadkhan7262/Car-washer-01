import express from 'express';
import * as bankAccountController from '../controllers/bankAccount.controller.js';
import { protectWasher } from '../middleware/auth.middleware.js';

const router = express.Router();

/**
 * Bank Account Routes for Washers
 * These routes handle bank account management for withdrawals
 * Mounted at /washer/bank-account in index.routes.js
 */

// Get bank account
router.get('/', protectWasher, bankAccountController.getBankAccount);

// Add or update bank account
router.post('/', protectWasher, bankAccountController.saveBankAccount);

// Update bank account (same as POST)
router.put('/', protectWasher, bankAccountController.saveBankAccount);

// Delete bank account
router.delete('/', protectWasher, bankAccountController.deleteBankAccount);

export default router;

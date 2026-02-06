import express from 'express';
import * as adminBankAccountController from '../controllers/adminBankAccount.controller.js';
import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

// All routes require admin authentication
router.use(protect);

// Get all bank accounts
router.get('/', adminBankAccountController.getAllBankAccounts);

// Get bank account by ID
router.get('/:id', adminBankAccountController.getBankAccountById);

// Verify bank account
router.put('/:id/verify', adminBankAccountController.verifyBankAccount);

// Reject bank account
router.put('/:id/reject', adminBankAccountController.rejectBankAccount);

export default router;

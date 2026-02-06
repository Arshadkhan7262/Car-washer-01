import express from 'express';
import * as withdrawalController from '../controllers/withdrawal.controller.js';
import { protectWasher } from '../middleware/auth.middleware.js';
import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

/**
 * Admin Withdrawal Routes
 * These routes are mounted at /admin/withdrawal in index.routes.js
 * IMPORTANT: Specific routes like /all and /limit must come BEFORE parameterized routes like /:id
 * Express matches routes in order, so /all must be defined before /:id to avoid matching conflicts
 */

// Get all withdrawal requests - MUST be before /:id routes
router.get('/all', protect, withdrawalController.getAllWithdrawals);

// Get minimum withdrawal limit (Admin) - MUST be before /:id routes  
router.get('/limit', protect, withdrawalController.getWithdrawalLimitAdmin);

// Set minimum withdrawal limit (Admin)
router.put('/limit', protect, withdrawalController.setWithdrawalLimit);

// Approve withdrawal request
router.put('/:id/approve', protect, withdrawalController.approveWithdrawal);

// Process withdrawal
router.put('/:id/process', protect, withdrawalController.processWithdrawal);

// Reject withdrawal request
router.put('/:id/reject', protect, withdrawalController.rejectWithdrawal);

/**
 * Washer Withdrawal Routes
 * These routes are mounted at /washer/withdrawal in index.routes.js
 */

// Create withdrawal request - MUST be before /:id routes
router.post('/request', protectWasher, withdrawalController.createWithdrawalRequest);

// Get minimum withdrawal limit
router.get('/limit', protectWasher, withdrawalController.getWithdrawalLimit);

// Get washer withdrawal requests
router.get('/', protectWasher, withdrawalController.getWasherWithdrawals);

// Get withdrawal details - MUST be after specific routes like /limit
router.get('/:id', protectWasher, withdrawalController.getWithdrawalDetails);

// Cancel withdrawal request - MUST be after /request
router.put('/:id/cancel', protectWasher, withdrawalController.cancelWithdrawal);

// Process approved withdrawal (Washer) - kept for backward compatibility
router.post('/:id/process', protectWasher, withdrawalController.processApprovedWithdrawal);

export default router;

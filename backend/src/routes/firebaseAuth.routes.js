/**
 * Firebase Authentication Routes
 * 
 * Firebase Phone Authentication for CUSTOMERS ONLY.
 * Washers use email/password authentication via /api/v1/washer/auth routes.
 */

import express from 'express';
import * as firebaseAuthController from '../controllers/firebaseAuth.controller.js';
import { protectCustomer } from '../middleware/auth.middleware.js';
import User from '../models/User.model.js';

const router = express.Router();

// Public routes
router.post('/firebase-login', firebaseAuthController.firebaseLogin);
router.post('/refresh', firebaseAuthController.refresh);

// Protected routes - Get current customer
router.get('/me/customer', protectCustomer, async (req, res, next) => {
  try {
    const customer = await User.findById(req.user.id).select('-password').lean();
    res.status(200).json({
      success: true,
      data: customer
    });
  } catch (error) {
    next(error);
  }
});

export default router;


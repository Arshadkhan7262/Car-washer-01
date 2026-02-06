import express from 'express';
import * as stripeConnectController from '../controllers/stripeConnect.controller.js';
import { protectWasher } from '../middleware/auth.middleware.js';

const router = express.Router();

/**
 * Stripe Connect Routes for Washers
 * These routes handle Stripe Connect account setup for receiving payouts
 * Mounted at /washer/stripe-connect in index.routes.js
 */

// Create Stripe Connect account
router.post('/create', protectWasher, stripeConnectController.createStripeConnectAccount);

// Get onboarding link
router.get('/onboarding-link', protectWasher, stripeConnectController.getOnboardingLink);

// Get account status
router.get('/status', protectWasher, stripeConnectController.getAccountStatus);

export default router;

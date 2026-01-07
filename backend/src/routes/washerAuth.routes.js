import express from 'express';
import * as washerAuthController from '../controllers/washerAuth.controller.js';
import { protectWasher } from '../middleware/auth.middleware.js';

const router = express.Router();

/**
 * Washer Authentication Routes - Email-based only
 * 
 * UI Flow:
 * 1. Register → POST /register (email, password, name, phone)
 * 2. Send Email OTP → POST /send-email-otp (email)
 * 3. Verify Email OTP → POST /verify-email-otp (email, otp)
 * 4. Login → POST /login (email, password) - requires email verified + status active
 * 5. Forgot Password → POST /forgot-password (email)
 * 6. Reset Password → POST /reset-password (email, otp, newPassword)
 */

// Primary routes matching UI flow
router.post('/register', washerAuthController.registerWithEmail);
router.post('/login', washerAuthController.loginWithEmail);
router.post('/send-email-otp', washerAuthController.requestEmailOTP);
router.post('/verify-email-otp', washerAuthController.verifyEmailOTP);
router.post('/forgot-password', washerAuthController.requestPasswordReset);
router.post('/reset-password', washerAuthController.resetPassword);
router.post('/check-status', washerAuthController.checkStatusByEmail); // Public - check status by email

// Legacy routes (for backward compatibility)
router.post('/register-email', washerAuthController.registerWithEmail);
router.post('/login-email', washerAuthController.loginWithEmail);
router.post('/request-email-otp', washerAuthController.requestEmailOTP);
router.post('/request-password-reset', washerAuthController.requestPasswordReset);

// Protected routes
router.get('/me', protectWasher, washerAuthController.getMe);
router.post('/logout', protectWasher, washerAuthController.logout);
router.post('/refresh', washerAuthController.refresh);

export default router;


import express from 'express';
import * as customerAuthController from '../controllers/customerAuth.controller.js';
import { protectCustomer } from '../middleware/auth.middleware.js';

const router = express.Router();

/**
 * Customer Authentication Routes - Email-based (similar to Washer Auth)
 * 
 * UI Flow:
 * 1. Register → POST /register (email, password, name, phone)
 * 2. Send Email OTP → POST /send-email-otp (email)
 * 3. Verify Email OTP → POST /verify-email-otp (email, otp)
 * 4. Login → POST /login (email, password) - requires email verified
 * 5. Forgot Password → POST /forgot-password (email)
 * 6. Reset Password → POST /reset-password (email, otp, newPassword)
 * 
 * NOTE: Customers are always active (no admin approval needed)
 */

// Primary routes matching UI flow
router.post('/register', customerAuthController.registerWithEmail);
router.post('/login', customerAuthController.loginWithEmail);
router.post('/send-email-otp', customerAuthController.requestEmailOTP);
router.post('/verify-email-otp', customerAuthController.verifyEmailOTP);
router.post('/forgot-password', customerAuthController.requestPasswordReset);
router.post('/reset-password', customerAuthController.resetPassword);
router.post('/check-status', customerAuthController.checkStatusByEmail); // Public - check status by email

// Legacy routes (for backward compatibility)
router.post('/register-phone', customerAuthController.registerWithPhone);
router.post('/verify-otp', customerAuthController.verifyOTP);
router.post('/resend-otp', customerAuthController.resendOTP);
router.post('/register-email', customerAuthController.registerWithEmail);
router.post('/login-email', customerAuthController.loginWithEmail);
router.post('/refresh', customerAuthController.refresh);

// Protected routes
router.get('/me', protectCustomer, customerAuthController.getMe);
router.post('/logout', protectCustomer, customerAuthController.logout);

export default router;


/**
 * Firebase Authentication Controller
 * 
 * Handles HTTP requests for Firebase-based authentication for CUSTOMERS ONLY.
 * Washers use email/password authentication via /api/v1/washer/auth routes.
 */

import * as firebaseAuthService from '../services/firebaseAuth.service.js';
import AppError from '../errors/AppError.js';

/**
 * @desc    Login or register customer with Firebase ID token
 * @route   POST /api/v1/auth/firebase-login
 * @access  Public
 */
export const firebaseLogin = async (req, res, next) => {
  try {
    const { idToken, role } = req.body;

    // Validation
    if (!idToken) {
      return res.status(400).json({
        success: false,
        message: 'Firebase ID token is required'
      });
    }

    // Default to customer if role not provided, but validate if provided
    const userRole = role || 'customer';
    if (userRole !== 'customer') {
      return res.status(400).json({
        success: false,
        message: 'Firebase authentication is only available for customers. Washers must use email/password authentication at /api/v1/washer/auth/login'
      });
    }

    const result = await firebaseAuthService.firebaseLogin(idToken, userRole);

    // Successful login
    res.status(200).json({
      success: true,
      message: 'Authentication successful',
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Refresh access token
 * @route   POST /api/v1/auth/refresh
 * @access  Public
 */
export const refresh = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({
        success: false,
        message: 'Refresh token is required'
      });
    }

    const tokens = await firebaseAuthService.refreshAccessToken(refreshToken);

    res.status(200).json({
      success: true,
      data: tokens
    });
  } catch (error) {
    next(error);
  }
};


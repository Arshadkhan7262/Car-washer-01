/**
 * Firebase Authentication Service
 * 
 * Handles user authentication using Firebase Phone Authentication for CUSTOMERS ONLY.
 * Firebase handles OTP generation and verification on the client side.
 * This service verifies Firebase tokens and manages user records.
 * 
 * NOTE: Washers use email/password authentication, not Firebase.
 */

import User from '../models/User.model.js';
import AppError from '../errors/AppError.js';
import { verifyFirebaseToken } from '../config/firebase.config.js';
import { generateAccessToken, generateRefreshToken } from '../config/jwt.config.js';

/**
 * Login or register customer with Firebase ID token
 * @param {string} idToken - Firebase ID token
 * @param {string} role - User role (must be 'customer')
 * @returns {Promise<Object>} User data with JWT tokens
 */
export const firebaseLogin = async (idToken, role) => {
  // Validate role - only customers can use Firebase auth
  if (role !== 'customer') {
    throw new AppError('Firebase authentication is only available for customers. Washers must use email/password authentication.', 400);
  }

  // Verify Firebase ID token
  let firebaseUser;
  try {
    firebaseUser = await verifyFirebaseToken(idToken);
  } catch (error) {
    throw new AppError(`Firebase authentication failed: ${error.message}`, 401);
  }

  // Ensure phone is verified (Firebase requirement)
  if (!firebaseUser.phoneVerified || !firebaseUser.phone) {
    throw new AppError('Phone number must be verified via Firebase', 400);
  }

  // Find existing user by firebaseUid + role
  let user = await User.findOne({ 
    firebaseUid: firebaseUser.uid, 
    role: role 
  });

  if (user) {
    // Existing user - login flow
    
    // Security: Prevent role escalation
    if (user.role !== role) {
      throw new AppError('Firebase UID is already associated with a different role', 403);
    }

    // Check if user is blocked
    if (user.is_blocked) {
      throw new AppError('Your account has been blocked. Please contact support.', 403);
    }

    // Update phone if changed in Firebase
    if (user.phone !== firebaseUser.phone) {
      user.phone = firebaseUser.phone;
      user.phone_verified = true;
    }

    // Update name if provided in Firebase token
    if (firebaseUser.name && !user.name) {
      user.name = firebaseUser.name;
    }

    await user.save();
  } else {
    // New user - registration flow
    
    // Check if phone already exists with this role (different Firebase UID)
    const existingPhoneUser = await User.findOne({ 
      phone: firebaseUser.phone, 
      role: role 
    });

    if (existingPhoneUser) {
      // Phone exists but different Firebase UID - update to new Firebase UID
      existingPhoneUser.firebaseUid = firebaseUser.uid;
      existingPhoneUser.phone_verified = true;
      if (firebaseUser.name && !existingPhoneUser.name) {
        existingPhoneUser.name = firebaseUser.name;
      }
      await existingPhoneUser.save();
      user = existingPhoneUser;
    } else {
      // Create new user
      user = await User.create({
        firebaseUid: firebaseUser.uid,
        phone: firebaseUser.phone,
        name: firebaseUser.name || 'User',
        email: firebaseUser.email || null,
        role: role,
        phone_verified: true,
        email_verified: firebaseUser.emailVerified || false,
        is_active: true,
        is_blocked: false
      });
    }
  }

  // Generate JWT tokens
  const token = generateAccessToken(user._id, user.role);
  const refreshToken = generateRefreshToken(user._id, user.role);

  // Prepare response
  return {
    user: {
      id: user._id,
      name: user.name,
      phone: user.phone,
      email: user.email,
      role: user.role,
      phone_verified: user.phone_verified,
      email_verified: user.email_verified
    },
    token,
    refreshToken
  };
};

/**
 * Refresh access token using refresh token
 * @param {string} refreshToken - JWT refresh token
 * @returns {Promise<Object>} New access token and refresh token
 */
export const refreshAccessToken = async (refreshToken) => {
  if (!refreshToken) {
    throw new AppError('Refresh token is required', 400);
  }

  try {
    const { verifyRefreshToken } = await import('../config/jwt.config.js');
    const decoded = verifyRefreshToken(refreshToken);

    const user = await User.findById(decoded.id);
    if (!user) {
      throw new AppError('User not found', 404);
    }

    if (user.is_blocked || !user.is_active) {
      throw new AppError('Account is inactive or blocked', 403);
    }

    // Generate new tokens
    const { generateAccessToken, generateRefreshToken } = await import('../config/jwt.config.js');
    const newToken = generateAccessToken(user._id, user.role);
    const newRefreshToken = generateRefreshToken(user._id, user.role);

    return {
      token: newToken,
      refreshToken: newRefreshToken
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Invalid or expired refresh token', 401);
  }
};


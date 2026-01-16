/**
 * Google Authentication Service using Firebase ID Token
 * 
 * This service handles Google Sign-In authentication using Firebase Authentication.
 * When Google Identity Services (GIS) is enabled, the Flutter app signs in via Firebase
 * and sends a Firebase ID Token to the backend. This service verifies the token using
 * Firebase Admin SDK and manages user records in MongoDB.
 */

import User from '../models/User.model.js';
import AppError from '../errors/AppError.js';
import { verifyFirebaseTokenForGoogle } from '../config/firebase.config.js';
import { generateAccessToken, generateRefreshToken } from '../config/jwt.config.js';

/**
 * Login or register user with Firebase ID Token (Google Sign-In)
 * @param {string} idToken - Firebase ID token from client
 * @param {string} role - User role ('customer' or 'washer')
 * @returns {Promise<Object>} User data with JWT tokens
 */
export const googleLoginWithFirebase = async (idToken, role) => {
  // Validate role
  if (!['customer', 'washer'].includes(role)) {
    throw new AppError('Invalid role. Must be "customer" or "washer"', 400);
  }

  // Verify Firebase ID Token
  let firebaseUser;
  try {
    firebaseUser = await verifyFirebaseTokenForGoogle(idToken);
  } catch (error) {
    throw new AppError(`Firebase authentication failed: ${error.message}`, 401);
  }

  // Ensure email is present (required for Google Sign-In)
  if (!firebaseUser.email) {
    throw new AppError('Email not provided by Firebase', 400);
  }

  const normalizedEmail = firebaseUser.email.toLowerCase().trim();
  const userName = firebaseUser.name || firebaseUser.email.split('@')[0];

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

    // Update user information from Firebase
    if (firebaseUser.name && !user.name) {
      user.name = firebaseUser.name;
    }
    if (firebaseUser.photoURL && !user.profilePicture) {
      user.profilePicture = firebaseUser.photoURL;
      user.avatar = firebaseUser.photoURL;
    }
    if (user.email !== normalizedEmail) {
      user.email = normalizedEmail;
    }
    if (!user.email_verified) {
      user.email_verified = firebaseUser.emailVerified;
    }
    if (user.provider !== 'google') {
      user.provider = 'google';
    }
    if (!user.firebaseUid) {
      user.firebaseUid = firebaseUser.uid;
    }
    
    // Update lastLogin timestamp
    user.lastLogin = new Date();
    
    await user.save();
  } else {
    // New user - registration flow
    
    // Check if email already exists with this role (different Firebase UID)
    const existingEmailUser = await User.findOne({ 
      email: normalizedEmail, 
      role: role 
    });

    if (existingEmailUser) {
      // Email exists but different Firebase UID - update to new Firebase UID
      if (existingEmailUser.firebaseUid && existingEmailUser.firebaseUid !== firebaseUser.uid) {
        throw new AppError('This email is already registered with a different Google account', 400);
      }
      
      existingEmailUser.firebaseUid = firebaseUser.uid;
      existingEmailUser.email_verified = firebaseUser.emailVerified;
      if (firebaseUser.name && !existingEmailUser.name) {
        existingEmailUser.name = firebaseUser.name;
      }
      if (firebaseUser.photoURL) {
        existingEmailUser.profilePicture = firebaseUser.photoURL;
        existingEmailUser.avatar = firebaseUser.photoURL;
      }
      existingEmailUser.provider = 'google';
      existingEmailUser.lastLogin = new Date();
      
      await existingEmailUser.save();
      user = existingEmailUser;
    } else {
      // Check if email exists with different role
      const existingEmailDifferentRole = await User.findOne({ 
        email: normalizedEmail 
      });
      
      if (existingEmailDifferentRole) {
        throw new AppError('This email is already registered with a different account type', 400);
      }

      // Generate a phone number placeholder (required field)
      // In production, you might want to require phone separately
      const phonePlaceholder = `google_${firebaseUser.uid.substring(0, 10)}`;

      // Create new user with Google OAuth via Firebase
      user = await User.create({
        name: userName,
        email: normalizedEmail,
        phone: phonePlaceholder,
        password: undefined, // No password for Google login
        firebaseUid: firebaseUser.uid,
        googleId: firebaseUser.uid, // Use Firebase UID as Google ID
        profilePicture: firebaseUser.photoURL || null,
        avatar: firebaseUser.photoURL || null,
        role: role,
        provider: 'google',
        email_verified: firebaseUser.emailVerified,
        phone_verified: false,
        is_active: true,
        is_blocked: false,
        lastLogin: new Date()
      });
    }
  }

  // Check if user is active
  if (!user.is_active) {
    throw new AppError('Your account has been deactivated. Please contact support.', 403);
  }

  // Generate JWT tokens
  const token = generateAccessToken(user._id, user.role);
  const refreshToken = generateRefreshToken(user._id, user.role);

  // Prepare response
  return {
    user: {
      id: user._id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      role: user.role,
      profileImage: user.profilePicture || user.avatar || null,
      authProvider: user.provider,
      email_verified: user.email_verified,
      phone_verified: user.phone_verified,
      createdAt: user.created_date,
      lastLogin: user.lastLogin
    },
    token,
    refreshToken
  };
};



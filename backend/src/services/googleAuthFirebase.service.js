/**
 * Google Authentication Service using Firebase ID Token
 * 
 * This service handles Google Sign-In authentication using Firebase Authentication.
 * When Google Identity Services (GIS) is enabled, the Flutter app signs in via Firebase
 * and sends a Firebase ID Token to the backend. This service verifies the token using
 * Firebase Admin SDK and manages user records in MongoDB.
 * 
 * Registration flow matches email registration:
 * - Customers: is_active=true, email_verified=false, OTP email sent
 * - Washers: is_active=true, email_verified=false, Washer profile created with status='pending', OTP email sent
 */

import mongoose from 'mongoose';
import User from '../models/User.model.js';
import Washer from '../models/Washer.model.js';
import AppError from '../errors/AppError.js';
import { verifyFirebaseTokenForGoogle } from '../config/firebase.config.js';
import { generateAccessToken, generateRefreshToken } from '../config/jwt.config.js';
import emailService from './email.service.js';

// Generate 4-digit OTP (same as email registration)
const generateEmailOTP = () => {
  return Math.floor(1000 + Math.random() * 9000).toString();
};

/**
 * Login or register user with Firebase ID Token (Google Sign-In)
 * @param {string} idToken - Firebase ID token from client
 * @param {string} role - User role ('customer' or 'washer')
 * @returns {Promise<Object>} User data with JWT tokens
 */
export const googleLoginWithFirebase = async (idToken, role) => {
  // Check MongoDB connection - fail fast if not connected
  if (mongoose.connection.readyState !== 1) {
    throw new AppError('Database connection not available. Please try again in a moment.', 503);
  }

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
  let user;
  try {
    user = await User.findOne({ 
      firebaseUid: firebaseUser.uid, 
      role: role 
    });
  } catch (dbError) {
    // If MongoDB isn't connected, the check above should have caught it
    // But handle any other DB errors gracefully
    if (mongoose.connection.readyState !== 1) {
      throw new AppError('Database connection not available. Please try again in a moment.', 503);
    }
    throw new AppError(`Database error: ${dbError.message}`, 500);
  }

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
    // Don't update email_verified from Firebase - keep existing status (same as email registration)
    if (user.provider !== 'google') {
      user.provider = 'google';
    }
    if (!user.firebaseUid) {
      user.firebaseUid = firebaseUser.uid;
    }
    
    // Update lastLogin timestamp
    user.lastLogin = new Date();
    
    try {
      await user.save();
    } catch (saveError) {
      if (mongoose.connection.readyState !== 1) {
        throw new AppError('Database connection not available. Please try again in a moment.', 503);
      }
      throw new AppError(`Failed to save user: ${saveError.message}`, 500);
    }
  } else {
    // New user - registration flow
    
    // Check if email already exists with this role (different Firebase UID)
    let existingEmailUser;
    try {
      existingEmailUser = await User.findOne({ 
        email: normalizedEmail, 
        role: role 
      });
    } catch (dbError) {
      if (mongoose.connection.readyState !== 1) {
        throw new AppError('Database connection not available. Please try again in a moment.', 503);
      }
      throw new AppError(`Database error: ${dbError.message}`, 500);
    }

    if (existingEmailUser) {
      // Email exists but different Firebase UID - update to new Firebase UID
      if (existingEmailUser.firebaseUid && existingEmailUser.firebaseUid !== firebaseUser.uid) {
        throw new AppError('This email is already registered with a different Google account', 400);
      }
      
      // Link Google account to existing email account
      existingEmailUser.firebaseUid = firebaseUser.uid;
      existingEmailUser.googleId = firebaseUser.uid;
      
      // Keep existing email_verified status (don't overwrite if already verified)
      // Only set to verified if Firebase says it's verified AND user hasn't verified yet
      if (firebaseUser.emailVerified && !existingEmailUser.email_verified) {
        existingEmailUser.email_verified = true;
      }
      
      // Update name only if not set
      if (firebaseUser.name && !existingEmailUser.name) {
        existingEmailUser.name = firebaseUser.name;
      }
      
      // Update profile picture if available and not set
      if (firebaseUser.photoURL && !existingEmailUser.profilePicture) {
        existingEmailUser.profilePicture = firebaseUser.photoURL;
        existingEmailUser.avatar = firebaseUser.photoURL;
      }
      
      // Keep original provider (email) - user can login with both email/password and Google
      // Only set to 'google' if it was null/undefined
      if (!existingEmailUser.provider) {
        existingEmailUser.provider = 'google';
      }
      
      existingEmailUser.lastLogin = new Date();
      
      try {
        await existingEmailUser.save();
      } catch (saveError) {
        if (mongoose.connection.readyState !== 1) {
          throw new AppError('Database connection not available. Please try again in a moment.', 503);
        }
        throw new AppError(`Failed to save user: ${saveError.message}`, 500);
      }
      user = existingEmailUser;
      
      console.log(`✅ Linked Google account to existing email account: ${normalizedEmail}`);
    } else {
      // Check if email exists with different role
      let existingEmailDifferentRole;
      try {
        existingEmailDifferentRole = await User.findOne({ 
          email: normalizedEmail 
        });
      } catch (dbError) {
        if (mongoose.connection.readyState !== 1) {
          throw new AppError('Database connection not available. Please try again in a moment.', 503);
        }
        throw new AppError(`Database error: ${dbError.message}`, 500);
      }
      
      if (existingEmailDifferentRole) {
        throw new AppError('This email is already registered with a different account type', 400);
      }

      // Generate a phone number placeholder (required field)
      // In production, you might want to require phone separately
      const phonePlaceholder = `google_${firebaseUser.uid.substring(0, 10)}`;

      // Create new user with Google OAuth via Firebase (same flow as email registration)
      try {
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
        email_verified: false, // Same as email registration - not verified initially
        phone_verified: false,
        is_active: true, // Customers and washers are active by default (same as email)
        is_blocked: false,
        wallet_balance: 0, // Explicitly set wallet balance (same as email registration)
        preferences: { // Explicitly set preferences (same as email registration)
          push_notification_enabled: true, // Default to true for push notifications
          two_factor_auth_enabled: false
        },
        lastLogin: new Date()
      });

      // Generate and send OTP email automatically after registration (same as email registration)
      const otpCode = generateEmailOTP();
      const otpExpires = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

      user.otp = {
        code: String(otpCode).trim(), // Ensure OTP is stored as trimmed string
        expiresAt: otpExpires
      };
      try {
        await user.save();
      } catch (saveError) {
        if (mongoose.connection.readyState !== 1) {
          throw new AppError('Database connection not available. Please try again in a moment.', 503);
        }
        throw new AppError(`Failed to save user: ${saveError.message}`, 500);
      }

      console.log(`📧 Generated OTP for ${normalizedEmail} (Google Sign-In): "${otpCode}" (stored as: "${user.otp.code}")`);

      // Send OTP email asynchronously (non-blocking - same as email registration)
      emailService.sendOTPEmail(normalizedEmail, otpCode, userName || (role === 'washer' ? 'Washer' : 'Customer'), role)
        .then(() => {
          console.log(`✅ Registration OTP email sent to ${normalizedEmail} (Google Sign-In)`);
          if (process.env.NODE_ENV === 'development') {
            console.log(`📧 If email not received, check Spam/Junk. OTP for ${normalizedEmail}: ${otpCode}`);
          }
        })
        .catch((emailError) => {
          console.error(`❌ Failed to send registration OTP email to ${normalizedEmail}:`, emailError);
          if (process.env.NODE_ENV === 'development') {
            console.log(`📧 Development mode - Registration OTP for ${normalizedEmail}: ${otpCode}`);
          }
          // Don't throw error - registration succeeds even if email fails
        });

      // For washers, create washer profile with 'pending' status (same as email registration)
      if (role === 'washer') {
        try {
          // Check if washer profile already exists (shouldn't happen, but safety check)
          const existingWasher = await Washer.findOne({ user_id: user._id });
          if (!existingWasher) {
            await Washer.create({
              user_id: user._id,
              name: userName,
              phone: phonePlaceholder,
              email: normalizedEmail,
              status: 'pending', // Start as pending - admin must approve (same as email registration)
              online_status: false
            });
            console.log(`✅ Washer profile created with pending status for ${normalizedEmail}`);
          }
        } catch (washerError) {
          if (mongoose.connection.readyState !== 1) {
            throw new AppError('Database connection not available. Please try again in a moment.', 503);
          }
          throw new AppError(`Failed to create washer profile: ${washerError.message}`, 500);
        }
      }
      } catch (createError) {
        if (mongoose.connection.readyState !== 1) {
          throw new AppError('Database connection not available. Please try again in a moment.', 503);
        }
        throw new AppError(`Failed to create user: ${createError.message}`, 500);
      }
    }
  }

  // Check if user is active
  if (!user.is_active) {
    throw new AppError('Your account has been deactivated. Please contact support.', 403);
  }

  // Generate JWT tokens (same format as email registration)
  // Convert user to plain object to avoid Mongoose document issues
  // Extract values and ensure they are plain primitives
  const userId = user._id ? String(user._id.toString()) : '';
  const userEmail = user.email ? String(user.email) : '';
  const userPhone = user.phone ? String(user.phone) : '';
  const userRole = user.role ? String(user.role) : 'customer';

  // Create plain object payload (ensure all values are primitives - no Mongoose types)
  const tokenPayload = {
    id: userId,
    email: userEmail,
    phone: userPhone,
    role: userRole
  };

  // Validate payload before signing
  if (!tokenPayload.id || !tokenPayload.email || !tokenPayload.role) {
    console.error('❌ Invalid token payload:', {
      id: tokenPayload.id,
      email: tokenPayload.email,
      phone: tokenPayload.phone,
      role: tokenPayload.role,
      userIdType: typeof userId,
      userEmailType: typeof userEmail
    });
    throw new AppError('Invalid user data for token generation', 500);
  }

  // Ensure payload is a plain object (not a Mongoose document)
  const plainPayload = JSON.parse(JSON.stringify(tokenPayload));

  const accessToken = generateAccessToken(plainPayload);
  const refreshToken = generateRefreshToken(plainPayload);

  // Prepare response (same format as email registration)
  return {
    token: accessToken,
    refreshToken: refreshToken,
    email: normalizedEmail,
    email_verified: user.email_verified,
    status: user.is_active ? 'active' : 'inactive',
    user: {
      id: user._id.toString(),
      name: user.name,
      phone: user.phone,
      email: user.email,
      role: user.role,
      profileImage: user.profilePicture || user.avatar || null,
      authProvider: user.provider,
      phone_verified: user.phone_verified,
      email_verified: user.email_verified,
      wallet_balance: user.wallet_balance || 0,
      createdAt: user.created_date,
      lastLogin: user.lastLogin
    },
    message: 'Account created successfully. Welcome email with OTP has been sent to your inbox.'
  };
};



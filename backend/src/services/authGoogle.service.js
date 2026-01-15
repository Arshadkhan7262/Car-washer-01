import User from '../models/User.model.js';
import AppError from '../errors/AppError.js';
import { OAuth2Client } from 'google-auth-library';
import jwt from 'jsonwebtoken';

/**
 * Login/Register customer with Google OAuth
 * Verifies Google ID token and creates/updates user
 * 
 * @param {string} idToken - Google ID token from Flutter app
 * @returns {Object} { token: string, user: { id, name, email, role } }
 */
export const loginWithGoogle = async (idToken) => {
  const clientId = process.env.GOOGLE_CLIENT_ID;
  if (!clientId) {
    throw new Error('GOOGLE_CLIENT_ID environment variable is required');
  }
  const client = new OAuth2Client(clientId);

  try {
    // Verify the Google ID token
    const ticket = await client.verifyIdToken({
      idToken: idToken,
      audience: clientId,
    });

    const payload = ticket.getPayload();
    
    if (!payload) {
      throw new AppError('Invalid Google token', 401);
    }

    // Extract user information from Google token
    const { sub: googleId, email, name, picture } = payload;
    
    if (!email) {
      throw new AppError('Email not provided by Google', 400);
    }

    const normalizedEmail = email.toLowerCase().trim();
    const userName = name || email.split('@')[0]; // Use name from Google or derive from email

    // Check if user already exists with this email
    let user = await User.findOne({ email: normalizedEmail, role: 'customer' });

    if (user) {
      // User exists - ensure role is customer
      if (user.role !== 'customer') {
        throw new AppError('This email is already registered with a different account type', 400);
      }
      
      // Update user with Google information if needed
      if (!user.googleId) {
        user.googleId = googleId;
      }
      if (picture) {
        user.avatar = picture;
        user.profilePicture = picture;
      }
      if (!user.email_verified) {
        user.email_verified = true; // Google emails are verified
      }
      if (user.provider !== 'google') {
        user.provider = 'google';
      }
      await user.save();
    } else {
      // Check if email exists with different role
      const existingEmail = await User.findOne({ email: normalizedEmail });
      if (existingEmail) {
        throw new AppError('This email is already registered with a different account type', 400);
      }

      // Generate a phone number placeholder (required field)
      // In production, you might want to require phone separately
      const phonePlaceholder = `google_${googleId.substring(0, 10)}`;

      // Create new user with Google OAuth
      user = await User.create({
        name: userName,
        email: normalizedEmail,
        phone: phonePlaceholder,
        password: undefined, // No password for Google login
        googleId: googleId,
        avatar: picture || null,
        profilePicture: picture || null,
        role: 'customer',
        provider: 'google',
        email_verified: true, // Google emails are verified
        phone_verified: false,
        is_active: true,
      });
    }

    // Check if user is blocked
    if (user.is_blocked) {
      throw new AppError('Your account has been blocked. Please contact support.', 403);
    }

    // Check if user is active
    if (!user.is_active) {
      throw new AppError('Your account has been deactivated. Please contact support.', 403);
    }

    // Generate JWT token with 7 days expiry
    const tokenPayload = {
      id: user._id.toString(),
      email: user.email,
      phone: user.phone,
      role: user.role
    };

    const token = jwt.sign(tokenPayload, process.env.JWT_SECRET, {
      expiresIn: '7d'
    });

    // Return response in the required format
    return {
      token: token,
      user: {
        id: user._id.toString(),
        name: user.name,
        email: user.email,
        role: user.role
      }
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    console.error('Google login error:', error);
    throw new AppError('Google authentication failed', 401);
  }
};


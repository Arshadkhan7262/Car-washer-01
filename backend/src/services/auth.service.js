import AdminUser from '../models/AdminUser.model.js';
import AppError from '../errors/AppError.js';
import { generateAccessToken, generateRefreshToken, verifyRefreshToken } from '../config/jwt.config.js';

/**
 * Login admin user
 */
export const loginAdmin = async (email, password) => {
  // Find admin and include password field
  const admin = await AdminUser.findOne({ email: email.toLowerCase() }).select('+password');

  if (!admin) {
    throw new AppError('Invalid email or password', 401);
  }

  // Check if admin is active
  if (!admin.is_active) {
    throw new AppError('Your account has been deactivated. Please contact support.', 403);
  }

  // Verify password
  const isPasswordValid = await admin.comparePassword(password);
  if (!isPasswordValid) {
    throw new AppError('Invalid email or password', 401);
  }

  // Generate tokens
  const tokenPayload = {
    id: admin._id.toString(),
    email: admin.email,
    role: admin.role
  };

  const accessToken = generateAccessToken(tokenPayload);
  const refreshToken = generateRefreshToken(tokenPayload);

  // Return admin data without password
  const adminData = admin.toJSON();

  return {
    token: accessToken,
    refreshToken: refreshToken,
    admin: {
      id: adminData._id,
      email: adminData.email,
      role: adminData.role,
      name: adminData.name
    }
  };
};

/**
 * Refresh access token
 */
export const refreshAccessToken = async (refreshTokenInput) => {
  try {
    // Verify refresh token
    const decoded = verifyRefreshToken(refreshTokenInput);

    // Find admin
    const admin = await AdminUser.findById(decoded.id);

    if (!admin) {
      throw new AppError('Admin not found', 404);
    }

    if (!admin.is_active) {
      throw new AppError('Your account has been deactivated', 403);
    }

    // Generate new access token
    const tokenPayload = {
      id: admin._id.toString(),
      email: admin.email,
      role: admin.role
    };

    const accessToken = generateAccessToken(tokenPayload);

    return {
      token: accessToken,
      refreshToken: refreshTokenInput, // Return same refresh token (it's still valid until expiry)
      admin: {
        id: admin._id.toString(),
        email: admin.email,
        role: admin.role,
        name: admin.name
      }
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Invalid or expired refresh token', 401);
  }
};

/**
 * Get admin by ID
 */
export const getAdminById = async (adminId) => {
  const admin = await AdminUser.findById(adminId);

  if (!admin) {
    throw new AppError('Admin not found', 404);
  }

  if (!admin.is_active) {
    throw new AppError('Your account has been deactivated', 403);
  }

  return admin;
};









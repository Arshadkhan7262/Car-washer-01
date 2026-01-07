import AppError from '../errors/AppError.js';
import { verifyAccessToken } from '../config/jwt.config.js';
import AdminUser from '../models/AdminUser.model.js';
import User from '../models/User.model.js';

/**
 * Protect routes - Verify JWT token for Admin
 */
export const protect = async (req, res, next) => {
  try {
    let token;

    // Get token from header
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return next(new AppError('You are not logged in! Please log in to get access.', 401));
    }

    // Verify token
    const decoded = verifyAccessToken(token);

    // Check if admin still exists
    const admin = await AdminUser.findById(decoded.id);

    if (!admin) {
      return next(new AppError('The admin belonging to this token no longer exists.', 401));
    }

    if (!admin.is_active) {
      return next(new AppError('Your account has been deactivated.', 403));
    }

    // Grant access to protected route
    req.admin = admin;
    next();
  } catch (error) {
    if (error.message.includes('Invalid') || error.message.includes('expired')) {
      return next(new AppError('Invalid or expired token. Please log in again!', 401));
    }
    next(error);
  }
};

/**
 * Protect routes - Verify JWT token for Customer
 */
export const protectCustomer = async (req, res, next) => {
  try {
    let token;

    // Get token from header
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return next(new AppError('You are not logged in! Please log in to get access.', 401));
    }

    // Verify token
    const decoded = verifyAccessToken(token);

    // Check if user is a customer
    if (decoded.role !== 'customer') {
      return next(new AppError('Access denied. This route is for customers only.', 403));
    }

    // Check if customer still exists
    const user = await User.findById(decoded.id);

    if (!user) {
      return next(new AppError('The customer belonging to this token no longer exists.', 401));
    }

    if (user.role !== 'customer') {
      return next(new AppError('Access denied. Invalid user role.', 403));
    }

    if (!user.is_active) {
      return next(new AppError('Your account has been deactivated.', 403));
    }

    if (user.is_blocked) {
      return next(new AppError('Your account has been blocked. Please contact support.', 403));
    }

    // Grant access to protected route
    req.customer = {
      _id: user._id, // Include _id for MongoDB queries
      id: user._id.toString(), // Include id as string for consistency
      phone: user.phone,
      email: user.email,
      role: user.role
    };
    next();
  } catch (error) {
    if (error.message.includes('Invalid') || error.message.includes('expired')) {
      return next(new AppError('Invalid or expired token. Please log in again!', 401));
    }
    next(error);
  }
};

/**
 * Protect routes - Verify JWT token for Washer
 */
export const protectWasher = async (req, res, next) => {
  try {
    let token;

    // Get token from header
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return next(new AppError('You are not logged in! Please log in to get access.', 401));
    }

    // Verify token
    const decoded = verifyAccessToken(token);

    // Check if user is a washer
    if (decoded.role !== 'washer') {
      return next(new AppError('Access denied. This route is for washers only.', 403));
    }

    // Check if washer still exists
    const user = await User.findById(decoded.id);

    if (!user) {
      return next(new AppError('The washer belonging to this token no longer exists.', 401));
    }

    if (user.role !== 'washer') {
      return next(new AppError('Access denied. Invalid user role.', 403));
    }

    if (!user.is_active) {
      return next(new AppError('Your account has been deactivated.', 403));
    }

    if (user.is_blocked) {
      return next(new AppError('Your account has been blocked. Please contact support.', 403));
    }

    // Grant access to protected route
    req.washer = {
      _id: user._id, // Include _id for MongoDB queries
      id: user._id.toString(), // Include id as string for consistency
      phone: user.phone,
      email: user.email,
      role: user.role,
      washer_id: decoded.washer_id
    };
    next();
  } catch (error) {
    if (error.message.includes('Invalid') || error.message.includes('expired')) {
      return next(new AppError('Invalid or expired token. Please log in again!', 401));
    }
    next(error);
  }
};

/**
 * Restrict routes to specific admin roles
 */
export const restrictTo = (...roles) => {
  return (req, res, next) => {
    if (!req.admin || !roles.includes(req.admin.role)) {
      return next(
        new AppError('You do not have permission to perform this action', 403)
      );
    }
    next();
  };
};









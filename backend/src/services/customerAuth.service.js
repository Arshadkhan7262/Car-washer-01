import User from '../models/User.model.js';
import AppError from '../errors/AppError.js';
import { generateAccessToken, generateRefreshToken, verifyRefreshToken } from '../config/jwt.config.js';
import emailService from './email.service.js';

/**
 * Generate OTP code (6 digits) - for phone OTP
 */
const generateOTP = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

/**
 * Generate 4-digit OTP code for email verification
 * OTP expires in 5 minutes as per UI requirements
 */
const generateEmailOTP = () => {
  return Math.floor(1000 + Math.random() * 9000).toString();
};

/**
 * Register customer with phone
 */
export const registerWithPhone = async (phone, name) => {
  // Check if user already exists with this phone and customer role
  let user = await User.findOne({ phone, role: 'customer' });

  if (user) {
    // User exists, just update OTP
    const otpCode = generateOTP();
    const otpExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    user.otp = {
      code: String(otpCode).trim(), // Ensure OTP is stored as trimmed string
      expiresAt: otpExpires
    };
    // Update name if provided
    if (name) {
      user.name = name;
    }
    await user.save();
    console.log(`📧 Generated Phone OTP for existing user ${phone}: "${otpCode}" (stored as: "${user.otp.code}")`);

    // TODO: Send OTP via SMS service
    console.log(`OTP for existing customer ${phone}: ${otpCode}`);

    return {
      phone,
      message: 'OTP sent to your phone number',
      otp: process.env.NODE_ENV === 'development' ? otpCode : undefined
    };
  }

  // Check if phone exists with different role
  const existingPhone = await User.findOne({ phone });
  if (existingPhone) {
    throw new AppError('This phone number is already registered with a different account type. Please use a different phone number.', 400);
  }

  // Generate OTP
  const otpCode = generateOTP();
  const otpExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

  // Create new user
  user = await User.create({
    phone,
    name,
    role: 'customer',
    otp: {
      code: String(otpCode).trim(), // Ensure OTP is stored as trimmed string
      expiresAt: otpExpires
    },
    phone_verified: false,
    is_active: true
  });
  console.log(`📧 Generated Phone OTP for new user ${phone}: "${otpCode}" (stored as: "${user.otp.code}")`);

  // TODO: Send OTP via SMS service (Twilio, AWS SNS, etc.)
  console.log(`OTP for new customer ${phone}: ${otpCode}`); // Remove in production

  return {
    phone,
    message: 'OTP sent to your phone number',
    otp: process.env.NODE_ENV === 'development' ? otpCode : undefined // Only in dev
  };
};

/**
 * Verify OTP and login customer
 */
export const verifyOTPAndLogin = async (phone, otp) => {
  const user = await User.findOne({ phone, role: 'customer' }).select('+otp.code +otp.expiresAt');

  if (!user) {
    throw new AppError('User not found. Please register first.', 404);
  }

  // Check if OTP exists and is valid
  if (!user.otp || !user.otp.code) {
    throw new AppError('OTP not found. Please request a new OTP.', 400);
  }

  // Check if OTP is expired
  const now = new Date();
  if (now > user.otp.expiresAt) {
    console.log(`❌ Phone OTP expired for ${phone}. Expires: ${user.otp.expiresAt}, Now: ${now}`);
    throw new AppError('OTP has expired. Please request a new OTP.', 400);
  }

  // Verify OTP (compare as strings, trim whitespace)
  const storedOTP = String(user.otp.code).trim();
  const providedOTP = String(otp).trim();
  
  console.log(`🔍 Phone OTP Verification - Phone: ${phone}, Stored: "${storedOTP}", Provided: "${providedOTP}"`);
  
  if (storedOTP !== providedOTP) {
    console.log(`❌ Phone OTP Mismatch - Stored: "${storedOTP}" (length: ${storedOTP.length}), Provided: "${providedOTP}" (length: ${providedOTP.length})`);
    throw new AppError('Invalid OTP. Please try again.', 401);
  }
  
  console.log(`✅ Phone OTP Verified successfully for ${phone}`);

  // Check if user is blocked
  if (user.is_blocked) {
    throw new AppError('Your account has been blocked. Please contact support.', 403);
  }

  // Check if user is active
  if (!user.is_active) {
    throw new AppError('Your account has been deactivated. Please contact support.', 403);
  }

  // Mark phone as verified and clear OTP
  user.phone_verified = true;
  user.otp = undefined;
  await user.save();

  // Generate tokens
  const tokenPayload = {
    id: user._id.toString(),
    phone: user.phone,
    role: user.role
  };

  const accessToken = generateAccessToken(tokenPayload);
  const refreshToken = generateRefreshToken(tokenPayload);

  return {
    token: accessToken,
    refreshToken: refreshToken,
    user: {
      id: user._id.toString(),
      name: user.name,
      phone: user.phone,
      email: user.email,
      role: user.role,
      phone_verified: user.phone_verified,
      wallet_balance: user.wallet_balance
    }
  };
};

/**
 * Resend OTP
 */
export const resendOTP = async (phone) => {
  const user = await User.findOne({ phone, role: 'customer' });

  if (!user) {
    throw new AppError('User not found. Please register first.', 404);
  }

  // Generate new OTP
  const otpCode = generateOTP();
  const otpExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

  user.otp = {
    code: String(otpCode).trim(), // Ensure OTP is stored as trimmed string
    expiresAt: otpExpires
  };
  await user.save();

  console.log(`📧 Generated Resend Phone OTP for ${phone}: "${otpCode}" (stored as: "${user.otp.code}")`);
  // TODO: Send OTP via SMS service
  console.log(`OTP for ${phone}: ${otpCode}`); // Remove in production

  return {
    phone,
    message: 'OTP resent to your phone number',
    otp: process.env.NODE_ENV === 'development' ? otpCode : undefined
  };
};

/**
 * Login with email and password
 * Requires: email_verified=true (customers must verify email via OTP)
 */
export const loginWithEmail = async (email, password) => {
  const normalizedEmail = email.toLowerCase().trim();
  
  const user = await User.findOne({ email: normalizedEmail, role: 'customer' }).select('+password');

  if (!user) {
    throw new AppError('Invalid email or password', 401);
  }

  if (!user.password) {
    throw new AppError('Password not set. Please use email OTP or set password first.', 400);
  }

  // Check if user is blocked
  if (user.is_blocked) {
    throw new AppError('Your account has been blocked. Please contact support.', 403);
  }

  // Check if user is active
  if (!user.is_active) {
    throw new AppError('Your account has been deactivated. Please contact support.', 403);
  }

  // Note: Email verification is optional for customers - they can login without verification
  // OTP email is sent but not required for login

  // Verify password
  const isPasswordValid = await user.comparePassword(password);
  if (!isPasswordValid) {
    throw new AppError('Invalid email or password', 401);
  }

  // Generate tokens
  const tokenPayload = {
    id: user._id.toString(),
    email: user.email,
    phone: user.phone,
    role: user.role
  };

  const accessToken = generateAccessToken(tokenPayload);
  const refreshToken = generateRefreshToken(tokenPayload);

  return {
    token: accessToken,
    refreshToken: refreshToken,
    user: {
      id: user._id.toString(),
      name: user.name,
      phone: user.phone,
      email: user.email,
      role: user.role,
      phone_verified: user.phone_verified,
      email_verified: user.email_verified,
      wallet_balance: user.wallet_balance
    },
    message: 'Login successful'
  };
};

/**
 * Register with email and password
 * Customers: Status is active by default, tokens returned immediately
 * OTP email is sent but not required for login
 */
export const registerWithEmail = async (email, password, name, phone) => {
  const normalizedEmail = email.toLowerCase().trim();
  
  // Check if email already exists with customer role
  const existingEmail = await User.findOne({ email: normalizedEmail, role: 'customer' });
  if (existingEmail) {
    throw new AppError('Email already registered', 400);
  }

  // Check if phone already exists with customer role
  const existingPhone = await User.findOne({ phone, role: 'customer' });
  if (existingPhone) {
    throw new AppError('Phone number already registered as customer', 400);
  }

  // Check if phone exists with different role
  const phoneWithOtherRole = await User.findOne({ phone, role: { $ne: 'customer' } });
  if (phoneWithOtherRole) {
    throw new AppError('This phone number is already registered with a different account type. Please use a different phone number.', 400);
  }

  // Create user - email NOT verified initially, but status is active (customers don't need admin approval)
  const user = await User.create({
    email: normalizedEmail,
    password,
    name,
    phone,
    role: 'customer',
    email_verified: false, // Can verify later via OTP
    is_active: true // Customers are active by default
  });

  // Generate and send OTP email automatically after registration
  const otpCode = generateEmailOTP();
  const otpExpires = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

  user.otp = {
    code: String(otpCode).trim(), // Ensure OTP is stored as trimmed string
    expiresAt: otpExpires
  };
  await user.save();

  console.log(`📧 Generated OTP for ${normalizedEmail}: "${otpCode}" (stored as: "${user.otp.code}")`);

  // Send OTP email asynchronously (non-blocking - don't wait for email to complete)
  // This prevents connection timeout issues
  emailService.sendOTPEmail(normalizedEmail, otpCode, name || 'Customer', 'customer')
    .then(() => {
      console.log(`✅ Registration OTP email sent to ${normalizedEmail}`);
    })
    .catch((emailError) => {
      console.error(`❌ Failed to send registration OTP email to ${normalizedEmail}:`, emailError);
      if (process.env.NODE_ENV === 'development') {
        console.log(`📧 Development mode - Registration OTP: ${otpCode}`);
      }
      // Don't throw error - registration succeeds even if email fails
    });

  // Generate tokens immediately (customer can login right away)
  const tokenPayload = {
    id: user._id.toString(),
    email: user.email,
    phone: user.phone,
    role: user.role
  };

  const accessToken = generateAccessToken(tokenPayload);
  const refreshToken = generateRefreshToken(tokenPayload);

  return {
    token: accessToken,
    refreshToken: refreshToken,
    email: normalizedEmail,
    email_verified: false,
    status: 'active', // Customers are always active
    user: {
      id: user._id.toString(),
      name: user.name,
      phone: user.phone,
      email: user.email,
      role: user.role,
      phone_verified: user.phone_verified,
      email_verified: user.email_verified,
      wallet_balance: user.wallet_balance || 0
    },
    message: 'Account created successfully. Welcome email with OTP has been sent to your inbox.'
  };
};

/**
 * Request email OTP for customer (4-digit, expires in 5 minutes)
 */
export const requestEmailOTP = async (email) => {
  const normalizedEmail = email.toLowerCase().trim();
  
  const user = await User.findOne({ email: normalizedEmail, role: 'customer' });

  if (!user) {
    // Don't reveal if email exists for security
    return {
      email: normalizedEmail,
      message: 'If an account exists with this email, an OTP has been sent.',
      status: 'active'
    };
  }

  // Check if user is blocked
  if (user.is_blocked) {
    throw new AppError('Your account has been blocked. Please contact support.', 403);
  }

  // Check if user is active
  if (!user.is_active) {
    throw new AppError('Your account has been deactivated. Please contact support.', 403);
  }

  // Generate OTP (4-digit, expires in 5 minutes)
  const otpCode = generateEmailOTP();
  const otpExpires = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

  user.otp = {
    code: String(otpCode).trim(), // Ensure OTP is stored as trimmed string
    expiresAt: otpExpires
  };
  await user.save();

  console.log(`📧 Generated OTP for ${normalizedEmail}: "${otpCode}" (stored as: "${user.otp.code}")`);

  // Send OTP email
  try {
    await emailService.sendOTPEmail(normalizedEmail, otpCode, user.name || 'Customer', 'customer');
    console.log(`✅ OTP email sent to ${normalizedEmail}`);
  } catch (emailError) {
    console.error(`❌ Failed to send OTP email to ${normalizedEmail}:`, emailError);
    // In development, still return OTP even if email fails
    if (process.env.NODE_ENV === 'development') {
      console.log(`📧 Development mode - OTP: ${otpCode}`);
    } else {
      throw new AppError('Failed to send OTP email. Please try again later.', 500);
    }
  }

  return {
    email: normalizedEmail,
    message: 'OTP sent to your email',
    status: 'active',
    otp: process.env.NODE_ENV === 'development' ? otpCode : undefined // Only in dev
  };
};

/**
 * Verify email OTP for customer
 * Customers: Always returns tokens (status is always active)
 */
export const verifyEmailOTP = async (email, otp) => {
  const normalizedEmail = email.toLowerCase().trim();
  
  // Select OTP fields explicitly (they are hidden by default)
  const user = await User.findOne({ email: normalizedEmail, role: 'customer' }).select('+otp.code +otp.expiresAt');

  if (!user) {
    throw new AppError('Account not found', 404);
  }

  // Check if OTP exists and is valid
  if (!user.otp || !user.otp.code) {
    console.log(`❌ OTP not found for ${normalizedEmail}`);
    throw new AppError('OTP not found. Please request a new OTP.', 400);
  }

  // Check if OTP is expired (5 minutes)
  const now = new Date();
  if (now > user.otp.expiresAt) {
    console.log(`❌ OTP expired for ${normalizedEmail}. Expires: ${user.otp.expiresAt}, Now: ${now}`);
    throw new AppError('OTP has expired. Please request a new OTP.', 400);
  }

  // Verify OTP (compare as strings, trim whitespace, ensure exact match)
  const storedOTP = String(user.otp.code).trim();
  const providedOTP = String(otp).trim();
  
  console.log(`🔍 OTP Verification - Email: ${normalizedEmail}, Stored: "${storedOTP}" (type: ${typeof storedOTP}), Provided: "${providedOTP}" (type: ${typeof providedOTP})`);
  
  if (storedOTP !== providedOTP) {
    console.log(`❌ OTP Mismatch - Stored: "${storedOTP}" (length: ${storedOTP.length}), Provided: "${providedOTP}" (length: ${providedOTP.length})`);
    throw new AppError('Invalid OTP. Please try again.', 401);
  }
  
  console.log(`✅ OTP Verified successfully for ${normalizedEmail}`);

  // Check if user is blocked
  if (user.is_blocked) {
    throw new AppError('Your account has been blocked. Please contact support.', 403);
  }

  // Check if user is active
  if (!user.is_active) {
    throw new AppError('Your account has been deactivated. Please contact support.', 403);
  }

  // Mark email as verified and clear OTP
  user.email_verified = true;
  user.otp = undefined;
  await user.save();

  // Generate tokens (customers always get tokens - no pending status)
  const tokenPayload = {
    id: user._id.toString(),
    email: user.email,
    phone: user.phone,
    role: user.role
  };

  const accessToken = generateAccessToken(tokenPayload);
  const refreshToken = generateRefreshToken(tokenPayload);

  return {
    token: accessToken,
    refreshToken: refreshToken,
    canLogin: true, // Customers can always login after email verification
    email_verified: true,
    status: 'active', // Customers are always active
    user: {
      id: user._id.toString(),
      name: user.name,
      phone: user.phone,
      email: user.email,
      role: user.role,
      phone_verified: user.phone_verified,
      email_verified: user.email_verified,
      wallet_balance: user.wallet_balance
    },
    message: 'Email verified successfully. You can now login.'
  };
};

/**
 * Request password reset (sends 4-digit OTP, expires in 5 minutes)
 */
export const requestPasswordReset = async (email) => {
  const normalizedEmail = email.toLowerCase().trim();
  
  const user = await User.findOne({ email: normalizedEmail, role: 'customer' });

  if (!user) {
    // Don't reveal if email exists for security
    return {
      message: 'If an account exists with this email, a password reset code has been sent.'
    };
  }

  // Check if user is blocked
  if (user.is_blocked) {
    throw new AppError('Your account has been blocked. Please contact support.', 403);
  }

  // Generate reset code (using OTP field temporarily)
  // OTP expires in 5 minutes
  const resetCode = generateEmailOTP();
  const resetExpires = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

  user.otp = {
    code: String(resetCode).trim(), // Ensure OTP is stored as trimmed string
    expiresAt: resetExpires
  };
  await user.save();

  console.log(`📧 Generated Password Reset OTP for ${normalizedEmail}: "${resetCode}" (stored as: "${user.otp.code}")`);

  // Send password reset email (with customer role for correct branding)
  try {
    await emailService.sendPasswordResetEmail(normalizedEmail, resetCode, user.name || 'Customer', 'customer');
    console.log(`✅ Password reset email sent to ${normalizedEmail} (Customer)`);
  } catch (emailError) {
    console.error(`❌ Failed to send password reset email to ${normalizedEmail}:`, emailError);
    // In development, still return reset code even if email fails
    if (process.env.NODE_ENV === 'development') {
      console.log(`📧 Development mode - Reset Code: ${resetCode}`);
    } else {
      throw new AppError('Failed to send password reset email. Please try again later.', 500);
    }
  }

  return {
    message: 'If an account exists with this email, a password reset code has been sent.',
    resetCode: process.env.NODE_ENV === 'development' ? resetCode : undefined // Only in dev
  };
};

/**
 * Reset password with OTP
 */
export const resetPassword = async (email, otp, newPassword) => {
  const normalizedEmail = email.toLowerCase().trim();
  
  const user = await User.findOne({ email: normalizedEmail, role: 'customer' }).select('+password +otp.code +otp.expiresAt');

  if (!user) {
    throw new AppError('Invalid reset code', 400);
  }

  // Check if OTP exists and is valid
  if (!user.otp || !user.otp.code) {
    throw new AppError('Reset code not found. Please request a new reset code.', 400);
  }

  // Check if OTP is expired
  const now = new Date();
  if (now > user.otp.expiresAt) {
    console.log(`❌ Password Reset OTP expired for ${normalizedEmail}. Expires: ${user.otp.expiresAt}, Now: ${now}`);
    throw new AppError('Reset code has expired. Please request a new reset code.', 400);
  }

  // Verify OTP (compare as strings, trim whitespace)
  const storedOTP = String(user.otp.code).trim();
  const providedOTP = String(otp).trim();
  
  console.log(`🔍 Password Reset OTP Verification - Email: ${normalizedEmail}, Stored: "${storedOTP}", Provided: "${providedOTP}"`);
  
  if (storedOTP !== providedOTP) {
    console.log(`❌ Password Reset OTP Mismatch - Stored: "${storedOTP}" (length: ${storedOTP.length}), Provided: "${providedOTP}" (length: ${providedOTP.length})`);
    throw new AppError('Invalid reset code', 400);
  }
  
  console.log(`✅ Password Reset OTP Verified successfully for ${normalizedEmail}`);

  // Update password and clear OTP
  user.password = newPassword;
  user.otp = undefined;
  await user.save();

  return {
    message: 'Password reset successfully. You can now login with your new password.'
  };
};

/**
 * Check customer status by email (public endpoint - no auth required)
 */
export const checkStatusByEmail = async (email) => {
  const normalizedEmail = email.toLowerCase().trim();
  
  const user = await User.findOne({ email: normalizedEmail, role: 'customer' });
  
  if (!user) {
    throw new AppError('Account not found', 404);
  }
  
  return {
    status: 'active', // Customers are always active
    email_verified: user.email_verified,
    email: user.email,
    name: user.name,
  };
};

/**
 * Refresh access token
 */
export const refreshAccessToken = async (refreshTokenInput) => {
  try {
    const decoded = verifyRefreshToken(refreshTokenInput);

    const user = await User.findById(decoded.id);

    if (!user) {
      throw new AppError('User not found', 404);
    }

    if (user.role !== 'customer') {
      throw new AppError('Invalid token for customer', 401);
    }

    if (!user.is_active) {
      throw new AppError('Your account has been deactivated', 403);
    }

    if (user.is_blocked) {
      throw new AppError('Your account has been blocked', 403);
    }

    const tokenPayload = {
      id: user._id.toString(),
      email: user.email,
      phone: user.phone,
      role: user.role
    };

    const accessToken = generateAccessToken(tokenPayload);

    return {
      token: accessToken,
      refreshToken: refreshTokenInput, // Return same refresh token (it's still valid until expiry)
      user: {
        id: user._id.toString(),
        name: user.name,
        phone: user.phone,
        email: user.email,
        role: user.role,
        wallet_balance: user.wallet_balance
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
 * Get customer by ID
 */
export const getCustomerById = async (customerId) => {
  const user = await User.findById(customerId);

  if (!user) {
    throw new AppError('Customer not found', 404);
  }

  if (user.role !== 'customer') {
    throw new AppError('User is not a customer', 400);
  }

  if (!user.is_active) {
    throw new AppError('Your account has been deactivated', 403);
  }

  return user;
};


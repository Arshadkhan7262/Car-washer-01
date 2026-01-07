import User from '../models/User.model.js';
import Washer from '../models/Washer.model.js';
import AppError from '../errors/AppError.js';
import { generateAccessToken, generateRefreshToken, verifyRefreshToken } from '../config/jwt.config.js';
import emailService from './email.service.js';

/**
 * Generate OTP code (6 digits) - DEPRECATED: Use generateEmailOTP for email OTP
 */
const generateOTP = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

/**
 * Get or create washer profile for a user (auto-fix for missing profiles)
 */
const getOrCreateWasherProfile = async (user) => {
  let washer = await Washer.findOne({ user_id: user._id });
  
  if (!washer) {
    washer = await Washer.create({
      user_id: user._id,
      name: user.name,
      phone: user.phone,
      email: user.email,
      status: 'pending', // Start as pending - admin must approve
      online_status: false
    });
  }
  
  return washer;
};

/**
 * Register washer with phone (request OTP)
 */
export const registerWithPhone = async (phone, name, email = null) => {
  // Check if user already exists with washer role
  let user = await User.findOne({ phone, role: 'washer' });

  if (user) {
    // User exists, check if washer profile exists
    const existingWasher = await Washer.findOne({ user_id: user._id });
    if (existingWasher) {
      throw new AppError('Phone number already registered as washer', 400);
    }
    // User exists but no washer profile - create washer profile
  } else {
    // Check if phone exists with different role
    const existingPhone = await User.findOne({ phone });
    if (existingPhone) {
      throw new AppError('This phone number is already registered with a different account type. Please use a different phone number.', 400);
    }

    // Create new user
    user = await User.create({
      phone,
      name,
      email: email ? email.toLowerCase() : null,
      role: 'washer',
      is_active: true
    });
  }

  // Check if washer profile already exists
  const existingWasher = await Washer.findOne({ user_id: user._id });
  if (existingWasher) {
    throw new AppError('Washer profile already exists for this user', 400);
  }

  // Create washer profile with 'pending' status
  const washer = await Washer.create({
    user_id: user._id,
    name,
    phone,
    email: email ? email.toLowerCase() : null,
    status: 'pending', // Start as pending - admin must approve
    online_status: false
  });

  // Generate OTP
  const otpCode = generateOTP();
  const otpExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

  user.otp = {
    code: otpCode,
    expiresAt: otpExpires
  };
  await user.save();

  // TODO: Send OTP via SMS service
  console.log(`OTP for washer registration ${phone}: ${otpCode}`); // Remove in production

  return {
    phone,
    message: 'OTP sent to your phone number. Your account is pending admin approval.',
    status: 'pending',
    otp: process.env.NODE_ENV === 'development' ? otpCode : undefined // Only in dev
  };
};

/**
 * Request OTP for washer login
 */
export const requestOTP = async (phone) => {
  // Find user with washer role
  const user = await User.findOne({ phone, role: 'washer' });

  if (!user) {
    throw new AppError('Washer account not found. Please register first or contact admin.', 404);
  }

  // Check if user is blocked
  if (user.is_blocked) {
    throw new AppError('Your account has been blocked. Please contact support.', 403);
  }

  // Check if user is active
  if (!user.is_active) {
    throw new AppError('Your account has been deactivated. Please contact support.', 403);
  }

  // Get or create washer profile
  const washer = await getOrCreateWasherProfile(user);

  // Check washer status
  if (washer.status === 'suspended') {
    throw new AppError('Your washer account has been suspended. Please contact admin.', 403);
  }

  // Generate OTP
  const otpCode = generateOTP();
  const otpExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

  user.otp = {
    code: otpCode,
    expiresAt: otpExpires
  };
  await user.save();

  // TODO: Send OTP via SMS service
  console.log(`OTP for washer ${phone}: ${otpCode}`); // Remove in production

  return {
    phone,
    message: 'OTP sent to your phone number',
    status: washer.status,
    otp: process.env.NODE_ENV === 'development' ? otpCode : undefined // Only in dev
  };
};

/**
 * Verify OTP and login washer
 */
export const verifyOTPAndLogin = async (phone, otp) => {
  // IMPORTANT: Must explicitly select OTP field since it has select: false
  const user = await User.findOne({ phone, role: 'washer' }).select('+otp.code +otp.expiresAt');

  if (!user) {
    throw new AppError('Washer account not found. Please contact admin.', 404);
  }

  // Check if OTP exists and is valid
  if (!user.otp || !user.otp.code) {
    throw new AppError('OTP not found. Please request a new OTP.', 400);
  }

  // Check if OTP is expired
  if (new Date() > user.otp.expiresAt) {
    throw new AppError('OTP has expired. Please request a new OTP.', 400);
  }

  // Verify OTP
  if (user.otp.code !== otp) {
    throw new AppError('Invalid OTP. Please try again.', 401);
  }

  // Check if user is blocked
  if (user.is_blocked) {
    throw new AppError('Your account has been blocked. Please contact support.', 403);
  }

  // Check if user is active
  if (!user.is_active) {
    throw new AppError('Your account has been deactivated. Please contact support.', 403);
  }

  // Get or create washer profile
  const washer = await getOrCreateWasherProfile(user);

  // Check washer status
  if (washer.status === 'suspended') {
    throw new AppError('Your washer account has been suspended. Please contact admin.', 403);
  }

  if (washer.status === 'inactive') {
    throw new AppError('Your account is inactive. Please contact admin.', 403);
  }

  // Mark phone as verified and clear OTP
  user.phone_verified = true;
  user.otp = undefined;
  await user.save();

  // Generate tokens
  const tokenPayload = {
    id: user._id.toString(),
    phone: user.phone,
    role: user.role,
    washer_id: washer._id.toString()
  };

  const accessToken = generateAccessToken(tokenPayload);
  const refreshToken = generateRefreshToken(tokenPayload);

  // Prepare response
  const response = {
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
    },
    washer: {
      id: washer._id.toString(),
      name: washer.name,
      status: washer.status,
      online_status: washer.online_status,
      rating: washer.rating,
      total_jobs: washer.total_jobs,
      completed_jobs: washer.completed_jobs,
      wallet_balance: washer.wallet_balance,
      total_earnings: washer.total_earnings
    }
  };

  // If status is pending, add message but still allow login
  if (washer.status === 'pending') {
    response.message = 'Your account is pending admin approval. You can view your profile but cannot accept jobs yet.';
  }

  return response;
};

/**
 * Resend OTP
 */
export const resendOTP = async (phone) => {
  const user = await User.findOne({ phone, role: 'washer' }).select('+otp.code +otp.expiresAt');

  if (!user) {
    throw new AppError('Washer account not found. Please contact admin.', 404);
  }

  // Check if user is blocked
  if (user.is_blocked) {
    throw new AppError('Your account has been blocked. Please contact support.', 403);
  }

  // Get or create washer profile
  const washer = await getOrCreateWasherProfile(user);

  // Generate new OTP
  const otpCode = generateOTP();
  const otpExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

  user.otp = {
    code: otpCode,
    expiresAt: otpExpires
  };
  await user.save();

  // TODO: Send OTP via SMS service
  console.log(`OTP for washer ${phone}: ${otpCode}`); // Remove in production

  return {
    phone,
    message: 'OTP resent to your phone number',
    status: washer.status,
    otp: process.env.NODE_ENV === 'development' ? otpCode : undefined
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

    if (user.role !== 'washer') {
      throw new AppError('Invalid token for washer', 401);
    }

    if (!user.is_active) {
      throw new AppError('Your account has been deactivated', 403);
    }

    if (user.is_blocked) {
      throw new AppError('Your account has been blocked', 403);
    }

    // Get or create washer profile
    const washer = await getOrCreateWasherProfile(user);

    if (washer.status === 'suspended' || washer.status === 'inactive') {
      throw new AppError('Your washer account has been suspended or is inactive', 403);
    }

    const tokenPayload = {
      id: user._id.toString(),
      phone: user.phone,
      role: user.role,
      washer_id: washer._id.toString()
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
      },
      washer: {
        id: washer._id.toString(),
        name: washer.name,
        status: washer.status,
        online_status: washer.online_status,
        rating: washer.rating,
        total_jobs: washer.total_jobs,
        completed_jobs: washer.completed_jobs,
        wallet_balance: washer.wallet_balance,
        total_earnings: washer.total_earnings
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
 * Get washer by ID
 */
/**
 * Check washer status by email (public endpoint - no auth required)
 * Used for pending accounts that don't have tokens yet
 */
export const checkStatusByEmail = async (email) => {
  const normalizedEmail = email.toLowerCase().trim();
  
  const user = await User.findOne({ email: normalizedEmail, role: 'washer' });
  
  if (!user) {
    throw new AppError('Account not found', 404);
  }
  
  const washer = await Washer.findOne({ user_id: user._id });
  
  if (!washer) {
    throw new AppError('Washer profile not found', 404);
  }
  
  return {
    status: washer.status,
    email_verified: user.email_verified,
    email: user.email,
    name: user.name,
  };
};

export const getWasherById = async (userId) => {
  const user = await User.findById(userId);

  if (!user) {
    throw new AppError('User not found', 404);
  }

  if (user.role !== 'washer') {
    throw new AppError('User is not a washer', 400);
  }

  if (!user.is_active) {
    throw new AppError('Your account has been deactivated', 403);
  }

  // Get or create washer profile
  const washer = await getOrCreateWasherProfile(user);

  return { user, washer };
};

/**
 * Generate 4-digit OTP code for email verification
 * OTP expires in 5 minutes as per UI requirements
 */
const generateEmailOTP = () => {
  return Math.floor(1000 + Math.random() * 9000).toString();
};

/**
 * Login washer with email and password
 */
export const loginWithEmail = async (email, password) => {
  const user = await User.findOne({ email: email.toLowerCase(), role: 'washer' }).select('+password');

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

  // Verify password
  const isPasswordValid = await user.comparePassword(password);
  if (!isPasswordValid) {
    throw new AppError('Invalid email or password', 401);
  }

  // Get or create washer profile
  const washer = await getOrCreateWasherProfile(user);

  // CRITICAL: Check email verification status - Washer cannot login until email is verified
  if (!user.email_verified) {
    throw new AppError('Please verify your email before logging in. Check your inbox for the verification OTP.', 403);
  }

  // CRITICAL: Check washer status - Washer cannot login until admin approves (status = active)
  if (washer.status === 'pending') {
    throw new AppError('Your account is pending admin approval. You cannot login until your account is activated.', 403);
  }

  if (washer.status === 'suspended') {
    throw new AppError('Your washer account has been suspended. Please contact admin.', 403);
  }

  if (washer.status === 'inactive') {
    throw new AppError('Your account is inactive. Please contact admin.', 403);
  }

  // Status must be 'active' to login
  if (washer.status !== 'active') {
    throw new AppError('Your account is not active. Please contact admin.', 403);
  }

  // Generate tokens
  const tokenPayload = {
    id: user._id.toString(),
    email: user.email,
    phone: user.phone,
    role: user.role,
    washer_id: washer._id.toString()
  };

  const accessToken = generateAccessToken(tokenPayload);
  const refreshToken = generateRefreshToken(tokenPayload);

  // Prepare response
  const response = {
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
    washer: {
      id: washer._id.toString(),
      name: washer.name,
      status: washer.status,
      online_status: washer.online_status,
      rating: washer.rating,
      total_jobs: washer.total_jobs,
      completed_jobs: washer.completed_jobs,
      wallet_balance: washer.wallet_balance,
      total_earnings: washer.total_earnings
    }
  };

  // If status is pending, add message but still allow login
  if (washer.status === 'pending') {
    response.message = 'Your account is pending admin approval. You can view your profile but cannot accept jobs yet.';
  }

  return response;
};

/**
 * Register washer with email and password
 */
/**
 * Register washer with email and password
 * 
 * UI Flow: Create Account Screen
 * - Email, Password, Confirm Password
 * - After registration: email_verified = false, status = pending
 * - User must verify email via OTP before login
 * - Admin must approve (status = active) before login
 */
export const registerWithEmail = async (email, password, name, phone) => {
  // Normalize email for consistent lookup and storage
  const normalizedEmail = email.toLowerCase().trim();
  
  // Check if email already exists with washer role
  let user = await User.findOne({ email: normalizedEmail, role: 'washer' });
  
  if (user) {
    // User exists, check if washer profile exists
    const existingWasher = await Washer.findOne({ user_id: user._id });
    if (existingWasher) {
      throw new AppError('Email already registered', 400);
    }
    // User exists but no washer profile - update user and create washer profile
    user.password = password; // Update password
    user.name = name; // Update name
    user.phone = phone; // Update phone
    // IMPORTANT: email_verified = false on registration (must verify via OTP)
    user.email_verified = false;
    user.is_active = true;
    await user.save();
  } else {
    // Check if phone already exists with washer role
    const existingPhone = await User.findOne({ phone, role: 'washer' });
    if (existingPhone) {
      throw new AppError('Phone number already registered as washer', 400);
    }

    // Check if phone exists with different role
    const phoneWithOtherRole = await User.findOne({ phone, role: { $ne: 'washer' } });
    if (phoneWithOtherRole) {
      throw new AppError('This phone number is already registered with a different account type. Please use a different phone number.', 400);
    }

    // Check if email exists with different role
    const emailWithOtherRole = await User.findOne({ email: normalizedEmail, role: { $ne: 'washer' } });
    if (emailWithOtherRole) {
      throw new AppError('This email is already registered with a different account type. Please use a different email.', 400);
    }

    // Create new user
    // IMPORTANT: email_verified = false on registration (must verify via OTP)
    // Washers use email/password authentication, not Firebase
    user = await User.create({
      email: normalizedEmail, // Use normalized email
      password,
      name,
      phone,
      role: 'washer',
      email_verified: false, // Must verify email via OTP
      is_active: true
      // firebaseUid remains null for email-based authentication
    });
  }

  // Check if washer profile already exists (shouldn't happen, but safety check)
  const existingWasher = await Washer.findOne({ user_id: user._id });
  if (existingWasher) {
    throw new AppError('Washer profile already exists for this user', 400);
  }

  // Create washer profile with 'pending' status
  const washer = await Washer.create({
    user_id: user._id,
    name,
    phone,
    email: normalizedEmail, // Use normalized email
    status: 'pending', // Start as pending - admin must approve
    online_status: false
  });

  // Generate and send OTP email automatically after registration
  const otpCode = generateEmailOTP();
  const otpExpires = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

  user.otp = {
    code: otpCode,
    expiresAt: otpExpires
  };
  await user.save();

  // Send OTP via email service (with washer role for correct branding)
  try {
    await emailService.sendOTPEmail(normalizedEmail, otpCode, name || 'User', 'washer');
    console.log(`✅ Registration OTP email sent to ${normalizedEmail} (Washer)`);
  } catch (emailError) {
    console.error(`❌ Failed to send registration OTP email to ${normalizedEmail}:`, emailError);
    // In development, still return OTP even if email fails
    if (process.env.NODE_ENV === 'development') {
      console.log(`📧 Development mode - Registration OTP: ${otpCode}`);
    } else {
      // In production, don't reveal OTP if email fails
      // Still save OTP so user can request it again
      console.warn(`⚠️ Email service failed, but OTP saved. User can request OTP again.`);
    }
  }

  // IMPORTANT: Do NOT return tokens on registration
  // User must verify email via OTP first, then admin must approve
  // Return success message directing user to verify email
  return {
    success: true,
    message: 'Account created successfully. Please verify your email with the OTP sent to your inbox. After verification, your account will be pending admin approval.',
    email: user.email,
    email_verified: false,
    status: 'pending',
    nextStep: 'verify_email', // UI should navigate to email verification screen
    otp: process.env.NODE_ENV === 'development' ? otpCode : undefined // Only in dev mode
  };
};

/**
 * Request email OTP for login/verification
 */
export const requestEmailOTP = async (email) => {
  // Normalize email for lookup (consistent with registration)
  const normalizedEmail = email.toLowerCase().trim();
  
  // Find user with washer role
  // IMPORTANT: Must explicitly select OTP field since it has select: false
  let user = await User.findOne({ email: normalizedEmail, role: 'washer' }).select('+otp.code +otp.expiresAt');

  // If not found, try case-insensitive search as fallback
  if (!user) {
    user = await User.findOne({ 
      email: { $regex: new RegExp(`^${normalizedEmail}$`, 'i') }, 
      role: 'washer' 
    }).select('+otp.code +otp.expiresAt');
  }

  if (!user) {
    throw new AppError(
      `Washer account not found for email: ${email}. Please register first or contact admin.`, 
      404
    );
  }

  // Check if user is blocked
  if (user.is_blocked) {
    throw new AppError('Your account has been blocked. Please contact support.', 403);
  }

  // Check if user is active
  if (!user.is_active) {
    throw new AppError('Your account has been deactivated. Please contact support.', 403);
  }

  // Get or create washer profile
  const washer = await getOrCreateWasherProfile(user);

  // Check washer status
  if (washer.status === 'suspended') {
    throw new AppError('Your washer account has been suspended. Please contact admin.', 403);
  }

  // Generate 4-digit OTP (expires in 5 minutes as per UI requirements)
  const otpCode = generateEmailOTP();
  const otpExpires = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes (changed from 10)

  user.otp = {
    code: otpCode,
    expiresAt: otpExpires
  };
  await user.save();

  // Send OTP via email service
  try {
    await emailService.sendOTPEmail(normalizedEmail, otpCode, user.name || 'User', 'washer');
    console.log(`✅ Email OTP sent to ${normalizedEmail}`);
  } catch (emailError) {
    console.error(`❌ Failed to send email OTP to ${normalizedEmail}:`, emailError);
    // In development, still return OTP even if email fails
    if (process.env.NODE_ENV === 'development') {
      console.log(`📧 Development mode - OTP: ${otpCode}`);
    } else {
      // In production, don't reveal OTP if email fails
      throw new AppError('Failed to send OTP email. Please try again later.', 500);
    }
  }

  return {
    email: normalizedEmail,
    message: 'OTP sent to your email',
    status: washer.status,
    otp: process.env.NODE_ENV === 'development' ? otpCode : undefined // Only in dev
  };
};

/**
 * Verify email OTP and login washer
 */
export const verifyEmailOTP = async (email, otp) => {
  // Normalize email for lookup
  const normalizedEmail = email.toLowerCase().trim();
  
  // First, try to find user with exact email match
  // IMPORTANT: Must explicitly select OTP field since it has select: false
  let user = await User.findOne({ email: normalizedEmail, role: 'washer' }).select('+otp.code +otp.expiresAt');

  // If not found, try case-insensitive search as fallback
  if (!user) {
    user = await User.findOne({ 
      email: { $regex: new RegExp(`^${normalizedEmail}$`, 'i') }, 
      role: 'washer' 
    }).select('+otp.code +otp.expiresAt');
  }

  if (!user) {
    // Provide more helpful error message
    throw new AppError(
      `Washer account not found for email: ${email}. Please ensure you have registered and the email is correct.`, 
      404
    );
  }

  // Check if OTP exists and is valid
  if (!user.otp || !user.otp.code) {
    throw new AppError('OTP not found. Please request a new OTP.', 400);
  }

  // Check if OTP is expired
  if (new Date() > user.otp.expiresAt) {
    throw new AppError('OTP has expired. Please request a new OTP.', 400);
  }

  // Verify OTP
  if (user.otp.code !== otp) {
    throw new AppError('Invalid OTP. Please try again.', 401);
  }

  // Check if user is blocked
  if (user.is_blocked) {
    throw new AppError('Your account has been blocked. Please contact support.', 403);
  }

  // Check if user is active
  if (!user.is_active) {
    throw new AppError('Your account has been deactivated. Please contact support.', 403);
  }

  // Get or create washer profile
  const washer = await getOrCreateWasherProfile(user);

  // Check washer status
  if (washer.status === 'suspended') {
    throw new AppError('Your washer account has been suspended. Please contact admin.', 403);
  }

  if (washer.status === 'inactive') {
    throw new AppError('Your account is inactive. Please contact admin.', 403);
  }

  // Mark email as verified and clear OTP
  user.email_verified = true;
  user.otp = undefined;
  await user.save();

  console.log(`✅ Email verified for user: ${user.email}`);

  // IMPORTANT: After email verification, check if account is active
  // Washer cannot login until admin approves (status = active)
  if (washer.status === 'pending') {
    return {
      success: true,
      email_verified: true,
      message: 'Email verified successfully. Your account is pending admin approval. You will be able to login once your account is activated.',
      status: washer.status,
      canLogin: false // Cannot login until status = active
    };
  }

  if (washer.status !== 'active') {
    return {
      success: true,
      email_verified: true,
      message: 'Email verified successfully. However, your account is not active. Please contact admin.',
      status: washer.status,
      canLogin: false
    };
  }

  // Account is active and email verified - generate tokens for login
  const tokenPayload = {
    id: user._id.toString(),
    email: user.email,
    phone: user.phone,
    role: user.role,
    washer_id: washer._id.toString()
  };

  const accessToken = generateAccessToken(tokenPayload);
  const refreshToken = generateRefreshToken(tokenPayload);

  // Prepare response
  const response = {
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
    washer: {
      id: washer._id.toString(),
      name: washer.name,
      status: washer.status,
      online_status: washer.online_status,
      rating: washer.rating,
      total_jobs: washer.total_jobs,
      completed_jobs: washer.completed_jobs,
      wallet_balance: washer.wallet_balance,
      total_earnings: washer.total_earnings
    },
    message: 'Email verified and login successful'
  };

  return response;
};

/**
 * Request password reset
 */
export const requestPasswordReset = async (email) => {
  const user = await User.findOne({ email: email.toLowerCase(), role: 'washer' });

  if (!user) {
    // Don't reveal if email exists for security
    return {
      message: 'If an account exists with this email, a password reset link has been sent.'
    };
  }

  // Check if user is blocked
  if (user.is_blocked) {
    throw new AppError('Your account has been blocked. Please contact support.', 403);
  }

  // Generate reset token (using OTP field temporarily)
  // OTP expires in 5 minutes as per UI requirements
  const resetCode = generateEmailOTP();
  const resetExpires = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes (changed from 30)

  user.otp = {
    code: resetCode,
    expiresAt: resetExpires
  };
  await user.save();

  // Send password reset email (with washer role for correct branding)
  try {
    await emailService.sendPasswordResetEmail(email.toLowerCase(), resetCode, user.name || 'User', 'washer');
    console.log(`✅ Password reset email sent to ${email} (Washer)`);
  } catch (emailError) {
    console.error(`❌ Failed to send password reset email to ${email}:`, emailError);
    // In development, still return reset code even if email fails
    if (process.env.NODE_ENV === 'development') {
      console.log(`📧 Development mode - Reset Code: ${resetCode}`);
    } else {
      // In production, don't reveal reset code if email fails
      throw new AppError('Failed to send password reset email. Please try again later.', 500);
    }
  }

  return {
    message: 'If an account exists with this email, a password reset link has been sent.',
    resetCode: process.env.NODE_ENV === 'development' ? resetCode : undefined // Only in dev
  };
};

/**
 * Reset password with OTP
 */
export const resetPassword = async (email, otp, newPassword) => {
  // IMPORTANT: Must explicitly select both password and OTP fields
  const user = await User.findOne({ email: email.toLowerCase(), role: 'washer' }).select('+password +otp.code +otp.expiresAt');

  if (!user) {
    throw new AppError('Invalid reset code', 400);
  }

  // Check if OTP exists and is valid
  if (!user.otp || !user.otp.code) {
    throw new AppError('Reset code not found. Please request a new reset code.', 400);
  }

  // Check if OTP is expired
  if (new Date() > user.otp.expiresAt) {
    throw new AppError('Reset code has expired. Please request a new reset code.', 400);
  }

  // Verify OTP
  if (user.otp.code !== otp) {
    throw new AppError('Invalid reset code. Please try again.', 401);
  }

  // Update password
  user.password = newPassword;
  user.otp = undefined;
  await user.save();

  return {
    message: 'Password reset successfully. You can now login with your new password.'
  };
};


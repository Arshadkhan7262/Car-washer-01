import * as customerAuthService from '../services/customerAuth.service.js';

/**
 * @desc    Register customer with phone (request OTP)
 * @route   POST /api/v1/customer/auth/register-phone
 * @access  Public
 */
export const registerWithPhone = async (req, res, next) => {
  try {
    const { phone, name } = req.body;

    if (!phone) {
      return res.status(400).json({
        success: false,
        message: 'Phone number is required'
      });
    }

    if (!name) {
      return res.status(400).json({
        success: false,
        message: 'Name is required'
      });
    }

    const result = await customerAuthService.registerWithPhone(phone, name);

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Verify OTP and login customer
 * @route   POST /api/v1/customer/auth/verify-otp
 * @access  Public
 */
export const verifyOTP = async (req, res, next) => {
  try {
    const { phone, otp } = req.body;

    if (!phone || !otp) {
      return res.status(400).json({
        success: false,
        message: 'Phone number and OTP are required'
      });
    }

    const result = await customerAuthService.verifyOTPAndLogin(phone, otp);

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Resend OTP
 * @route   POST /api/v1/customer/auth/resend-otp
 * @access  Public
 */
export const resendOTP = async (req, res, next) => {
  try {
    const { phone } = req.body;

    if (!phone) {
      return res.status(400).json({
        success: false,
        message: 'Phone number is required'
      });
    }

    const result = await customerAuthService.resendOTP(phone);

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Register customer with email and password (Email OTP flow)
 * @route   POST /api/v1/customer/auth/register
 * @access  Public
 */
export const registerWithEmail = async (req, res, next) => {
  try {
    const { email, password, name, phone } = req.body;

    if (!email || !password || !name || !phone) {
      return res.status(400).json({
        success: false,
        message: 'Email, password, name, and phone are required'
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 6 characters'
      });
    }

    console.log(`📝 Registration request received for: ${email}`);

    const result = await customerAuthService.registerWithEmail(email, password, name, phone);

    console.log(`✅ Registration successful for: ${email}`);

    res.status(201).json({
      success: true,
      data: result
    });
  } catch (error) {
    console.error(`❌ Registration error for ${req.body?.email || 'unknown'}:`, error);
    next(error);
  }
};

/**
 * @desc    Request email OTP for customer
 * @route   POST /api/v1/customer/auth/send-email-otp
 * @access  Public
 */
export const requestEmailOTP = async (req, res, next) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email is required'
      });
    }

    const result = await customerAuthService.requestEmailOTP(email);

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Verify email OTP for customer
 * @route   POST /api/v1/customer/auth/verify-email-otp
 * @access  Public
 */
export const verifyEmailOTP = async (req, res, next) => {
  try {
    const { email, otp } = req.body;

    if (!email || !otp) {
      return res.status(400).json({
        success: false,
        message: 'Email and OTP are required'
      });
    }

    const result = await customerAuthService.verifyEmailOTP(email, otp);

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Request password reset
 * @route   POST /api/v1/customer/auth/forgot-password
 * @access  Public
 */
export const requestPasswordReset = async (req, res, next) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email is required'
      });
    }

    const result = await customerAuthService.requestPasswordReset(email);

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Reset password with OTP
 * @route   POST /api/v1/customer/auth/reset-password
 * @access  Public
 */
export const resetPassword = async (req, res, next) => {
  try {
    const { email, otp, newPassword } = req.body;

    if (!email || !otp || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Email, OTP, and new password are required'
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 6 characters'
      });
    }

    const result = await customerAuthService.resetPassword(email, otp, newPassword);

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Check customer status by email (public - no auth required)
 * @route   POST /api/v1/customer/auth/check-status
 * @access  Public
 */
export const checkStatusByEmail = async (req, res, next) => {
  try {
    const { email } = req.body;
    
    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email is required'
      });
    }
    
    const statusData = await customerAuthService.checkStatusByEmail(email);
    
    res.status(200).json({
      success: true,
      data: statusData
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Login customer with email and password
 * @route   POST /api/v1/customer/auth/login
 * @access  Public
 */
export const loginWithEmail = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required'
      });
    }

    const result = await customerAuthService.loginWithEmail(email, password);

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Refresh access token
 * @route   POST /api/v1/customer/auth/refresh
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

    const result = await customerAuthService.refreshAccessToken(refreshToken);

    res.status(200).json({
      success: true,
      data: {
        token: result.token,
        refreshToken: result.refreshToken,
        user: result.user
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get current customer profile
 * @route   GET /api/v1/customer/auth/me
 * @access  Private
 */
export const getMe = async (req, res, next) => {
  try {
    const customer = await customerAuthService.getCustomerById(req.customer.id);

    res.status(200).json({
      success: true,
      data: customer
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Logout customer
 * @route   POST /api/v1/customer/auth/logout
 * @access  Private
 */
export const logout = async (req, res, next) => {
  try {
    // In a stateless JWT system, logout is handled client-side by removing the token.
    // If server-side token invalidation (e.g., blacklisting) is needed, implement it here.
    res.status(200).json({
      success: true,
      message: 'Logged out successfully'
    });
  } catch (error) {
    next(error);
  }
};


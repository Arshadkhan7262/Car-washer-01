import * as washerAuthService from '../services/washerAuth.service.js';

/**
 * @desc    Register washer with phone (request OTP)
 * @route   POST /api/v1/washer/auth/register
 * @access  Public
 */
export const register = async (req, res, next) => {
  try {
    const { phone, name, email } = req.body;

    if (!phone || !name) {
      return res.status(400).json({
        success: false,
        message: 'Phone number and name are required'
      });
    }

    const result = await washerAuthService.registerWithPhone(phone, name, email);

    res.status(201).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Request OTP for washer login
 * @route   POST /api/v1/washer/auth/request-otp
 * @access  Public
 */
export const requestOTP = async (req, res, next) => {
  try {
    const { phone } = req.body;

    if (!phone) {
      return res.status(400).json({
        success: false,
        message: 'Phone number is required'
      });
    }

    const result = await washerAuthService.requestOTP(phone);

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Verify OTP and login washer
 * @route   POST /api/v1/washer/auth/verify-otp
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

    const result = await washerAuthService.verifyOTPAndLogin(phone, otp);

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
 * @route   POST /api/v1/washer/auth/resend-otp
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

    const result = await washerAuthService.resendOTP(phone);

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
 * @route   POST /api/v1/washer/auth/refresh
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

    const result = await washerAuthService.refreshAccessToken(refreshToken);

    res.status(200).json({
      success: true,
      data: {
        token: result.token,
        refreshToken: result.refreshToken,
        user: result.user,
        washer: result.washer
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Check washer status by email (public - no auth required)
 * @route   POST /api/v1/washer/auth/check-status
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
    
    const statusData = await washerAuthService.checkStatusByEmail(email);
    
    res.status(200).json({
      success: true,
      data: statusData
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get current washer profile
 * @route   GET /api/v1/washer/auth/me
 * @access  Private
 */
export const getMe = async (req, res, next) => {
  try {
    const { user, washer } = await washerAuthService.getWasherById(req.washer.id);

    res.status(200).json({
      success: true,
      data: {
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
          phone: washer.phone,
          email: washer.email,
          status: washer.status,
          online_status: washer.online_status,
          rating: washer.rating,
          total_jobs: washer.total_jobs,
          completed_jobs: washer.completed_jobs,
          wallet_balance: washer.wallet_balance,
          total_earnings: washer.total_earnings
        }
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Logout washer
 * @route   POST /api/v1/washer/auth/logout
 * @access  Private
 */
export const logout = async (req, res, next) => {
  try {
    // In a stateless JWT system, logout is handled client-side by removing the token
    // If you need server-side logout, implement token blacklisting here
    
    res.status(200).json({
      success: true,
      message: 'Logged out successfully'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Login washer with email and password
 * @route   POST /api/v1/washer/auth/login-email
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

    const result = await washerAuthService.loginWithEmail(email, password);

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Register washer with email and password
 * @route   POST /api/v1/washer/auth/register-email
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

    const result = await washerAuthService.registerWithEmail(email, password, name, phone);

    res.status(201).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Request email OTP for login/verification
 * @route   POST /api/v1/washer/auth/request-email-otp
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

    const result = await washerAuthService.requestEmailOTP(email);

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Verify email OTP and login washer
 * @route   POST /api/v1/washer/auth/verify-email-otp
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

    const result = await washerAuthService.verifyEmailOTP(email, otp);

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
 * @route   POST /api/v1/washer/auth/request-password-reset
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

    const result = await washerAuthService.requestPasswordReset(email);

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
 * @route   POST /api/v1/washer/auth/reset-password
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

    const result = await washerAuthService.resetPassword(email, otp, newPassword);

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};


import * as authService from '../services/auth.service.js';

/**
 * @desc    Login admin
 * @route   POST /api/v1/admin/auth/login
 * @access  Public
 */
export const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email and password'
      });
    }

    const result = await authService.loginAdmin(email, password);

    res.status(200).json({
      success: true,
      data: {
        token: result.token,
        admin: result.admin
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Refresh access token
 * @route   POST /api/v1/admin/auth/refresh
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

    const result = await authService.refreshAccessToken(refreshToken);

    res.status(200).json({
      success: true,
      data: {
        token: result.token,
        admin: result.admin
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Logout admin
 * @route   POST /api/v1/admin/auth/logout
 * @access  Private (Admin)
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
 * @desc    Get current admin profile
 * @route   GET /api/v1/admin/auth/me
 * @access  Private (Admin)
 */
export const getMe = async (req, res, next) => {
  try {
    const admin = req.admin;

    res.status(200).json({
      success: true,
      data: {
        admin: {
          id: admin._id,
          email: admin.email,
          role: admin.role,
          name: admin.name,
          branch_id: admin.branch_id,
          is_active: admin.is_active,
          created_at: admin.created_at
        }
      }
    });
  } catch (error) {
    next(error);
  }
};









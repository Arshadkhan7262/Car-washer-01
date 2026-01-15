import * as authGoogleService from '../services/authGoogle.service.js';

/**
 * @desc    Login/Register customer with Google OAuth
 * @route   POST /api/v1/auth/google/customer
 * @access  Public
 */
export const googleLoginCustomer = async (req, res, next) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({
        success: false,
        message: 'Google ID token is required'
      });
    }

    const result = await authGoogleService.loginWithGoogle(idToken);

    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};



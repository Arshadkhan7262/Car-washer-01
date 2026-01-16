import * as googleAuthFirebaseService from '../services/googleAuthFirebase.service.js';

/**
 * @desc    Login/Register customer with Google OAuth (Firebase ID Token)
 * @route   POST /api/v1/auth/google/customer
 * @access  Public
 * 
 * Flutter app signs in via Firebase Google Auth and sends Firebase ID Token.
 * Backend verifies token using Firebase Admin SDK.
 * Registration flow matches email registration (OTP sent, same database structure).
 */
export const googleLoginCustomer = async (req, res, next) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({
        success: false,
        message: 'Firebase ID token is required'
      });
    }

    // Use Firebase-based authentication only
    const result = await googleAuthFirebaseService.googleLoginWithFirebase(idToken, 'customer');

    res.status(200).json({
      success: true,
      message: 'Authentication successful',
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Login/Register washer with Google OAuth (Firebase ID Token)
 * @route   POST /api/v1/auth/google/washer
 * @access  Public
 * 
 * Flutter app signs in via Firebase Google Auth and sends Firebase ID Token.
 * Backend verifies token using Firebase Admin SDK.
 * Registration flow matches email registration (OTP sent, Washer profile created with pending status).
 */
export const googleLoginWasher = async (req, res, next) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({
        success: false,
        message: 'Firebase ID token is required'
      });
    }

    // Use Firebase-based authentication only
    const result = await googleAuthFirebaseService.googleLoginWithFirebase(idToken, 'washer');

    res.status(200).json({
      success: true,
      message: 'Authentication successful',
      data: result
    });
  } catch (error) {
    next(error);
  }
};




import * as authGoogleService from '../services/authGoogle.service.js';
import * as googleAuthFirebaseService from '../services/googleAuthFirebase.service.js';

/**
 * @desc    Login/Register customer with Google OAuth (Firebase ID Token with fallback)
 * @route   POST /api/v1/auth/google/customer
 * @access  Public
 * 
 * When Google Identity Services (GIS) is enabled, Flutter app sends Firebase ID Token.
 * Backend verifies token using Firebase Admin SDK.
 * If Firebase verification fails (GIS not enabled), falls back to Google OAuth token verification.
 */
export const googleLoginCustomer = async (req, res, next) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({
        success: false,
        message: 'ID token is required'
      });
    }

    let result;

    // Try Firebase-based authentication first (GIS enabled)
    try {
      result = await googleAuthFirebaseService.googleLoginWithFirebase(idToken, 'customer');
    } catch (firebaseError) {
      // If Firebase verification fails (GIS not enabled), fall back to Google OAuth
      console.log('⚠️ Firebase verification failed, falling back to Google OAuth:', firebaseError.message);
      
      try {
        // Use the token as Google OAuth token (fallback when GIS is not enabled)
        result = await authGoogleService.loginWithGoogle(idToken, 'customer');
      } catch (googleError) {
        // Both methods failed
        console.error('❌ Both Firebase and Google OAuth verification failed');
        throw firebaseError; // Throw original Firebase error
      }
    }

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
 * @desc    Login/Register washer with Google OAuth (Firebase ID Token with fallback)
 * @route   POST /api/v1/auth/google/washer
 * @access  Public
 * 
 * When Google Identity Services (GIS) is enabled, Flutter app sends Firebase ID Token.
 * Backend verifies token using Firebase Admin SDK.
 * If Firebase verification fails (GIS not enabled), falls back to Google OAuth token verification.
 */
export const googleLoginWasher = async (req, res, next) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({
        success: false,
        message: 'ID token is required'
      });
    }

    let result;

    // Try Firebase-based authentication first (GIS enabled)
    try {
      result = await googleAuthFirebaseService.googleLoginWithFirebase(idToken, 'washer');
    } catch (firebaseError) {
      // If Firebase verification fails (GIS not enabled), fall back to Google OAuth
      console.log('⚠️ Firebase verification failed, falling back to Google OAuth:', firebaseError.message);
      
      try {
        // Use the token as Google OAuth token (fallback when GIS is not enabled)
        result = await authGoogleService.loginWithGoogle(idToken, 'washer');
      } catch (googleError) {
        // Both methods failed
        console.error('❌ Both Firebase and Google OAuth verification failed');
        throw firebaseError; // Throw original Firebase error
      }
    }

    res.status(200).json({
      success: true,
      message: 'Authentication successful',
      data: result
    });
  } catch (error) {
    next(error);
  }
};




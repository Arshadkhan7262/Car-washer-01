import express from 'express';
import * as authGoogleController from '../controllers/authGoogle.controller.js';

const router = express.Router();

/**
 * Google OAuth Authentication Routes (Firebase-based)
 * 
 * When Google Identity Services (GIS) is enabled:
 * - Flutter app signs in via Firebase Google Auth
 * - Sends Firebase ID Token to backend
 * - Backend verifies token using Firebase Admin SDK
 * 
 * Endpoints:
 * POST /auth/google/customer - Customer Google login
 * POST /auth/google/washer - Washer Google login
 * 
 * Request body: { "idToken": "firebase_id_token_from_flutter" }
 * Response: { 
 *   "success": true,
 *   "message": "Authentication successful",
 *   "data": {
 *     "user": { "id", "name", "email", "phone", "role", "profileImage", "authProvider", ... },
 *     "token": "jwt_access_token",
 *     "refreshToken": "jwt_refresh_token"
 *   }
 * }
 */
router.post('/google/customer', authGoogleController.googleLoginCustomer);
router.post('/google/washer', authGoogleController.googleLoginWasher);

export default router;




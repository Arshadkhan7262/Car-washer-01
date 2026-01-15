import express from 'express';
import * as authGoogleController from '../controllers/authGoogle.controller.js';

const router = express.Router();

/**
 * Google OAuth Authentication Route for Customer App
 * 
 * Endpoint: POST /auth/google/customer
 * Request body: { "idToken": "google_id_token_from_flutter" }
 * Response: { "token": "jwt_token", "user": { "id", "name", "email", "role": "customer" } }
 */
router.post('/google/customer', authGoogleController.googleLoginCustomer);

export default router;



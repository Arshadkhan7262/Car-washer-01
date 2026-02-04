/**
 * Firebase Admin SDK Configuration
 * 
 * This module initializes Firebase Admin SDK for server-side authentication.
 * Firebase handles OTP generation and verification on the client side.
 * Backend only verifies the Firebase ID token and manages user records.
 */

import admin from 'firebase-admin';
import dotenv from 'dotenv';

dotenv.config();

// Initialize Firebase Admin SDK
// Option 1: Using service account JSON (recommended for production)
// Option 2: Using environment variables (for development)
let firebaseApp;

try {
  if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
    // Parse service account from environment variable (JSON string)
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
    
    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: serviceAccount.project_id
    });
  } else if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_CLIENT_EMAIL && process.env.FIREBASE_PRIVATE_KEY) {
    // Initialize using individual environment variables
    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n')
      })
    });
  } else {
    // Try to use default credentials (for Google Cloud environments)
    firebaseApp = admin.initializeApp({
      credential: admin.credential.applicationDefault()
    });
  }

  console.log('✅ Firebase Admin SDK initialized successfully');
  
  // Get project ID from various sources
  const projectId = firebaseApp.options.projectId || 
                   (process.env.FIREBASE_SERVICE_ACCOUNT_KEY ? JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY).project_id : null) ||
                   process.env.FIREBASE_PROJECT_ID ||
                   'Not set';
  
  console.log(`📱 [Firebase] Project ID: ${projectId}`);
  console.log(`📱 [Firebase] Service Account: ${process.env.FIREBASE_SERVICE_ACCOUNT_KEY ? 'Using JSON' : process.env.FIREBASE_CLIENT_EMAIL ? 'Using env vars' : 'Using default credentials'}`);
  
  // Verify messaging is available
  try {
    const messaging = admin.messaging();
    console.log('✅ Firebase Cloud Messaging API is available');
  } catch (messagingError) {
    console.error('❌ Firebase Cloud Messaging API not available:', messagingError.message);
  }
} catch (error) {
  console.error('❌ Firebase Admin SDK initialization error:', error.message);
  console.error('Stack:', error.stack);
  console.error('Please configure Firebase credentials in .env file');
  console.error('Required: FIREBASE_SERVICE_ACCOUNT_KEY (JSON string) OR');
  console.error('         FIREBASE_PROJECT_ID + FIREBASE_CLIENT_EMAIL + FIREBASE_PRIVATE_KEY');
  throw error;
}

/**
 * Verify Firebase ID Token
 * @param {string} idToken - Firebase ID token from client
 * @returns {Promise<Object>} Decoded token with user info
 */
export const verifyFirebaseToken = async (idToken) => {
  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    
    // Ensure phone number is verified
    if (!decodedToken.phone_number) {
      throw new Error('Phone number not verified in Firebase token');
    }

    return {
      uid: decodedToken.uid,
      phone: decodedToken.phone_number,
      phoneVerified: decodedToken.phone_number ? true : false,
      email: decodedToken.email || null,
      emailVerified: decodedToken.email_verified || false,
      name: decodedToken.name || null
    };
  } catch (error) {
    if (error.code === 'auth/id-token-expired') {
      throw new Error('Firebase ID token has expired');
    } else if (error.code === 'auth/id-token-revoked') {
      throw new Error('Firebase ID token has been revoked');
    } else if (error.code === 'auth/argument-error') {
      throw new Error('Invalid Firebase ID token');
    }
    throw new Error(`Firebase token verification failed: ${error.message}`);
  }
};

/**
 * Verify Firebase ID Token for Google Sign-In (supports both phone and email providers)
 * @param {string} idToken - Firebase ID token from client
 * @returns {Promise<Object>} Decoded token with user info
 */
export const verifyFirebaseTokenForGoogle = async (idToken) => {
  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    
    // Extract provider information
    const providerData = decodedToken.firebase?.identities || {};
    const providers = Object.keys(providerData);
    const isGoogleProvider = providers.includes('google.com');
    
    // For Google Sign-In, email is required
    if (!decodedToken.email) {
      throw new Error('Email not provided in Firebase token');
    }

    return {
      uid: decodedToken.uid,
      email: decodedToken.email,
      emailVerified: decodedToken.email_verified || false,
      name: decodedToken.name || null,
      photoURL: decodedToken.picture || decodedToken.photoURL || null,
      phone: decodedToken.phone_number || null,
      phoneVerified: decodedToken.phone_number ? true : false,
      provider: isGoogleProvider ? 'google' : decodedToken.firebase?.sign_in_provider || 'unknown'
    };
  } catch (error) {
    if (error.code === 'auth/id-token-expired') {
      throw new Error('Firebase ID token has expired');
    } else if (error.code === 'auth/id-token-revoked') {
      throw new Error('Firebase ID token has been revoked');
    } else if (error.code === 'auth/argument-error') {
      throw new Error('Invalid Firebase ID token');
    }
    throw new Error(`Firebase token verification failed: ${error.message}`);
  }
};

export default firebaseApp;


import Stripe from 'stripe';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

// Always load backend/.env from this file's location (backend/src/config -> backend/.env)
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const envPath = path.join(__dirname, '..', '..', '.env');
dotenv.config({ path: envPath, override: true });

// Initialize Stripe with secret key
let stripeInstance = null;
/** First 12 chars of Stripe account id (from secret key), set when instance is created */
let stripeAccountIdPrefix = null;

function getSecretKey() {
  const fromEnv = (process.env.STRIPE_SECRET_KEY || '').trim();
  if (fromEnv) return fromEnv;
  throw new Error('STRIPE_SECRET_KEY is not defined. Check backend/.env (path: ' + envPath + ')');
}

/** Returns first 12 chars of account id (e.g. 51RLB5nPdbAW) for debugging key mismatch */
export function getStripeAccountIdPrefix() {
  if (stripeAccountIdPrefix) return stripeAccountIdPrefix;
  const secretKey = (process.env.STRIPE_SECRET_KEY || '').trim();
  const match = secretKey.match(/sk_(?:test|live)_(\w+)/);
  return match ? match[1].substring(0, 12) : null;
}

export const getStripeInstance = () => {
  if (!stripeInstance) {
    const secretKey = getSecretKey();
    
    stripeInstance = new Stripe(secretKey, {
      apiVersion: '2024-12-18.acacia', // Use latest API version
    });
    
    const match = secretKey.match(/sk_(?:test|live)_(\w+)/);
    stripeAccountIdPrefix = match ? match[1].substring(0, 12) : null;
    const keyPrefix = secretKey.length >= 24 ? secretKey.substring(0, 24) + '...' : '***';
    console.log('✅ Stripe initialized (backend/.env)');
    console.log('   Secret key: ' + keyPrefix);
    console.log('   Account: ' + stripeAccountIdPrefix + '... → app must use pk_test_' + stripeAccountIdPrefix + '...');
  }
  
  return stripeInstance;
};

export default getStripeInstance;


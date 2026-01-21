import Stripe from 'stripe';
import dotenv from 'dotenv';

dotenv.config();

// Initialize Stripe with secret key
let stripeInstance = null;

export const getStripeInstance = () => {
  if (!stripeInstance) {
    const secretKey = process.env.STRIPE_SECRET_KEY;
    
    if (!secretKey) {
      throw new Error('STRIPE_SECRET_KEY is not defined in environment variables');
    }
    
    stripeInstance = new Stripe(secretKey, {
      apiVersion: '2024-12-18.acacia', // Use latest API version
    });
    
    console.log('✅ Stripe initialized successfully');
  }
  
  return stripeInstance;
};

export default getStripeInstance;


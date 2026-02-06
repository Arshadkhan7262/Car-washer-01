import Stripe from 'stripe';

let stripeInstance = null;

/**
 * Get Stripe instance (singleton)
 */
const getStripeInstance = () => {
  if (!stripeInstance) {
    const stripeSecretKey = process.env.STRIPE_SECRET_KEY;
    
    if (!stripeSecretKey) {
      console.warn('⚠️ Stripe secret key not found in environment variables');
      return null;
    }

    stripeInstance = new Stripe(stripeSecretKey, {
      apiVersion: '2024-11-20.acacia',
    });

    console.log('✅ Stripe initialized');
  }

  return stripeInstance;
};

export default getStripeInstance;

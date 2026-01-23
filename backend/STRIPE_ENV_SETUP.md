# Stripe Environment Variables Setup

## Required Environment Variables

Add the following variables to your `.env` file in the `backend` directory:

```env
# Stripe Configuration
STRIPE_SECRET_KEY=sk_test_51RLB5nPdbAWpbZ8zaxaskODi8aLOduup3HImwvuRzcWA3OhtDSzg6Xj10FGOp9f61HHz71Fi7STVtKKwW1DVS7mE00E0tOwOMG
STRIPE_PUBLISHABLE_KEY=pk_test_51RLB5nPdbAWpbZ8zjW263HT7LnFIcz813twUFCpk5T6PR2MqGuoWdR8wmeWuHc19Gmb7zxWXWLL3pKEdqVMCHyVQ00XH7POBCZ

# Stripe Webhook Secret (Optional - for production)
# Get this from Stripe Dashboard > Developers > Webhooks > Your endpoint > Signing secret
STRIPE_WEBHOOK_SECRET=whsec_xxx

# MongoDB Connection
MONGO_URI=mongodb://localhost:27017/carwash-pro

# JWT Configuration (if not already set)
JWT_SECRET=your_jwt_secret_key
JWT_EXPIRE=24h
JWT_REFRESH_SECRET=your_jwt_refresh_secret_key
JWT_REFRESH_EXPIRE=7d
```

## Important Notes

1. **TEST MODE ONLY**: The provided keys are Stripe TEST keys. Never use these in production.

2. **Secret Key Security**: 
   - The `STRIPE_SECRET_KEY` must NEVER be exposed to the Flutter app
   - Only the `STRIPE_PUBLISHABLE_KEY` should be sent to the Flutter app
   - Store secret keys securely in environment variables

3. **Webhook Secret**:
   - Required for production to verify webhook signatures
   - Optional for development/testing
   - Get from Stripe Dashboard after setting up webhook endpoint

4. **Production Setup**:
   - Replace test keys with live keys from Stripe Dashboard
   - Set up webhook endpoint in Stripe Dashboard
   - Configure `STRIPE_WEBHOOK_SECRET` from webhook settings

## Stripe Dashboard Setup

1. Go to [Stripe Dashboard](https://dashboard.stripe.com/)
2. Navigate to **Developers > API keys**
3. Copy your **Publishable key** and **Secret key**
4. For webhooks:
   - Go to **Developers > Webhooks**
   - Click **Add endpoint**
   - Enter your webhook URL: `https://yourdomain.com/api/v1/stripe/webhook`
   - Select events: `payment_intent.succeeded`, `payment_intent.payment_failed`, `payment_intent.canceled`
   - Copy the **Signing secret** to `STRIPE_WEBHOOK_SECRET`

## Testing

Use Stripe test cards for testing:
- **Success**: `4242 4242 4242 4242`
- **3D Secure**: `4000 0025 0000 3155`
- **Declined**: `4000 0000 0000 0002`

See [Stripe Test Cards](https://stripe.com/docs/testing#cards) for more options.

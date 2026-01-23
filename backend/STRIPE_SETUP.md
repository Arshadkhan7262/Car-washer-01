# Stripe Payment Integration Setup

This guide explains how to set up Stripe payment processing in the backend.

## Prerequisites

1. Stripe account with API keys
2. Node.js backend server running

## Setup Steps

### 1. Install Stripe Package

The Stripe package has been installed:
```bash
npm install stripe
```

### 2. Configure Environment Variables

Create a `.env` file in the `backend/` directory (if it doesn't exist) and add your Stripe secret key:

```env
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key_here
```

**Important:** 
- Never commit the `.env` file to version control
- Use test keys for development (`sk_test_...`)
- Use live keys for production (`sk_live_...`)

### 3. Backend API Endpoints

The following endpoints are available:

#### Create Payment Intent
```
POST /api/v1/customer/payment/create-intent
Authorization: Bearer <token>
Content-Type: application/json

Body:
{
  "amount": 2000,  // Amount in cents (e.g., $20.00 = 2000 cents)
  "currency": "usd",
  "customerId": "optional_customer_id",
  "metadata": {
    "booking_id": "optional_booking_id"
  }
}

Response:
{
  "success": true,
  "message": "Payment intent created successfully",
  "data": {
    "client_secret": "pi_xxx_secret_xxx",
    "payment_intent_id": "pi_xxx",
    "amount": 20.00,
    "currency": "usd",
    "status": "requires_payment_method"
  }
}
```

#### Confirm Payment
```
POST /api/v1/customer/payment/confirm
Authorization: Bearer <token>
Content-Type: application/json

Body:
{
  "paymentIntentId": "pi_xxx"
}

Response:
{
  "success": true,
  "message": "Payment confirmed successfully",
  "data": {
    "id": "pi_xxx",
    "status": "succeeded",
    "amount": 20.00,
    "currency": "usd"
  }
}
```

#### Get Payment Intent
```
GET /api/v1/customer/payment/intent/:id
Authorization: Bearer <token>

Response:
{
  "success": true,
  "message": "Payment intent retrieved successfully",
  "data": {
    "id": "pi_xxx",
    "status": "succeeded",
    "amount": 20.00,
    "currency": "usd",
    "client_secret": "pi_xxx_secret_xxx",
    "metadata": {}
  }
}
```

### 4. File Structure

The Stripe integration consists of:

- `backend/src/config/stripe.config.js` - Stripe initialization
- `backend/src/services/payment.service.ts` - Payment business logic
- `backend/src/controllers/payment.controller.ts` - API controllers
- `backend/src/routes/payment.routes.ts` - Route definitions

### 5. Testing

#### Test Card Numbers (Stripe Test Mode)

Use these test card numbers for testing:

- **Success:** `4242 4242 4242 4242`
- **Decline:** `4000 0000 0000 0002`
- **3D Secure:** `4000 0025 0000 3155`

Use any:
- Future expiry date (e.g., 12/25)
- Any 3-digit CVC
- Any ZIP code

#### Test Payment Flow

1. Start the backend server:
   ```bash
   npm start
   ```

2. From Flutter app, create a payment intent:
   - Navigate to booking screen
   - Select credit card payment
   - Enter test card details
   - Complete payment

3. Check Stripe Dashboard:
   - Go to https://dashboard.stripe.com/test/payments
   - Verify payment appears in test mode

### 6. Error Handling

Common errors and solutions:

- **"STRIPE_SECRET_KEY is not defined"**: Add the key to `.env` file
- **"Invalid API Key"**: Check that you're using the correct test/live key
- **"Amount must be greater than 0"**: Ensure amount is sent in cents (e.g., $20 = 2000)

### 7. Production Setup

Before going to production:

1. Replace test keys with live keys:
   ```env
   STRIPE_SECRET_KEY=sk_live_...
   ```

2. Update Flutter app with live publishable key:
   ```dart
   static const String stripePublishableKey = 'pk_live_...';
   ```

3. Test thoroughly with small amounts first

4. Set up webhooks for payment status updates (optional)

## Notes

- All payment endpoints require authentication (Bearer token)
- Amount should be sent in cents from Flutter app (already handled)
- Payment intents are created server-side for security
- Client secret is returned to Flutter app for payment confirmation


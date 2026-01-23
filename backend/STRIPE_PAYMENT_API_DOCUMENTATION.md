# Stripe Payment API Documentation

## Overview
This document describes the Stripe payment integration APIs for the Car Wash Pro platform. All payment operations are handled securely on the backend, with the Flutter app only receiving the publishable key and payment client secrets.

## Base URL
```
http://localhost:3000/api/v1/stripe
```

## Authentication
Most endpoints require authentication via JWT token in the Authorization header:
```
Authorization: Bearer <token>
```

## Environment Variables
The following environment variables must be set in `.env`:
```env
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_PUBLISHABLE_KEY=pk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx (optional, for webhook signature verification)
MONGO_URI=mongodb://...
```

---

## 1. Get Stripe Publishable Key

### Endpoint
`GET /api/v1/stripe/publishable-key`

### Purpose
Returns the Stripe publishable key for the Flutter app. This should be called once on app launch and cached locally.

### Access
**Public** (No authentication required)

### Request
No request body or parameters required.

### Response
**Status Code:** `200 OK`

```json
{
  "success": true,
  "data": {
    "publishableKey": "pk_test_51RLB5nPdbAWpbZ8zjW263HT7LnFIcz813twUFCpk5T6PR2MqGuoWdR8wmeWuHc19Gmb7zxWXWLL3pKEdqVMCHyVQ00XH7POBCZ"
  }
}
```

### Error Responses
- `500 Internal Server Error` - Stripe publishable key not configured

### Notes for Flutter Developer
- Call this endpoint once on app launch
- Store the publishable key in local storage/cache
- Use this key to initialize Stripe in the Flutter app
- Never expose the secret key to the Flutter app

---

## 2. Create Stripe Customer

### Endpoint
`POST /api/v1/stripe/customer`

### Purpose
Creates a Stripe customer and saves the customer ID to the user's MongoDB record. This should be called before creating a payment intent.

### Access
**Private** (Customer authentication required)

### Request Headers
```
Authorization: Bearer <customer_token>
Content-Type: application/json
```

### Request Body
```json
{
  "userId": "mongodb_user_id",  // Optional if authenticated
  "email": "customer@email.com",
  "name": "Customer Name",
  "role": "customer"  // Optional, defaults to "customer"
}
```

**Note:** If `userId` is not provided, the authenticated user's ID will be used. If `email` or `name` are not provided, they will be fetched from the user record.

### Response
**Status Code:** `201 Created`

```json
{
  "success": true,
  "data": {
    "stripeCustomerId": "cus_xxxxx",
    "message": "Stripe customer created successfully"
  }
}
```

If customer already exists:
```json
{
  "success": true,
  "data": {
    "stripeCustomerId": "cus_xxxxx",
    "message": "Customer already exists in Stripe"
  }
}
```

### Error Responses
- `400 Bad Request` - Missing required fields (userId, email, name)
- `401 Unauthorized` - Invalid or missing authentication token
- `404 Not Found` - User not found
- `500 Internal Server Error` - Failed to create Stripe customer

### Notes for Flutter Developer
- Call this endpoint once per user (or check if user already has `stripeCustomerId`)
- Store the `stripeCustomerId` in the user's profile
- This is a one-time setup per user

---

## 3. Create Payment Intent

### Endpoint
`POST /api/v1/stripe/create-payment-intent`

### Purpose
Creates a Stripe PaymentIntent for a booking. Returns a client secret that the Flutter app uses to confirm the payment.

### Access
**Private** (Customer authentication required)

### Request Headers
```
Authorization: Bearer <customer_token>
Content-Type: application/json
```

### Request Body
```json
{
  "stripeCustomerId": "cus_xxxxx",  // Required
  "amount": 3000,  // Required: Amount in cents (e.g., 3000 = $30.00)
  "currency": "usd",  // Optional, defaults to "usd"
  "bookingId": "BOOKING_123",  // Required: MongoDB booking ID
  "washerId": "washer_mongo_id",  // Optional: Washer MongoDB ID
  "adminId": "admin_mongo_id"  // Optional: Admin MongoDB ID
}
```

**Important:** 
- `amount` must be a positive integer in the smallest currency unit (cents for USD)
- `stripeCustomerId` can be omitted if the authenticated user has a `stripeCustomerId` in their profile

### Response
**Status Code:** `201 Created`

```json
{
  "success": true,
  "data": {
    "clientSecret": "pi_xxx_secret_xxx",
    "paymentIntentId": "pi_xxxxx",
    "paymentId": "mongodb_payment_id"
  }
}
```

### Error Responses
- `400 Bad Request` - Missing required fields or invalid amount
- `401 Unauthorized` - Invalid or missing authentication token
- `404 Not Found` - Booking not found or Stripe customer ID not found
- `500 Internal Server Error` - Failed to create payment intent

### Notes for Flutter Developer
- Use the `clientSecret` to confirm the payment using Stripe SDK
- The payment record is created in MongoDB with status `pending`
- After successful payment confirmation, the status will be updated to `succeeded` via webhook
- Amount validation is done on the backend - never trust client-side amount

---

## 4. Get Customer Payment History

### Endpoint
`GET /api/v1/stripe/payment-history/:stripeCustomerId`

### Purpose
Returns all payment history for a Stripe customer.

### Access
**Private** (Customer authentication required)

### Request Headers
```
Authorization: Bearer <customer_token>
```

### URL Parameters
- `stripeCustomerId` (required) - Stripe customer ID

**Note:** If `stripeCustomerId` is not provided in URL, the authenticated user's Stripe customer ID will be used.

### Query Parameters
- `page` (optional) - Page number (default: 1)
- `limit` (optional) - Items per page (default: 20)
- `sort` (optional) - Sort field and order (default: "-created_date")

### Response
**Status Code:** `200 OK`

```json
{
  "success": true,
  "data": {
    "payments": [
      {
        "paymentId": "pi_xxx",
        "amount": 3000,
        "currency": "usd",
        "status": "succeeded",
        "bookingId": "BOOKING_123",
        "createdAt": "2025-01-15T10:30:00Z",
        "paidAt": "2025-01-15T10:31:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 50,
      "totalPages": 3
    }
  }
}
```

### Error Responses
- `400 Bad Request` - Stripe customer ID is required
- `401 Unauthorized` - Invalid or missing authentication token
- `404 Not Found` - Stripe customer ID not found
- `500 Internal Server Error` - Failed to fetch payment history

---

## 5. Get Washer Earnings History

### Endpoint
`GET /api/v1/stripe/washer/earnings/:washerId`

### Purpose
Returns all earnings history for a washer (only succeeded payments).

### Access
**Private** (Washer authentication required)

### Request Headers
```
Authorization: Bearer <washer_token>
```

### URL Parameters
- `washerId` (required) - Washer MongoDB ID

**Note:** If `washerId` is not provided, the authenticated washer's ID will be used.

### Query Parameters
- `page` (optional) - Page number (default: 1)
- `limit` (optional) - Items per page (default: 20)
- `sort` (optional) - Sort field and order (default: "-created_date")

### Response
**Status Code:** `200 OK`

```json
{
  "success": true,
  "data": {
    "earnings": [
      {
        "paymentId": "pi_xxx",
        "amount": 3000,
        "currency": "usd",
        "customerName": "John Doe",
        "bookingId": "BOOKING_123",
        "createdAt": "2025-01-15T10:30:00Z",
        "paidAt": "2025-01-15T10:31:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 50,
      "totalPages": 3
    }
  }
}
```

### Error Responses
- `400 Bad Request` - Washer ID is required
- `401 Unauthorized` - Invalid or missing authentication token
- `500 Internal Server Error` - Failed to fetch earnings

---

## 6. Get All Payments (Admin)

### Endpoint
`GET /api/v1/stripe/admin/payments`

### Purpose
Returns all payments with optional filters. Used by admin dashboard.

### Access
**Private** (Admin authentication required)

### Request Headers
```
Authorization: Bearer <admin_token>
```

### Query Parameters
- `status` (optional) - Filter by payment status (`pending`, `succeeded`, `failed`, `canceled`, `refunded`)
- `paymentMethod` (optional) - Filter by payment method (`card`, `wallet`, `cash`, etc.)
- `customerId` (optional) - Filter by customer MongoDB ID
- `washerId` (optional) - Filter by washer MongoDB ID
- `dateFrom` (optional) - Filter from date (ISO 8601 format)
- `dateTo` (optional) - Filter to date (ISO 8601 format)
- `page` (optional) - Page number (default: 1)
- `limit` (optional) - Items per page (default: 50)
- `sort` (optional) - Sort field and order (default: "-created_date")

### Response
**Status Code:** `200 OK`

```json
{
  "success": true,
  "data": {
    "payments": [
      {
        "_id": "...",
        "stripePaymentIntentId": "pi_xxx",
        "stripeCustomerId": "cus_xxx",
        "booking_id": {...},
        "customer_id": {...},
        "washer_id": {...},
        "amount": 3000,
        "currency": "usd",
        "status": "succeeded",
        "created_date": "2025-01-15T10:30:00Z",
        "paid_at": "2025-01-15T10:31:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 50,
      "total": 100,
      "totalPages": 2
    }
  }
}
```

### Error Responses
- `401 Unauthorized` - Invalid or missing authentication token
- `403 Forbidden` - Admin access required
- `500 Internal Server Error` - Failed to fetch payments

---

## 7. Stripe Webhook

### Endpoint
`POST /api/v1/stripe/webhook`

### Purpose
Handles Stripe webhook events for payment status updates. This endpoint processes:
- `payment_intent.succeeded` - Updates payment status and booking payment status
- `payment_intent.payment_failed` - Updates payment status to failed
- `payment_intent.canceled` - Updates payment status to canceled

### Access
**Public** (Stripe signature verification)

### Request Headers
```
Stripe-Signature: <stripe_signature>
Content-Type: application/json
```

### Request Body
Raw JSON body from Stripe (automatically parsed)

### Response
**Status Code:** `200 OK`

```json
{
  "received": true
}
```

### Error Responses
- `400 Bad Request` - Invalid webhook signature or payload

### Notes
- This endpoint uses `express.raw()` middleware for body parsing
- Webhook secret should be configured in `.env` as `STRIPE_WEBHOOK_SECRET`
- In development, webhook signature verification can be disabled

### Webhook Events Handled
1. **payment_intent.succeeded**
   - Updates payment status to `succeeded`
   - Updates booking `payment_status` to `paid`
   - Sets `paid_at` timestamp

2. **payment_intent.payment_failed**
   - Updates payment status to `failed`
   - Stores error message

3. **payment_intent.canceled**
   - Updates payment status to `canceled`

---

## Payment Flow

### Complete Payment Flow

1. **App Launch**
   - Flutter app calls `GET /api/v1/stripe/publishable-key`
   - Stores publishable key in local cache

2. **User Registration/Login**
   - User creates account or logs in
   - If user doesn't have `stripeCustomerId`, call `POST /api/v1/stripe/customer`
   - Store `stripeCustomerId` in user profile

3. **Create Booking**
   - User creates a booking
   - Booking is saved with `payment_status: "unpaid"`

4. **Initiate Payment**
   - User clicks "Pay Now"
   - Flutter app calls `POST /api/v1/stripe/create-payment-intent`
   - Receives `clientSecret`

5. **Confirm Payment**
   - Flutter app uses Stripe SDK to confirm payment with `clientSecret`
   - Stripe processes the payment

6. **Payment Success**
   - Stripe sends webhook to `POST /api/v1/stripe/webhook`
   - Backend updates:
     - Payment status → `succeeded`
     - Booking `payment_status` → `paid`
   - When job is completed, washer wallet is updated

---

## Payment Status Flow

### Payment Statuses
- `pending` - Payment intent created, awaiting confirmation
- `processing` - Payment is being processed
- `succeeded` - Payment completed successfully
- `failed` - Payment failed
- `canceled` - Payment was canceled
- `refunded` - Payment was refunded
- `partially_refunded` - Partial refund issued

### Booking Payment Status
- `unpaid` - Booking created, payment not initiated
- `paid` - Payment completed successfully
- `refunded` - Payment was refunded

---

## Stripe Test Cards

Use these test card numbers for testing:

### Successful Payment
```
Card Number: 4242 4242 4242 4242
Expiry: Any future date (e.g., 12/25)
CVC: Any 3 digits (e.g., 123)
ZIP: Any 5 digits (e.g., 12345)
```

### Payment Requires Authentication (3D Secure)
```
Card Number: 4000 0025 0000 3155
Expiry: Any future date
CVC: Any 3 digits
ZIP: Any 5 digits
```

### Payment Declined
```
Card Number: 4000 0000 0000 0002
Expiry: Any future date
CVC: Any 3 digits
ZIP: Any 5 digits
```

### Insufficient Funds
```
Card Number: 4000 0000 0000 9995
Expiry: Any future date
CVC: Any 3 digits
ZIP: Any 5 digits
```

### More Test Cards
See [Stripe Test Cards](https://stripe.com/docs/testing#cards) for complete list.

---

## Error Handling

All endpoints follow a consistent error response format:

```json
{
  "success": false,
  "message": "Error message here"
}
```

Common HTTP status codes:
- `400` - Bad Request (validation errors, missing fields)
- `401` - Unauthorized (invalid or missing token)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found (resource doesn't exist)
- `500` - Internal Server Error (server-side errors)

---

## Security Best Practices

1. **Never expose secret key** - Secret key is only used on the backend
2. **Validate amount on backend** - Always validate payment amounts server-side
3. **Use webhooks** - Don't trust client-side payment status
4. **Verify webhook signatures** - Always verify Stripe webhook signatures in production
5. **Sanitize inputs** - All inputs are validated and sanitized
6. **Use HTTPS** - Always use HTTPS in production
7. **Token expiration** - JWT tokens should have appropriate expiration times

---

## Integration Checklist for Flutter Developer

- [ ] Call `GET /api/v1/stripe/publishable-key` on app launch
- [ ] Store publishable key in local storage
- [ ] Initialize Stripe SDK with publishable key
- [ ] Create Stripe customer on user registration/login (if not exists)
- [ ] Store `stripeCustomerId` in user profile
- [ ] Call `POST /api/v1/stripe/create-payment-intent` when user initiates payment
- [ ] Use `clientSecret` to confirm payment with Stripe SDK
- [ ] Handle payment success/failure in Flutter app
- [ ] Call `GET /api/v1/stripe/payment-history/:stripeCustomerId` to show payment history
- [ ] Implement proper error handling for all payment operations
- [ ] Test with Stripe test cards before going live

---

## Support

For issues or questions:
1. Check the error message in the response
2. Verify all required fields are provided
3. Ensure authentication token is valid
4. Check Stripe dashboard for payment status
5. Review server logs for detailed error information

---

**Last Updated:** January 2025
**API Version:** 1.0

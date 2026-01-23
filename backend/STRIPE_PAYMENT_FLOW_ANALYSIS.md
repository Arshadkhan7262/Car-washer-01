# Stripe Payment Flow Analysis

## Current Implementation Status

### ❌ **Stripe Integration: NOT IMPLEMENTED**

**Finding:** 
- `stripe` package is listed in `package.json` (version ^14.25.0) but **NO actual Stripe integration code exists**
- Payment TypeScript files (`payment.controller.ts`, `payment.service.ts`, `Payment.model.ts`) are **empty**
- No payment routes are registered in the backend

### Current Payment Flow (Simplified)

#### 1. **Customer Creates Booking** (`POST /api/v1/customer/bookings`)

**File:** `backend/src/controllers/customerBooking.controller.js`

```javascript
// Lines 96-100
let paymentStatus = 'unpaid';
if (payment_method === 'card' || payment_method === 'wallet' || 
    payment_method === 'apple_pay' || payment_method === 'google_pay') {
  paymentStatus = 'paid'; // ⚠️ Just sets status, NO actual payment processing
}
```

**Issues:**
- No Stripe API call
- No payment verification
- Payment status is assumed based on method selection
- No transaction ID or payment receipt

#### 2. **Booking Model** (`backend/src/models/Booking.model.js`)

**Payment Fields:**
- `payment_status`: `['unpaid', 'paid', 'refunded']`
- `payment_method`: `['cash', 'card', 'wallet', 'apple_pay', 'google_pay']`
- `total`: Amount charged

**Note:** All payment info is stored in Booking model, not a separate Payment model.

---

## Transaction History Flow

### ✅ **Washer Transaction History**

**Endpoint:** `GET /api/v1/washer/wallet/transactions`

**File:** `backend/src/services/washerWallet.service.js` (Lines 116-206)

**How it works:**
1. Queries `Booking` model where:
   - `washer_id` = current washer
   - `status` = 'completed'
   - `payment_status` = 'paid'
2. Transforms bookings into transaction format
3. Returns formatted transactions with:
   - `booking_id`
   - `customer_name`
   - `service_name`
   - `amount` (from booking.total)
   - `payment_method`
   - `date` (from booking.created_date)

**✅ Status:** **WORKING** - Washer can see transactions from completed paid bookings

---

### ✅ **Customer Transaction History**

**Endpoint:** `GET /api/v1/customer/bookings`

**File:** `backend/src/services/customer.service.js` (Lines 179-226)

**How it works:**
1. Queries `Booking` model where:
   - `customer_id` = current customer
   - Optional status filter
2. Returns all bookings (including payment info) with:
   - `payment_method`
   - `payment_status`
   - `total`
   - `created_date`

**✅ Status:** **WORKING** - Customer can see their booking history with payment details

**Customer App:** `wash_away/lib/controllers/history_controller.dart`
- Fetches bookings via `BookingService.getCustomerBookings()`
- Displays booking history with payment information

---

### ⚠️ **Admin Panel Transaction History**

**File:** `CarWashProAdminPanel/src/pages/Payments.jsx`

**Current Implementation:**
```javascript
// Line 39-42
const { data: payments = [], isLoading: paymentsLoading } = useQuery({
  queryKey: ['payments'],
  queryFn: () => base44.entities.Payment.list('-created_date', 200),
});
```

**Problem:**
- Admin panel tries to fetch `Payment` entities
- But `base44Client.js` does **NOT** have Payment entity defined
- No backend endpoint exists for `/admin/payments`
- Payment model/controller files are empty

**Expected Behavior:**
- Admin should see all payments from all bookings
- Should be able to filter by payment method, status, customer, etc.
- Should show transaction details

**Current Workaround:**
- Admin can view bookings via `/admin/bookings` which includes payment info
- But no dedicated payment/transaction view

---

## Payment Flow Summary

### When Customer Pays with "Card" (Stripe):

**Current Flow:**
1. ✅ Customer selects payment method: `'card'`
2. ✅ Booking created with `payment_status: 'paid'`
3. ❌ **NO Stripe API call**
4. ❌ **NO payment verification**
5. ❌ **NO transaction ID stored**
6. ✅ Booking saved to database
7. ✅ When job completed → Washer wallet updated
8. ✅ Washer sees transaction in history
9. ✅ Customer sees booking in history
10. ⚠️ Admin panel cannot view payments (Payment entity missing)

---

## Missing Implementation

### 1. **Stripe Payment Processing**

**Required:**
- Stripe payment intent creation
- Payment confirmation
- Webhook handling for payment status
- Transaction ID storage
- Payment receipt generation

### 2. **Payment Model & API**

**Required:**
- Create `Payment` model (separate from Booking)
- Create payment controller/service
- Create payment routes
- Link payments to bookings
- Store Stripe transaction IDs

### 3. **Admin Payment View**

**Required:**
- Add Payment entity to `base44Client.js`
- Create `/admin/payments` endpoint
- Return all payments from all bookings
- Support filtering and search

### 4. **Transaction Creation**

**Current:** Transactions are derived from bookings
**Recommended:** Create separate Payment records when payment is processed

---

## Recommended Implementation Flow

### When Customer Pays with Stripe:

1. **Customer creates booking** → `POST /api/v1/customer/bookings`
2. **If payment_method = 'card':**
   - Create Stripe Payment Intent
   - Return client_secret to frontend
   - Frontend confirms payment with Stripe
3. **After Stripe confirmation:**
   - Create `Payment` record with:
     - `booking_id`
     - `customer_id`
     - `amount`
     - `payment_method: 'card'`
     - `transaction_id` (Stripe payment intent ID)
     - `status: 'completed'`
   - Update booking `payment_status: 'paid'`
4. **When job completed:**
   - Update washer wallet balance
   - Washer transaction appears in history
5. **All parties can view:**
   - **Washer:** `/api/v1/washer/wallet/transactions` ✅
   - **Customer:** `/api/v1/customer/bookings` ✅
   - **Admin:** `/api/v1/admin/payments` ❌ (needs implementation)

---

## Files That Need Implementation

1. **Backend:**
   - `backend/src/models/Payment.model.ts` - Create Payment model
   - `backend/src/controllers/payment.controller.ts` - Payment CRUD
   - `backend/src/services/payment.service.ts` - Stripe integration
   - `backend/src/routes/payment.routes.js` - Payment routes
   - Add to `backend/src/routes/index.routes.js`

2. **Admin Panel:**
   - Add Payment entity to `CarWashProAdminPanel/src/api/base44Client.js`
   - Update `CarWashProAdminPanel/src/pages/Payments.jsx` to use correct endpoint

3. **Customer App:**
   - Already working - uses booking history
   - May need payment confirmation flow if Stripe is added

4. **Washer App:**
   - Already working - uses booking-based transactions

---

## Current Status Summary

| Feature | Customer | Washer | Admin |
|---------|----------|--------|-------|
| View Transactions | ✅ (via bookings) | ✅ (via wallet) | ⚠️ (Payment entity missing) |
| Payment Processing | ❌ (No Stripe) | N/A | N/A |
| Transaction History | ✅ | ✅ | ❌ |
| Payment Details | ✅ (in booking) | ✅ (in booking) | ⚠️ (via bookings only) |

---

## Next Steps

1. **Implement Stripe Payment Processing**
2. **Create Payment Model & API**
3. **Add Payment entity to Admin Panel**
4. **Create payment records when Stripe payment succeeds**
5. **Update transaction history to use Payment model**

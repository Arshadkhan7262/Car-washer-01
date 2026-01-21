# Payment Methods Details Handling

This document explains how payment method details are handled in the booking flow.

## Overview

When a user selects a payment method in Stage 4 of the booking process, the payment details are shown **inline on the same screen** instead of navigating to a separate screen.

## Payment Methods

### 1. Credit Card

**Details Shown:**
- Stripe's `CardField` widget (default Stripe UI)
- Real-time card validation
- Secure card input (card details never touch your server directly)

**How It Works:**
1. User selects "Credit Card" from payment methods
2. Stripe's `CardField` appears below the payment method list
3. User enters card details (number, expiry, CVC)
4. Stripe validates the card in real-time
5. When user clicks "Pay", the card details are sent to Stripe
6. Payment is processed via Stripe Payment Intent API

**Card Details Storage:**
- Card details are **NEVER stored** in your app or backend
- Stripe handles all card data securely
- Only payment method ID or payment intent ID is stored

**Implementation:**
```dart
CardField(
  onCardChanged: (card) {
    // card.complete - true when all fields are valid
    // card.brand - card brand (visa, mastercard, etc.)
    // card.last4 - last 4 digits of card
    // card.expMonth - expiry month
    // card.expYear - expiry year
  },
)
```

### 2. Google Pay

**Details Shown:**
- Google Pay icon and description
- Message: "You will be redirected to Google Pay for authentication"

**How It Works:**
1. User selects "Google Pay"
2. Info message appears below
3. When user clicks "Pay", Google Pay SDK is invoked
4. User authenticates with Google Pay
5. Payment is processed through Google Pay

**Implementation:**
- Currently shows placeholder UI
- TODO: Integrate `google_pay` or `pay` package
- Payment details handled by Google Pay SDK

### 3. Wallet

**Details Shown:**
- Current wallet balance
- Amount to pay
- Remaining balance after payment
- Warning if insufficient balance

**How It Works:**
1. User selects "Wallet"
2. Wallet balance is fetched from `ProfileController`
3. Balance validation happens automatically
4. If sufficient balance, payment proceeds
5. If insufficient, warning is shown

**Wallet Details:**
- Balance: Fetched from `ProfileController.walletBalance`
- Updated after each transaction
- Stored in user profile in database

**Implementation:**
```dart
final profileController = Get.find<ProfileController>();
final balance = profileController.walletBalance.value;
final remaining = balance - amount;
```

### 4. Cash

**Details Shown:**
- Cash icon
- Message: "You will pay $X.XX in cash when the service is completed"

**How It Works:**
1. User selects "Cash"
2. Info message appears
3. Payment status is set to "pending"
4. Payment is collected when service is completed

**Cash Details:**
- No payment processing required upfront
- Payment status: "pending" or "unpaid"
- Updated to "paid" when service is completed

### 5. Apple Pay

**Details Shown:**
- Apple Pay icon and description
- Similar to Google Pay

**How It Works:**
- Similar to Google Pay
- Uses Apple Pay SDK
- Currently placeholder

## Payment Processing Flow

### Credit Card Flow:
1. User enters card details in `CardField`
2. Stripe validates card in real-time
3. User clicks "Pay" button
4. Backend creates Payment Intent
5. Client confirms payment with Stripe
6. Payment status updated to "succeeded"
7. Booking is created with payment method = "card"

### Wallet Flow:
1. User selects "Wallet"
2. System checks wallet balance
3. If sufficient, payment is processed
4. Wallet balance is deducted
5. Booking is created with payment method = "wallet"

### Cash Flow:
1. User selects "Cash"
2. No payment processing
3. Booking is created with payment method = "cash"
4. Payment status = "pending"
5. Updated to "paid" when service completes

## Security Notes

1. **Credit Card**: Never store card details. Use Stripe Payment Intents.
2. **Wallet**: Balance is stored server-side, validated on backend.
3. **Google/Apple Pay**: Payment details handled by respective SDKs.
4. **Cash**: No sensitive data, just payment status.

## Backend Requirements

For each payment method, your backend needs:

1. **Credit Card**:
   - `POST /customer/payment/create-intent` - Create Stripe Payment Intent
   - `POST /customer/payment/confirm` - Confirm payment

2. **Wallet**:
   - Deduct balance from user wallet
   - Create transaction record

3. **Cash**:
   - Set payment status to "pending"
   - Update to "paid" when service completes

## Testing

- **Credit Card**: Use Stripe test cards (4242 4242 4242 4242)
- **Wallet**: Test with different balance amounts
- **Cash**: No special testing needed


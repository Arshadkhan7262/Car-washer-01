# Washer-Friendly Withdrawal System Implementation

## Overview
This document describes the implementation of a washer-friendly withdrawal system using Stripe Connect Transfers. The system allows washers to set up their bank accounts and receive payouts directly, with automatic processing when admins approve withdrawal requests.

## Key Features

### 1. Stripe Connect Integration
- **Express Accounts**: Washers create Stripe Connect Express accounts for receiving payouts
- **Onboarding Flow**: Secure bank account setup via Stripe's hosted onboarding
- **Account Status Tracking**: Real-time status updates (pending, restricted, enabled)

### 2. Automatic Withdrawal Processing
- **Admin Approval**: Admins approve withdrawal requests
- **Automatic Transfer**: Funds are automatically transferred via Stripe Transfers when approved
- **No Payment Sheet**: Removed complex Payment Sheet flow - withdrawals are processed server-side
- **Idempotency Protection**: Prevents duplicate transfers using Stripe idempotency keys

### 3. Race Condition Prevention
- **Database Transactions**: MongoDB sessions ensure atomic operations
- **Balance Locking**: Washer balance is locked during withdrawal processing
- **Status Verification**: Multiple checks prevent concurrent withdrawals

### 4. Webhook Handling
- **Transfer Events**: Handles `transfer.created`, `transfer.paid`, `transfer.failed`
- **Account Updates**: Automatically updates account status when Stripe account changes
- **Error Recovery**: Failed transfers automatically refund wallet balance

## Backend Implementation

### New Files Created

1. **`backend/src/services/stripeConnect.service.js`**
   - `createStripeConnectAccount()` - Creates Stripe Connect Express account
   - `getAccountOnboardingLink()` - Gets onboarding link for existing account
   - `getAccountStatus()` - Checks account status and capabilities

2. **`backend/src/controllers/stripeConnect.controller.js`**
   - Endpoints for creating accounts, getting onboarding links, and checking status

3. **`backend/src/routes/stripeConnect.routes.js`**
   - Routes mounted at `/washer/stripe-connect`

4. **`backend/src/controllers/stripeWebhook.controller.js`**
   - Webhook handler for Stripe events
   - Handles transfer and account update events

### Updated Files

1. **`backend/src/models/Washer.model.js`**
   - Added fields:
     - `stripe_account_id` - Stripe Connect account ID
     - `stripe_account_status` - Account status (none, pending, restricted, enabled, disabled)
     - `stripe_account_onboarding_complete` - Boolean flag for completion

2. **`backend/src/services/withdrawal.service.js`**
   - Updated `createWithdrawalRequest()`:
     - Checks Stripe Connect account setup
     - Uses database transactions
     - Validates account status before allowing withdrawal
   
   - Updated `processWithdrawal()`:
     - Uses Stripe Transfers instead of Payment Intents
     - Implements database transactions for atomicity
     - Adds idempotency protection
     - Locks washer balance during processing
     - Only deducts wallet after successful Stripe transfer

   - Removed `createWithdrawalPaymentIntent()` - No longer needed
   - Updated `processApprovedWithdrawal()` - Simplified for backward compatibility

3. **`backend/src/controllers/withdrawal.controller.js`**
   - Replaced `createWithdrawalPaymentIntent` with `getWithdrawalDetails`
   - Updated to use new withdrawal flow

4. **`backend/src/routes/index.routes.js`**
   - Added Stripe Connect routes
   - Added Stripe webhook routes

## Frontend Implementation

### New Files Created

1. **`car_wash_app/lib/features/wallet/services/stripe_connect_service.dart`**
   - `createAccount()` - Creates Stripe Connect account
   - `getOnboardingLink()` - Gets onboarding link
   - `getAccountStatus()` - Checks account status

2. **`car_wash_app/lib/features/wallet/widgets/bank_account_setup_card.dart`**
   - UI widget prompting washers to set up bank account
   - Shows setup button and status messages

### Updated Files

1. **`car_wash_app/lib/features/wallet/controllers/wallet_controller.dart`**
   - Added Stripe Connect service integration
   - Added `loadStripeAccountStatus()` - Loads account status
   - Added `setupBankAccount()` - Creates account and gets onboarding link
   - Added `openBankAccountSetup()` - Opens Stripe onboarding in browser
   - Updated `refreshData()` - Includes account status refresh

2. **`car_wash_app/lib/features/wallet/widgets/balance_card.dart`**
   - Removed Payment Sheet integration
   - Added bank account status check before allowing withdrawal
   - Shows withdrawal status messages (approved, processing, completed)
   - Simplified withdrawal flow

3. **`car_wash_app/lib/features/wallet/widgets/approved_withdrawal_card.dart`**
   - Removed Payment Sheet processing code
   - Shows informational message about automatic processing
   - Displays withdrawal status

4. **`car_wash_app/lib/features/wallet/wallet_screen.dart`**
   - Added `BankAccountSetupCard` widget
   - Shows bank account setup prompt when needed

## API Endpoints

### Washer Endpoints

#### Stripe Connect
- `POST /api/v1/washer/stripe-connect/create` - Create Stripe Connect account
- `GET /api/v1/washer/stripe-connect/onboarding-link` - Get onboarding link
- `GET /api/v1/washer/stripe-connect/status` - Get account status

#### Withdrawals
- `POST /api/v1/washer/withdrawal/request` - Request withdrawal (requires bank account setup)
- `GET /api/v1/washer/withdrawal/:id` - Get withdrawal details
- `PUT /api/v1/washer/withdrawal/:id/cancel` - Cancel withdrawal
- `GET /api/v1/washer/withdrawal` - Get withdrawal history

### Admin Endpoints

- `PUT /api/v1/admin/withdrawal/:id/approve` - Approve withdrawal
- `PUT /api/v1/admin/withdrawal/:id/process` - Process withdrawal (creates Stripe Transfer)
- `PUT /api/v1/admin/withdrawal/:id/reject` - Reject withdrawal

### Webhook Endpoint

- `POST /api/v1/stripe/webhook` - Stripe webhook handler

## User Flow

### 1. Bank Account Setup
1. Washer opens Wallet screen
2. Sees "Set Up Bank Account" card if not set up
3. Clicks "Set Up Bank Account" button
4. Opens Stripe onboarding page in browser
5. Completes bank account information
6. Returns to app - account status updates automatically

### 2. Withdrawal Request
1. Washer clicks "Request Withdrawal" button
2. System checks bank account setup (must be enabled)
3. System checks wallet balance
4. Creates withdrawal request with status "pending"
5. Admin receives notification

### 3. Admin Approval & Processing
1. Admin approves withdrawal request
2. Admin clicks "Process" button
3. System creates Stripe Transfer to washer's connected account
4. Wallet balance is deducted (only after successful transfer)
5. Withdrawal status changes to "processing" then "completed"
6. Washer receives notification

### 4. Automatic Processing (via Webhooks)
1. Stripe sends `transfer.paid` webhook
2. System updates withdrawal status to "completed"
3. Washer sees completion message in app

## Security Features

1. **Database Transactions**: Ensures atomic operations
2. **Balance Locking**: Prevents concurrent withdrawals
3. **Idempotency Keys**: Prevents duplicate Stripe transfers
4. **Account Verification**: Checks account status before allowing withdrawals
5. **Webhook Signature Verification**: Validates Stripe webhook authenticity

## Error Handling

1. **Failed Transfers**: Automatically refunds wallet balance
2. **Account Setup Errors**: Clear error messages to users
3. **Network Errors**: Retry logic and user-friendly messages
4. **Race Conditions**: Database transactions prevent conflicts

## Environment Variables Required

```env
STRIPE_SECRET_KEY=sk_...
STRIPE_WEBHOOK_SECRET=whsec_...
FRONTEND_URL=https://yourapp.com  # For Stripe return URLs
```

## Testing Checklist

- [ ] Create Stripe Connect account
- [ ] Complete bank account onboarding
- [ ] Request withdrawal (should require bank account setup)
- [ ] Admin approves withdrawal
- [ ] Admin processes withdrawal (creates Stripe Transfer)
- [ ] Verify wallet balance deducted
- [ ] Verify webhook updates withdrawal status
- [ ] Test failed transfer (should refund wallet)
- [ ] Test concurrent withdrawal prevention
- [ ] Test account status updates

## Migration Notes

1. **Existing Washers**: Need to set up Stripe Connect accounts before withdrawing
2. **Pending Withdrawals**: Old Payment Sheet-based withdrawals need to be cancelled and re-requested
3. **Database**: Run migration to add new Stripe Connect fields to Washer model

## Benefits

1. **Simpler UX**: No complex Payment Sheet flow
2. **Automatic Processing**: Withdrawals processed automatically when approved
3. **Better Security**: Server-side processing with proper validation
4. **Race Condition Safe**: Database transactions prevent conflicts
5. **Webhook Integration**: Real-time status updates
6. **Error Recovery**: Automatic refunds on failed transfers

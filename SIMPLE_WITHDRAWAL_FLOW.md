# Simple Withdrawal Flow - Like Other Apps

## Overview
This document describes the updated withdrawal flow that works like popular apps (Uber, DoorDash, etc.) where washers add their bank account details directly in the app, and withdrawals are processed automatically.

## Key Changes

### Before (Complex Stripe Connect Flow)
- Washers had to go through external Stripe Connect onboarding
- Required opening browser and completing Stripe's hosted form
- Complex integration with Stripe Connect Express accounts

### After (Simple In-App Form)
- Washers add bank account details directly in the app
- Simple form with account number, routing number, account holder name
- Works like other popular apps
- Admin processes withdrawals automatically using stored bank account details

## Backend Implementation

### New Models

1. **BankAccount Model** (`backend/src/models/BankAccount.model.js`)
   - Stores bank account details securely
   - Fields: account_holder_name, account_number, routing_number, account_type, bank_name
   - Links to Stripe if Stripe Connect account exists
   - Tracks verification status

### New Services

1. **BankAccount Service** (`backend/src/services/bankAccount.service.js`)
   - `saveBankAccount()` - Save or update bank account details
   - `getBankAccount()` - Get bank account (returns safe data, hides full account number)
   - `deleteBankAccount()` - Delete bank account

### Updated Services

1. **Withdrawal Service** (`backend/src/services/withdrawal.service.js`)
   - Updated to check bank account instead of Stripe Connect account
   - Uses stored bank account details for processing
   - Supports both Stripe Connect (if available) and manual processing

### New API Endpoints

- `POST /api/v1/washer/bank-account` - Add or update bank account
- `GET /api/v1/washer/bank-account` - Get bank account details
- `DELETE /api/v1/washer/bank-account` - Delete bank account

## Frontend Implementation

### New Services

1. **BankAccountService** (`car_wash_app/lib/features/wallet/services/bank_account_service.dart`)
   - Handles API calls for bank account management
   - Methods: `getBankAccount()`, `saveBankAccount()`, `deleteBankAccount()`

### New Widgets

1. **BankAccountForm** (`car_wash_app/lib/features/wallet/widgets/bank_account_form.dart`)
   - Simple form for adding/editing bank account details
   - Fields: Account Holder Name, Account Number, Routing Number, Account Type, Bank Name
   - Validates input and saves to backend

2. **BankAccountSetupCard** (Updated)
   - Shows prompt to add bank account if not set up
   - Opens BankAccountForm when clicked
   - Hides when bank account is verified

### Updated Widgets

1. **BalanceCard**
   - Checks bank account status before allowing withdrawal
   - Shows message with link to add bank account if not set up

2. **WalletController**
   - Updated `loadStripeAccountStatus()` to check bank account first
   - Falls back to Stripe Connect if bank account not found

## User Flow

### 1. Adding Bank Account
1. Washer opens Wallet screen
2. Sees "Set Up Bank Account" card
3. Clicks "Add Bank Account"
4. Fills out form with bank account details:
   - Account Holder Name
   - Account Number
   - Routing Number (9 digits)
   - Account Type (Checking/Savings)
   - Bank Name (Optional)
5. Clicks "Save Bank Account"
6. Account is saved and verified (if Stripe Connect available)

### 2. Requesting Withdrawal
1. Washer clicks "Request Withdrawal"
2. System checks if bank account is set up
3. If not set up, shows message with link to add bank account
4. If set up, creates withdrawal request
5. Admin approves and processes withdrawal

### 3. Processing Withdrawal
1. Admin approves withdrawal request
2. Admin clicks "Process"
3. System uses stored bank account details:
   - If Stripe Connect account exists: Creates Stripe Transfer
   - Otherwise: Stores details for manual processing
4. Wallet balance is deducted
5. Withdrawal marked as completed

## Security Features

1. **Data Storage**: Bank account details stored securely (encrypt in production)
2. **Display Safety**: Only last 4 digits of account number shown
3. **Validation**: Routing number must be 9 digits, account number validated
4. **Ownership Verification**: Only washer can access their own bank account

## Benefits

1. **Simpler UX**: No external browser redirects
2. **Familiar Flow**: Works like other popular apps
3. **Faster Setup**: Washers can add bank account in seconds
4. **Better Control**: All data stored in your database
5. **Flexible Processing**: Supports both automatic and manual processing

## Migration Notes

1. **Existing Washers**: Can add bank account via new form
2. **Stripe Connect**: Still supported if washer has Stripe Connect account
3. **Backward Compatibility**: System checks both bank account and Stripe Connect

## Future Enhancements

1. **Encryption**: Encrypt bank account details at rest
2. **Verification**: Add micro-deposit verification
3. **Multiple Accounts**: Allow washers to add multiple bank accounts
4. **Instant Payouts**: Integrate with instant payout services
5. **Bank Name Auto-fill**: Auto-detect bank name from routing number

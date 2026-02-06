# App-Based Withdrawal Testing Guide

## Overview
This guide explains how to test the bank account and withdrawal system **directly in the mobile app** (not via API).

---

## Prerequisites

1. **Washer Account Status:** Account must be **approved** (status: `active`)
   - If account is `pending`, you'll see "Pending Approval" overlay
   - Admin must approve account first

2. **Wallet Balance:** Washer must have wallet balance > 0
   - For testing, admin can add balance via admin panel or database

3. **Bank Account:** Must be set up before requesting withdrawal

---

## Part 1: Setting Up Bank Account (In App)

### Step 1: Navigate to Wallet Screen
1. Open the app and login as washer
2. Go to **Wallet** tab (bottom navigation)
3. You'll see the wallet screen with balance card

### Step 2: Add Bank Account
1. **If bank account is NOT set up:**
   - You'll see an orange card: **"Set Up Bank Account"**
   - Tap **"Add Bank Account"** button

2. **Bank Account Form will open:**
   - Fill in the following fields using the recommended test values:

| Field | Recommended Test Value | Note |
|-------|----------------------|------|
| **Account Holder Name** | `Test User` or `John Doe` | Any string works |
| **Account Number** | `000123456789` | Standard mock length |
| **Routing Number** | `110000000` | Standard Stripe/MFA test routing number |
| **Account Type** | `checking` | Usually checking or savings |
| **Bank Name** | `Test Bank` | For identification in UI |

3. **Tap "Save"** button
   - You'll see success message: "Bank account saved successfully"
   - The orange setup card will disappear

### Step 3: Verify Bank Account (Admin Required)
- Bank account needs admin verification before withdrawals are allowed
- For testing, admin can verify via admin panel or database
- Once verified, `canWithdraw` will be `true`

---

## Part 2: Requesting Withdrawal (In App)

### Step 1: Check Wallet Balance
1. Go to **Wallet** tab
2. Check your **Current Balance** at the top
3. Ensure balance > 0

### Step 2: Request Withdrawal
1. **If bank account is set up and verified:**
   - You'll see **"Request Withdrawal"** button below balance
   - Tap the button

2. **What happens:**
   - Withdrawal request is created with your full balance
   - You'll see success message: "Withdrawal request sent successfully. Waiting for admin approval."
   - Balance card will show withdrawal status

3. **If bank account is NOT set up:**
   - You'll see error: "Please set up your bank account first to receive payouts"
   - Orange setup card will be visible

4. **If balance is 0:**
   - You'll see error: "You have no earnings to withdraw"
   - Button may be disabled

### Step 3: View Withdrawal Status
- After requesting, you'll see withdrawal card showing:
  - **Status:** "Pending" (waiting for admin approval)
  - **Amount:** Requested amount
  - **Requested Date:** When you requested

---

## Part 3: Admin Approval (Admin Panel)

### Step 1: Login as Admin
1. Open admin panel (web interface)
   - Navigate to admin panel URL (e.g., `https://your-admin-panel.com`)
2. Login with admin credentials
   - Enter admin email and password
   - Click **"Login"** button

### Step 2: Navigate to Withdrawals Section
1. **In the admin dashboard sidebar/menu:**
   - Look for **"Withdrawals"** or **"Payouts"** menu item
   - Click on it to open withdrawals page

2. **Filter by Status:**
   - Look for filter dropdown or tabs
   - Select **"Pending"** status filter
   - Or click on **"Pending Withdrawals"** tab
   - You'll see all pending withdrawal requests in a table/list

### Step 3: View Withdrawal Details
1. **In the withdrawals list:**
   - Find the withdrawal request you want to approve
   - You'll see columns like:
     - Washer Name
     - Amount
     - Requested Date
     - Status (should show "Pending")
     - Actions

2. **Click on the withdrawal row or "View Details" button:**
   - This opens withdrawal detail page/modal
   - Review all details:
     - **Washer Name:** Name of the washer requesting withdrawal
     - **Amount:** Requested withdrawal amount (e.g., $100.00)
     - **Bank Account:** Last 4 digits of account number
     - **Account Holder:** Name on bank account
     - **Routing Number:** Bank routing number
     - **Bank Name:** Name of the bank
     - **Requested Date:** When withdrawal was requested

### Step 4: Approve Withdrawal
1. **On the withdrawal detail page:**
   - Review all information carefully
   - Verify bank account details are correct
   - Check that amount is valid

2. **Click "Approve" button:**
   - Button is usually located at:
     - Top right of detail page
     - Bottom of detail modal
     - In the actions column of the list
   - Button text: **"Approve"** or **"Approve Withdrawal"**

3. **Confirm approval (if prompted):**
   - Some admin panels show a confirmation dialog
   - Click **"Confirm"** or **"Yes, Approve"**

4. **Success:**
   - You'll see success message: "Withdrawal approved successfully"
   - Status changes to **"Approved"** in the list
   - Withdrawal moves from "Pending" to "Approved" section

### Step 5: Process Withdrawal
1. **Navigate to Approved Withdrawals:**
   - Go back to withdrawals list
   - Filter by **"Approved"** status
   - Or click **"Approved Withdrawals"** tab
   - Find the withdrawal you just approved

2. **Click on the withdrawal:**
   - Open withdrawal detail page again
   - Status should now show "Approved"

3. **Click "Process" button:**
   - Button is usually located at:
     - Top right of detail page
     - Bottom of detail modal
     - In the actions column (next to "Approve")
   - Button text: **"Process"** or **"Process Payout"** or **"Send Payment"**

4. **Confirm processing (if prompted):**
   - Some admin panels show a confirmation dialog
   - Review final details
   - Click **"Confirm"** or **"Yes, Process"**

5. **What happens:**
   - Withdrawal status changes to **"Processing"** then **"Completed"**
   - Amount is deducted from washer's wallet balance
   - If Stripe Connect is configured, payout is created automatically
   - Transaction is recorded in database

6. **Success:**
   - You'll see success message: "Withdrawal processed successfully"
   - Status changes to **"Completed"** in the list
   - Withdrawal moves to "Completed" section

---

## Part 4: Complete Testing Flow (In App)

### Test Scenario 1: First Time Setup

1. **Login as Washer**
   - Account must be approved (`active` status)

2. **Go to Wallet Tab**
   - See current balance (should be 0 or test amount)

3. **Set Up Bank Account**
   - Tap "Add Bank Account"
   - Fill form and save
   - See success message

4. **Admin Verifies Bank Account**

   **Via Admin Panel (Recommended):**
   - Login to admin panel
   - Click **"Washers"** in sidebar menu
   - Find washer → Click name
   - Go to **"Bank Account"** section
   - Click **"Verify"** button or toggle switch
   
   **Via Database (For Testing):**
   ```javascript
   db.bankaccounts.updateOne(
     { washer_id: ObjectId("WASHER_ID") },
     { $set: { is_verified: true, status: "verified" } }
   )
   ```

5. **Add Wallet Balance** (for testing)

   **Via Admin Panel (Recommended):**
   - Login to admin panel
   - Click **"Washers"** → Select washer
   - Go to **"Wallet"** section
   - Click **"Add Balance"** button
   - Enter amount: `100.00`
   - Click **"Save"**
   
   **Via Database (For Testing):**
   ```javascript
   db.washers.updateOne(
     { user_id: ObjectId("USER_ID") },
     { $set: { wallet_balance: 100.00 } }
   )
   ```

6. **Pull to Refresh Wallet Screen**
   - Balance updates to show new amount

7. **Request Withdrawal**
   - Tap "Request Withdrawal" button
   - See success message
   - See withdrawal card with "Pending" status

8. **Admin Approves** (via admin panel)
   - Status changes to "Approved"

9. **Admin Processes** (via admin panel)
   - Status changes to "Completed"
   - Wallet balance deducted

10. **Refresh Wallet Screen**
    - Balance shows deducted amount
    - Withdrawal card shows "Completed" status

---

## Part 5: Testing Different Scenarios

### Scenario A: Bank Account Not Set Up
**Steps:**
1. Login as washer
2. Go to Wallet tab
3. Try to tap "Request Withdrawal"
4. **Expected:** Error message: "Please set up your bank account first"

### Scenario B: Bank Account Not Verified
**Steps:**
1. Set up bank account using test values:
   - Account Holder: `Test User`
   - Account Number: `000123456789`
   - Routing Number: `110000000`
   - Account Type: `checking`
   - Bank Name: `Test Bank`
2. Don't verify (keep `is_verified: false`)
3. Try to request withdrawal
4. **Expected:** Error message: "Please set up your bank account first" (because `canWithdraw` is false)

### Scenario C: Insufficient Balance
**Steps:**
1. Set up and verify bank account
2. Ensure balance is 0
3. Try to request withdrawal
4. **Expected:** Error message: "You have no earnings to withdraw"

### Scenario D: Already Has Pending Withdrawal
**Steps:**
1. Request withdrawal (status: pending)
2. Try to request another withdrawal
3. **Expected:** Error message: "You already have a pending withdrawal request"

### Scenario E: Account Not Approved
**Steps:**
1. Login with `pending` status account
2. Go to Wallet tab
3. **Expected:** "Pending Approval" overlay shown, can't access wallet features

---

## Part 6: UI Elements to Check

### Wallet Screen Elements:

1. **Balance Card:**
   - Shows current wallet balance
   - Shows "Request Withdrawal" button (if conditions met)
   - Shows withdrawal status card (if withdrawal exists)

2. **Bank Account Setup Card:**
   - Orange card appears if bank account not set up
   - Disappears after setup

3. **Approved Withdrawal Card:**
   - Shows if withdrawal is approved
   - Displays amount and status

4. **Transaction History:**
   - Shows all wallet transactions
   - Includes withdrawals

5. **Pull to Refresh:**
   - Pull down on wallet screen to refresh data
   - Updates balance and withdrawal status

---

## Part 7: Quick Testing Checklist

### Setup Phase:
- [ ] Washer account is approved (`active` status)
- [ ] Login successfully as washer
- [ ] Navigate to Wallet tab
- [ ] See wallet balance displayed

### Bank Account Setup:
- [ ] See "Set Up Bank Account" card (if not set up)
- [ ] Tap "Add Bank Account" button
- [ ] Fill bank account form
- [ ] Save bank account successfully
- [ ] Card disappears after setup

### Admin Verification:
- [ ] Admin verifies bank account (via admin panel or database)
- [ ] Refresh wallet screen
- [ ] `canWithdraw` becomes `true`

### Add Balance (Testing):
- [ ] Admin adds wallet balance (via admin panel or database)
- [ ] Refresh wallet screen
- [ ] Balance updates correctly

### Request Withdrawal:
- [ ] Tap "Request Withdrawal" button
- [ ] See success message
- [ ] See withdrawal card with "Pending" status
- [ ] Balance still shows (not deducted yet)

### Admin Approval:
- [ ] Admin approves withdrawal (via admin panel)
- [ ] Refresh wallet screen in app
- [ ] Status changes to "Approved"

### Admin Processing:
- [ ] Admin processes withdrawal (via admin panel)
- [ ] Refresh wallet screen in app
- [ ] Status changes to "Completed"
- [ ] Balance is deducted correctly
- [ ] Transaction appears in history

---

## Part 8: Common Issues & Solutions

### Issue 1: "Please set up your bank account first"
**Solution:**
- Go to Wallet tab
- Tap "Add Bank Account"
- Fill and save bank account details
- Admin must verify bank account

### Issue 2: "You have no earnings to withdraw"
**Solution:**
- Admin needs to add wallet balance
- Or complete jobs to earn money

### Issue 3: "You already have a pending withdrawal request"
**Solution:**
- Wait for admin to approve/process existing withdrawal
- Or admin can cancel existing withdrawal

### Issue 4: Can't see Wallet tab
**Solution:**
- Account must be approved (`active` status)
- If `pending`, you'll see approval overlay

### Issue 5: Balance not updating after refresh
**Solution:**
- Pull down to refresh wallet screen
- Check internet connection
- Wait a few seconds and refresh again

---

## Part 9: Database Queries for Testing

### Add Wallet Balance (for testing):
```javascript
// Find washer by user email
db.users.findOne({email: "washer@example.com"})

// Update wallet balance
db.washers.updateOne(
  { user_id: ObjectId("USER_ID") },
  { $set: { wallet_balance: 100.00 } }
)
```

### Verify Bank Account:

**Via Admin Panel (Recommended):**
1. Login to admin panel
2. Navigate to **Washers** → Select washer → **Bank Account** section
3. Click **"Verify"** button or toggle **"Verified"** switch

**Via Database (For Testing):**
```javascript
db.bankaccounts.updateOne(
  { washer_id: ObjectId("WASHER_ID") },
  { $set: { is_verified: true, status: "verified" } }
)
```

### Check Withdrawal Status:
```javascript
db.withdrawals.find(
  { washer_id: ObjectId("WASHER_ID") }
).sort({ requested_date: -1 })
```

### Approve Washer Account:
```javascript
db.washers.updateOne(
  { user_id: ObjectId("USER_ID") },
  { $set: { status: "active" } }
)
```

---

## Part 10: Step-by-Step App Testing

### Complete End-to-End Test:

1. **Login as Washer**
   ```
   - Open app
   - Login with washer credentials
   - Ensure account is approved
   ```

2. **Navigate to Wallet**
   ```
   - Tap "Wallet" tab (bottom navigation)
   - See balance card at top
   ```

3. **Set Up Bank Account**
   ```
   - See orange "Set Up Bank Account" card
   - Tap "Add Bank Account"
   - Fill form with test values:
     * Account Holder: Test User (or John Doe)
     * Account Number: 000123456789
     * Routing Number: 110000000
     * Account Type: checking
     * Bank Name: Test Bank
   - Tap "Save"
   - See success message
   ```

4. **Admin Verifies Bank Account**

   **Via Admin Panel:**
   ```
   - Login to admin panel
   - Click "Washers" in sidebar
   - Find washer → Click name
   - Go to "Bank Account" section
   - Click "Verify" button
   ```
   
   **Via Database (For Testing):**
   ```javascript
   db.bankaccounts.updateOne(
     { washer_id: ObjectId("WASHER_ID") },
     { $set: { is_verified: true, status: "verified" } }
   )
   ```

5. **Add Test Balance**

   **Via Admin Panel:**
   ```
   - Login to admin panel
   - Click "Washers" → Select washer
   - Go to "Wallet" section
   - Click "Add Balance" button
   - Enter amount: 100.00
   - Click "Save"
   ```
   
   **Via Database (For Testing):**
   ```javascript
   db.washers.updateOne(
     { user_id: ObjectId("USER_ID") },
     { $set: { wallet_balance: 100.00 } }
   )
   ```

6. **Refresh Wallet Screen**
   ```
   - Pull down to refresh
   - See updated balance: $100.00
   ```

7. **Request Withdrawal**
   ```
   - Tap "Request Withdrawal" button
   - See success message
   - See withdrawal card: Status "Pending", Amount $100.00
   ```

8. **Admin Approves** (via admin panel)
   ```
   - Login as admin
   - Click "Withdrawals" in sidebar menu
   - Click "Pending" tab or filter by "Pending" status
   - Click on the withdrawal request
   - Review details (washer name, amount, bank account)
   - Click "Approve" button
   - Confirm approval if prompted
   - See success message: "Withdrawal approved successfully"
   ```

9. **Refresh Wallet Screen**
   ```
   - Pull down to refresh
   - See withdrawal status: "Approved"
   ```

10. **Admin Processes** (via admin panel)
    ```
    - Go to Withdrawals section
    - Click "Approved" tab or filter by "Approved" status
    - Click on the approved withdrawal
    - Review final details
    - Click "Process" or "Process Payout" button
    - Confirm processing if prompted
    - See success message: "Withdrawal processed successfully"
    - Status changes to "Completed"
    - Wallet balance is deducted
    ```

11. **Final Check in App**
    ```
    - Refresh wallet screen
    - See balance: $0.00 (deducted)
    - See withdrawal card: Status "Completed"
    - See transaction in history
    ```

---

## Part 11: Visual Guide

### Wallet Screen Layout:

```
┌─────────────────────────────┐
│     My Wallet (Header)      │
├─────────────────────────────┤
│                             │
│   Balance Card              │
│   ┌─────────────────────┐   │
│   │ Current Balance     │   │
│   │ $100.00             │   │
│   │ [Request Withdrawal] │   │
│   └─────────────────────┘   │
│                             │
│   Bank Account Setup Card   │
│   (if not set up)           │
│   ┌─────────────────────┐   │
│   │ ⚠️ Set Up Bank       │   │
│   │ [Add Bank Account]  │   │
│   └─────────────────────┘   │
│                             │
│   Withdrawal Card           │
│   (if withdrawal exists)    │
│   ┌─────────────────────┐   │
│   │ Status: Pending       │   │
│   │ Amount: $100.00       │   │
│   └─────────────────────┘   │
│                             │
│   Wallet Stats              │
│   ┌─────┬─────┬─────┐     │
│   │Today│Week │Month│     │
│   └─────┴─────┴─────┘     │
│                             │
│   Transaction History       │
│   ┌─────────────────────┐   │
│   │ Withdrawal $100.00   │   │
│   │ Status: Completed    │   │
│   └─────────────────────┘   │
│                             │
└─────────────────────────────┘
```

---

## Part 12: Tips for Testing

1. **Use Pull-to-Refresh:**
   - Always pull down to refresh after admin actions
   - This ensures you see latest data

2. **Check Status Messages:**
   - App shows clear success/error messages
   - Read messages carefully for guidance

3. **Test Edge Cases:**
   - Try withdrawing with 0 balance
   - Try withdrawing without bank account
   - Try multiple withdrawals

4. **Monitor Backend Logs:**
   - Check backend logs when testing
   - Look for API calls and responses

5. **Database Verification:**
   - After each step, verify in database
   - Check wallet balance, withdrawal status

---

## Support

If you encounter issues:
1. Check app error messages
2. Verify account status is `active`
3. Check wallet balance > 0
4. Ensure bank account is verified
5. Check backend logs for API errors
6. Verify database data consistency

---

## Quick Reference

### Test Values for Bank Account Form:

| Field | Recommended Test Value | Note |
|-------|----------------------|------|
| **Account Holder Name** | `Test User` or `John Doe` | Any string works |
| **Account Number** | `000123456789` | Standard mock length |
| **Routing Number** | `110000000` | Standard Stripe/MFA test routing number |
| **Account Type** | `checking` | Usually checking or savings |
| **Bank Name** | `Test Bank` | For identification in UI |

### App Screens:
- **Wallet Tab** → Main withdrawal interface
- **Bank Account Form** → Add bank account
- **Transaction History** → View withdrawals

### Admin Actions (Step-by-Step):

1. **Approve Washer Account:**
   - Login to admin panel
   - Click **"Washers"** in sidebar menu
   - Find washer → Click name
   - Click **"Approve"** button
   - Status changes to `active`

2. **Verify Bank Account:**
   - Login to admin panel
   - Click **"Washers"** → Select washer
   - Go to **"Bank Account"** section
   - Click **"Verify"** button or toggle switch
   - `is_verified` set to `true`

3. **Add Wallet Balance:**
   - Login to admin panel
   - Click **"Washers"** → Select washer
   - Go to **"Wallet"** section
   - Click **"Add Balance"** button
   - Enter amount → Click **"Save"**

4. **Approve Withdrawal:**
   - Login to admin panel
   - Click **"Withdrawals"** in sidebar menu
   - Click **"Pending"** tab or filter by "Pending" status
   - Click on withdrawal request
   - Review details → Click **"Approve"** button
   - Status changes to `approved`

5. **Process Withdrawal:**
   - Login to admin panel
   - Click **"Withdrawals"** → **"Approved"** tab
   - Click on approved withdrawal
   - Click **"Process"** or **"Process Payout"** button
   - Status changes to `completed`

### App Actions:
- **Add Bank Account** → Fill form with test values and save
- **Request Withdrawal** → Tap button
- **Refresh Data** → Pull down on screen
- **View Status** → Check withdrawal card

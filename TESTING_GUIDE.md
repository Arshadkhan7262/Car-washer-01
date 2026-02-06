# Testing Guide: Bank Account & Withdrawal System

## Overview
This guide explains how to test the bank account management and withdrawal system for washers.

## Prerequisites
1. Washer account must be **approved** (status: `active`)
2. Washer must have **wallet balance** > 0
3. Admin account for approving withdrawals

---

## Part 1: Adding Bank Account Details

### Step 1: Get Washer Authentication Token
1. Login as washer via app or API
2. Copy the authentication token from response

### Step 2: Add Bank Account via API

**Endpoint:** `POST /api/v1/washer/bank-account`

**Headers:**
```
Authorization: Bearer <washer_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "account_holder_name": "John Doe",
  "account_number": "1234567890",
  "routing_number": "110000000",
  "account_type": "checking",
  "bank_name": "Test Bank"
}
```

**Example using cURL:**
```bash
curl -X POST https://your-api-url/api/v1/washer/bank-account \
  -H "Authorization: Bearer YOUR_WASHER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "account_holder_name": "John Doe",
    "account_number": "1234567890",
    "routing_number": "110000000",
    "account_type": "checking",
    "bank_name": "Test Bank"
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "id": "...",
    "account_holder_name": "John Doe",
    "account_number_last4": "7890",
    "routing_number": "110000000",
    "account_type": "checking",
    "bank_name": "Test Bank",
    "is_verified": false,
    "status": "pending"
  }
}
```


### Step 3: Verify Bank Account (Admin)
Bank account will be marked as `is_verified: true` after admin review or Stripe verification.

**For Testing:** You can manually update in database:
```javascript
// In MongoDB
db.bankaccounts.updateOne(
  { washer_id: ObjectId("...") },
  { $set: { is_verified: true, status: "verified" } }
)
```

---

## Part 2: Requesting Withdrawal

### Step 1: Ensure Wallet Balance
Washer must have wallet balance > 0. You can add balance via admin panel or database:

**Via Database:**
```javascript
db.washers.updateOne(
  { user_id: ObjectId("...") },
  { $set: { wallet_balance: 100.00 } }
)
```

### Step 2: Create Withdrawal Request

**Endpoint:** `POST /api/v1/washer/withdrawal/request`

**Headers:**
```
Authorization: Bearer <washer_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "amount": 50.00,
  "currency": "usd"
}
```

**Example using cURL:**
```bash
curl -X POST https://your-api-url/api/v1/washer/withdrawal/request \
  -H "Authorization: Bearer YOUR_WASHER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 50.00,
    "currency": "usd"
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "id": "...",
    "amount": 50.00,
    "status": "pending",
    "requested_date": "2026-02-05T10:00:00.000Z"
  }
}
```

---

## Part 3: Admin Approval & Processing

### Step 1: Get All Pending Withdrawals (Admin)

**Endpoint:** `GET /api/v1/admin/withdrawal/all?status=pending`

**Headers:**
```
Authorization: Bearer <admin_token>
```

**Example using cURL:**
```bash
curl -X GET "https://your-api-url/api/v1/admin/withdrawal/all?status=pending" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

### Step 2: Approve Withdrawal (Admin)

**Endpoint:** `PUT /api/v1/admin/withdrawal/:id/approve`

**Headers:**
```
Authorization: Bearer <admin_token>
Content-Type: application/json
```

**Request Body (optional):**
```json
{
  "admin_note": "Approved for processing"
}
```

**Example using cURL:**
```bash
curl -X PUT https://your-api-url/api/v1/admin/withdrawal/WITHDRAWAL_ID/approve \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "admin_note": "Approved for processing"
  }'
```

### Step 3: Process Withdrawal (Admin)

**Endpoint:** `PUT /api/v1/admin/withdrawal/:id/process`

**Headers:**
```
Authorization: Bearer <admin_token>
```

**Example using cURL:**
```bash
curl -X PUT https://your-api-url/api/v1/admin/withdrawal/WITHDRAWAL_ID/process \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

**What happens:**
1. Withdrawal status changes to `processing`
2. Wallet balance is deducted
3. If Stripe Connect is configured, payout is created
4. Status changes to `completed`

---

## Part 4: Testing Flow Summary

### Complete Test Flow:

1. **Setup:**
   - Create washer account
   - Approve washer account (status: `active`)
   - Add wallet balance (e.g., $100)

2. **Add Bank Account:**
   ```
   POST /api/v1/washer/bank-account
   → Verify bank account (set is_verified: true)
   ```

3. **Request Withdrawal:**
   ```
   POST /api/v1/washer/withdrawal/request
   → Status: pending
   ```

4. **Admin Approve:**
   ```
   PUT /api/v1/admin/withdrawal/:id/approve
   → Status: approved
   ```

5. **Admin Process:**
   ```
   PUT /api/v1/admin/withdrawal/:id/process
   → Status: completed
   → Wallet balance deducted
   ```

---

## Part 5: Testing via Postman/Thunder Client

### Collection Setup:

1. **Environment Variables:**
   - `base_url`: Your API base URL
   - `washer_token`: Washer authentication token
   - `admin_token`: Admin authentication token
   - `washer_id`: Washer ID
   - `withdrawal_id`: Withdrawal request ID

2. **Request Sequence:**
   ```
   1. POST /washer/bank-account (Add bank account)
   2. GET /washer/bank-account (Verify bank account added)
   3. POST /washer/withdrawal/request (Request withdrawal)
   4. GET /admin/withdrawal/all?status=pending (View pending)
   5. PUT /admin/withdrawal/:id/approve (Approve)
   6. PUT /admin/withdrawal/:id/process (Process)
   7. GET /washer/wallet (Verify balance deducted)
   ```

---

## Part 6: Common Issues & Solutions

### Issue 1: "Please set up your bank account first"
**Solution:** Add bank account before requesting withdrawal

### Issue 2: "Insufficient wallet balance"
**Solution:** Add wallet balance via admin panel or database

### Issue 3: "You already have a pending withdrawal request"
**Solution:** Complete or cancel existing withdrawal request first

### Issue 4: "Only active washers can request withdrawal"
**Solution:** Ensure washer account status is `active` (not `pending`)

### Issue 5: Bank account not verified
**Solution:** Set `is_verified: true` in database for testing

---

## Part 7: Database Queries for Testing

### Check Washer Wallet Balance:
```javascript
db.washers.findOne(
  { user_id: ObjectId("USER_ID") },
  { wallet_balance: 1, name: 1 }
)
```

### Check Bank Account:
```javascript
db.bankaccounts.findOne(
  { washer_id: ObjectId("WASHER_ID") }
)
```

### Check Withdrawal Status:
```javascript
db.withdrawals.find(
  { washer_id: ObjectId("WASHER_ID") }
).sort({ requested_date: -1 })
```

### Manually Add Wallet Balance:
```javascript
db.washers.updateOne(
  { user_id: ObjectId("USER_ID") },
  { $inc: { wallet_balance: 100.00 } }
)
```

### Verify Bank Account:
```javascript
db.bankaccounts.updateOne(
  { washer_id: ObjectId("WASHER_ID") },
  { $set: { is_verified: true, status: "verified" } }
)
```

---

## Part 8: Testing Checklist

- [ ] Washer account is approved (status: `active`)
- [ ] Bank account is added successfully
- [ ] Bank account is verified (`is_verified: true`)
- [ ] Wallet balance > 0
- [ ] Withdrawal request created successfully
- [ ] Withdrawal appears in admin pending list
- [ ] Admin can approve withdrawal
- [ ] Admin can process withdrawal
- [ ] Wallet balance is deducted correctly
- [ ] Withdrawal status changes to `completed`
- [ ] Washer can view withdrawal history

---

## Notes

1. **Stripe Integration:** For production, Stripe Connect accounts are required for automatic payouts. For testing, manual processing is used.

2. **Bank Account Security:** Full account numbers are stored encrypted. Only last 4 digits are displayed.

3. **Minimum Withdrawal:** Check minimum withdrawal limit via `GET /api/v1/washer/withdrawal/limit`

4. **Withdrawal History:** View via `GET /api/v1/washer/withdrawal`

---

## Support

If you encounter issues:
1. Check backend logs for detailed error messages
2. Verify authentication tokens are valid
3. Ensure all required fields are provided
4. Check database for data consistency

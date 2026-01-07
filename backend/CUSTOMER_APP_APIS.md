# Customer App (wash_away) APIs

This document describes the APIs created specifically for the wash_away customer app. These APIs are separate from the admin customer APIs (`/api/v1/admin/customers`).

## Base URL
All customer app APIs are prefixed with: `/api/v1/customer/`

## Authentication
All routes require customer authentication via JWT token in the Authorization header:
```
Authorization: Bearer <token>
```

---

## Profile APIs

### 1. Get Customer Profile
**GET** `/api/v1/customer/profile`

Get customer profile with stats and preferences.

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "customer_id",
      "name": "John Doe",
      "email": "john@example.com",
      "phone": "+1234567890",
      "userInitial": "J",
      "email_verified": true,
      "phone_verified": true,
      "is_gold_member": false,
      "wallet_balance": 25.0
    },
    "stats": {
      "total_washes": 5,
      "total_spent": 150.0,
      "wallet_balance": 25.0
    },
    "preferences": {
      "push_notification_enabled": false,
      "two_factor_auth_enabled": false
    }
  }
}
```

### 2. Update Customer Profile
**PUT** `/api/v1/customer/profile`

Update customer profile information.

**Request Body:**
```json
{
  "name": "John Doe",      // Optional
  "phone": "+1234567890",  // Optional
  "email": "john@example.com" // Optional
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": { ... },
    "stats": { ... },
    "preferences": { ... }
  },
  "message": "Profile updated successfully"
}
```

---

## Stats APIs

### 3. Get Customer Stats
**GET** `/api/v1/customer/profile/stats`

Get customer statistics (total washes, total spent).

**Response:**
```json
{
  "success": true,
  "data": {
    "total_washes": 5,
    "total_spent": 150.0
  }
}
```

**Note:** 
- `total_washes` counts only completed bookings
- `total_spent` sums the total amount from all completed bookings (both paid and unpaid)

---

## Preferences APIs

### 4. Get Customer Preferences
**GET** `/api/v1/customer/profile/preferences`

Get customer preferences.

**Response:**
```json
{
  "success": true,
  "data": {
    "push_notification_enabled": false,
    "two_factor_auth_enabled": false
  }
}
```

### 5. Update Customer Preferences
**PUT** `/api/v1/customer/profile/preferences`

Update customer preferences.

**Request Body:**
```json
{
  "push_notification_enabled": true,    // Optional
  "two_factor_auth_enabled": false      // Optional
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "push_notification_enabled": true,
    "two_factor_auth_enabled": false
  },
  "message": "Preferences updated successfully"
}
```

---

## Database Schema Updates

### User Model
Added the following fields to the User model:

```javascript
preferences: {
  push_notification_enabled: {
    type: Boolean,
    default: false
  },
  two_factor_auth_enabled: {
    type: Boolean,
    default: false
  }
},
is_gold_member: {
  type: Boolean,
  default: false
}
```

---

## Error Responses

All APIs return standard error responses:

```json
{
  "success": false,
  "message": "Error message here"
}
```

**Common HTTP Status Codes:**
- `200` - Success
- `400` - Bad Request (validation errors)
- `401` - Unauthorized (invalid or missing token)
- `403` - Forbidden (account blocked/deactivated)
- `404` - Not Found (customer not found)
- `500` - Internal Server Error

---

## Notes

1. **Separation from Admin APIs:**
   - Admin customer APIs: `/api/v1/admin/customers/*`
   - Customer app APIs: `/api/v1/customer/profile/*`
   - These are completely separate and serve different purposes

2. **Stats Calculation:**
   - Total washes: Count of bookings with `status: 'completed'`
   - Total spent: Sum of `total` field from completed bookings

3. **Gold Member Status:**
   - Currently stored in `is_gold_member` field
   - Can be updated via admin panel or business logic

4. **User Initial:**
   - Automatically calculated from the first character of the user's name
   - Used for avatar display in the app

---

## Integration Status

✅ **APIs Created** - Ready for integration
⏳ **App Integration** - Not yet integrated in wash_away app




# Admin Washer APIs Documentation

## Overview
This document describes the admin-specific APIs for managing washers in the Admin Panel. These APIs are separate from the Washer App APIs and are designed for administrative operations.

## API Structure

### Base URL
```
/api/v1/admin/washers
```

### Authentication
All endpoints require admin authentication via Bearer token:
```
Authorization: Bearer <admin_access_token>
```

---

## Endpoints

### GET `/admin/washers`
Get all washers with filters and pagination.

**Query Parameters:**
- `status` (optional): Filter by status (`pending`, `active`, `suspended`, `inactive`)
- `online_status` (optional): Filter by online status (`true`/`false`)
- `search` (optional): Search by name, email, or phone
- `page` (optional, default: 1): Page number
- `limit` (optional, default: 20): Items per page
- `sort` (optional, default: `-created_date`): Sort order

**Response:**
```json
{
  "success": true,
  "data": {
    "washers": [
      {
        "id": "...",
        "_id": "...",
        "name": "John Washer",
        "phone": "+1234567890",
        "email": "john@example.com",
        "status": "active",
        "online_status": true,
        "rating": 4.5,
        "email_verified": true,
        "jobs_completed": 150,
        "total_jobs": 160,
        "jobs_cancelled": 10,
        "total_ratings": 0,
        "total_earnings": 7500.00,
        "wallet_balance": 1250.00,
        "branch_name": "Main Branch",
        "branch_id": "...",
        "created_date": "2024-01-15T10:00:00Z"
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

---

### GET `/admin/washers/:id`
Get washer details by ID with full profile and statistics.

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "...",
    "name": "John Washer",
    "phone": "+1234567890",
    "email": "john@example.com",
    "status": "active",
    "online_status": true,
    "rating": 4.5,
    "email_verified": true,
    "jobs_completed": 150,
    "total_jobs": 160,
    "jobs_cancelled": 10,
    "total_ratings": 0,
    "total_earnings": 7500.00,
    "wallet_balance": 1250.00,
    "performance": {
      "totalJobs": 160,
      "completedJobs": 150,
      "cancelledJobs": 10,
      "pendingJobs": 5,
      "totalEarnings": 7500.00,
      "walletBalance": 1250.00
    },
    "recentJobs": [...]
  }
}
```

---

### POST `/admin/washers`
Create a new washer (Admin only).

**Body:**
```json
{
  "name": "John Washer",
  "phone": "+1234567890",
  "email": "john@example.com",
  "status": "active",
  "branch_id": "...",
  "branch_name": "Main Branch"
}
```

**Important Notes:**
- When admin creates a washer:
  - `email_verified` is automatically set to `true`
  - `status` defaults to `active` (can be overridden)
  - A User record is created if it doesn't exist
  - If User exists, it's updated to have `role: 'washer'` and `email_verified: true`

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "...",
    "name": "John Washer",
    "phone": "+1234567890",
    "email": "john@example.com",
    "status": "active",
    "email_verified": true,
    "jobs_completed": 0,
    "total_jobs": 0,
    "jobs_cancelled": 0,
    "total_earnings": 0,
    "wallet_balance": 0
  }
}
```

---

### PUT `/admin/washers/:id`
Update washer details.

**Body:**
```json
{
  "name": "John Washer Updated",
  "phone": "+1234567890",
  "email": "john.updated@example.com",
  "status": "active",
  "online_status": true,
  "rating": 4.5
}
```

**Status Change Behavior:**
- When status changes to `active`:
  - User's `is_active` is set to `true`
- When status changes to `suspended` or `inactive`:
  - User's `is_active` is set to `false`

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "...",
    "name": "John Washer Updated",
    "status": "active",
    "email_verified": true,
    "jobs_completed": 150,
    "total_jobs": 160,
    "jobs_cancelled": 10,
    "total_earnings": 7500.00,
    "wallet_balance": 1250.00
  }
}
```

---

### DELETE `/admin/washers/:id`
Delete a washer.

**Validation:**
- Cannot delete washer with active bookings (status: `pending`, `accepted`, `on_the_way`, `in_progress`)

**Response:**
```json
{
  "success": true,
  "message": "Washer deleted successfully"
}
```

---

## Field Mapping

The API response includes computed fields for admin panel compatibility:

| Admin Panel Field | Source | Description |
|------------------|--------|-------------|
| `jobs_completed` | `completed_jobs` or calculated | Number of completed jobs |
| `total_jobs` | `total_jobs` or calculated | Total number of jobs |
| `jobs_cancelled` | Calculated from bookings | Number of cancelled jobs |
| `total_ratings` | Placeholder (0) | Total number of ratings (TODO: implement) |
| `total_earnings` | Calculated from bookings or `total_earnings` | Total earnings from completed jobs |
| `wallet_balance` | `wallet_balance` | Current wallet balance |
| `email_verified` | From User model | Email verification status |

---

## Admin Panel Integration

The admin panel (`CarWashProAdminPanel`) uses these endpoints via `base44.entities.Washer`:

```javascript
// List washers
base44.entities.Washer.list('-created_date', 200)

// Filter washers
base44.entities.Washer.filter({ status: 'active' })

// Get washer by ID
base44.entities.Washer.get(id)

// Create washer
base44.entities.Washer.create({ name, phone, email, ... })

// Update washer
base44.entities.Washer.update(id, { status: 'active', ... })
```

---

## Security Features

1. **Admin Authentication**: All endpoints require admin token
2. **Data Validation**: Input validation for all fields
3. **Status Management**: Proper handling of status changes and user activation
4. **Email Verification**: Admin-created washers have verified emails by default
5. **Delete Protection**: Cannot delete washers with active bookings

---

## Error Responses

All endpoints return errors in the following format:

```json
{
  "success": false,
  "message": "Error message",
  "error": {
    "statusCode": 400,
    "status": "fail",
    "isOperational": true
  }
}
```

### Common Status Codes
- `200`: Success
- `201`: Created
- `400`: Bad Request (validation errors, invalid parameters)
- `401`: Unauthorized (missing or invalid token)
- `403`: Forbidden (insufficient permissions)
- `404`: Not Found (resource doesn't exist)
- `500`: Internal Server Error

---

## Differences from Washer App APIs

| Feature | Admin APIs | Washer App APIs |
|---------|-----------|-----------------|
| Base Route | `/admin/washers` | `/washer/*` |
| Authentication | Admin token | Washer token |
| Create Washer | ✅ Yes | ❌ No (via registration) |
| Update Any Field | ✅ Yes | ❌ Limited (own profile only) |
| Delete Washer | ✅ Yes | ❌ No |
| View All Washers | ✅ Yes | ❌ No (own data only) |
| Email Verification | Auto-verified on create | Requires OTP verification |
| Default Status | `active` | `pending` |


# Washer App APIs Documentation

## Overview
This document describes the screen-specific APIs created for the Washer mobile app. These APIs are separate from the Admin Panel APIs and follow a professional folder structure.

## API Structure

### Base URL
```
/api/v1/washer
```

### Authentication
All endpoints require authentication via Bearer token in the Authorization header:
```
Authorization: Bearer <access_token>
```

The token is obtained from `/washer/auth/login` or `/washer/auth/verify-email-otp`.

---

## 1. Home Screen APIs

### Base Route: `/washer/home`

#### GET `/washer/home/stats`
Get dashboard statistics for home screen.

**Response:**
```json
{
  "success": true,
  "data": {
    "today": {
      "jobs": 5,
      "earnings": 250.00
    },
    "total": {
      "jobs": 150,
      "earnings": 7500.00,
      "rating": 4.5
    },
    "online_status": true
  }
}
```

#### GET `/washer/home/stats/:period`
Get period-based statistics (today, week, month).

**Parameters:**
- `period` (path): `today`, `week`, or `month`

**Response:**
```json
{
  "success": true,
  "data": {
    "period": "today",
    "jobs": 5,
    "earnings": 250.00
  }
}
```

---

## 2. Jobs Screen APIs

### Base Route: `/washer/jobs`

#### GET `/washer/jobs`
Get all jobs for the washer with filters and pagination.

**Query Parameters:**
- `status` (optional): Filter by status (`pending`, `accepted`, `on_the_way`, `in_progress`, `completed`, `cancelled`)
- `page` (optional, default: 1): Page number
- `limit` (optional, default: 20): Items per page
- `sort` (optional, default: `-created_date`): Sort order

**Response:**
```json
{
  "success": true,
  "data": {
    "jobs": [
      {
        "_id": "...",
        "booking_id": "BK001",
        "customer_name": "John Doe",
        "service_name": "Premium Wash",
        "status": "pending",
        "total": 50.00,
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

#### GET `/washer/jobs/:id`
Get job details by ID.

**Response:**
```json
{
  "success": true,
  "data": {
    "_id": "...",
    "booking_id": "BK001",
    "customer_id": {...},
    "service_id": {...},
    "status": "pending",
    "total": 50.00,
    "address": "123 Main St",
    "timeline": [...]
  }
}
```

#### POST `/washer/jobs/:id/accept`
Accept a pending job.

**Response:**
```json
{
  "success": true,
  "data": {...},
  "message": "Job accepted successfully"
}
```

#### PUT `/washer/jobs/:id/status`
Update job status.

**Body:**
```json
{
  "status": "in_progress",
  "note": "Started washing"
}
```

**Valid Status Transitions:**
- `pending` → `accepted`, `cancelled`
- `accepted` → `on_the_way`, `cancelled`
- `on_the_way` → `in_progress`, `cancelled`
- `in_progress` → `completed`, `cancelled`

**Response:**
```json
{
  "success": true,
  "data": {...},
  "message": "Job status updated to in_progress"
}
```

#### POST `/washer/jobs/:id/complete`
Complete a job (convenience endpoint).

**Body:**
```json
{
  "note": "Job completed successfully"
}
```

**Response:**
```json
{
  "success": true,
  "data": {...},
  "message": "Job completed successfully"
}
```

---

## 3. Wallet Screen APIs

### Base Route: `/washer/wallet`

#### GET `/washer/wallet/balance`
Get wallet balance.

**Response:**
```json
{
  "success": true,
  "data": {
    "balance": 1250.00,
    "total_earnings": 7500.00
  }
}
```

#### GET `/washer/wallet/stats`
Get wallet statistics by period.

**Query Parameters:**
- `period` (optional, default: `today`): `today`, `week`, or `month`

**Response:**
```json
{
  "success": true,
  "data": {
    "period": "today",
    "balance": 1250.00,
    "earnings": 250.00,
    "jobs_completed": 5
  }
}
```

#### GET `/washer/wallet/transactions`
Get transaction history.

**Query Parameters:**
- `period` (optional, default: `all`): `today`, `week`, `month`, or `all`
- `page` (optional, default: 1): Page number
- `limit` (optional, default: 20): Items per page
- `sort` (optional, default: `-created_date`): Sort order

**Response:**
```json
{
  "success": true,
  "data": {
    "transactions": [
      {
        "id": "...",
        "booking_id": "BK001",
        "customer_name": "John Doe",
        "service_name": "Premium Wash",
        "amount": 50.00,
        "type": "earning",
        "payment_method": "cash",
        "date": "2024-01-15T10:00:00Z",
        "status": "completed"
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

#### POST `/washer/wallet/withdraw`
Request withdrawal.

**Body:**
```json
{
  "amount": 500.00
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "message": "Withdrawal request submitted successfully",
    "requested_amount": 500.00,
    "current_balance": 1250.00,
    "remaining_balance": 750.00
  }
}
```

---

## 4. Profile Screen APIs

### Base Route: `/washer/profile`

#### GET `/washer/profile`
Get washer profile with full details.

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "...",
      "name": "John Washer",
      "email": "john@example.com",
      "phone": "+1234567890",
      "email_verified": true,
      "phone_verified": false,
      "wallet_balance": 1250.00
    },
    "washer": {
      "id": "...",
      "name": "John Washer",
      "phone": "+1234567890",
      "email": "john@example.com",
      "status": "active",
      "online_status": true,
      "rating": 4.5,
      "total_jobs": 150,
      "completed_jobs": 145,
      "wallet_balance": 1250.00,
      "total_earnings": 7500.00
    }
  }
}
```

#### PUT `/washer/profile`
Update washer profile.

**Body:**
```json
{
  "name": "John Washer Updated",
  "phone": "+1234567890",
  "email": "john.updated@example.com"
}
```

**Response:**
```json
{
  "success": true,
  "data": {...},
  "message": "Profile updated successfully"
}
```

#### PUT `/washer/profile/online-status`
Toggle online status.

**Body:**
```json
{
  "online_status": true
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "online_status": true,
    "message": "You are now online"
  }
}
```

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
- `400`: Bad Request (validation errors, invalid parameters)
- `401`: Unauthorized (missing or invalid token)
- `403`: Forbidden (insufficient permissions, account suspended)
- `404`: Not Found (resource doesn't exist)
- `500`: Internal Server Error

---

## Security Features

1. **Authentication**: All endpoints require valid JWT token
2. **Authorization**: Token must belong to a washer with `active` status
3. **Input Validation**: All inputs are validated before processing
4. **Error Handling**: Consistent error responses with appropriate status codes
5. **Data Isolation**: Washers can only access their own data

---

## Folder Structure

```
backend/src/
├── services/
│   ├── washerHome.service.js      # Home screen business logic
│   ├── washerJobs.service.js       # Jobs screen business logic
│   ├── washerWallet.service.js     # Wallet screen business logic
│   └── washerProfile.service.js    # Profile screen business logic
├── controllers/
│   ├── washerHome.controller.js    # Home screen HTTP handlers
│   ├── washerJobs.controller.js    # Jobs screen HTTP handlers
│   ├── washerWallet.controller.js  # Wallet screen HTTP handlers
│   └── washerProfile.controller.js # Profile screen HTTP handlers
└── routes/
    ├── washerHome.routes.js         # Home screen routes
    ├── washerJobs.routes.js         # Jobs screen routes
    ├── washerWallet.routes.js       # Wallet screen routes
    └── washerProfile.routes.js      # Profile screen routes
```

---

## Integration Notes

### Flutter App Integration

1. **Home Screen**: Use `HomeService` to fetch dashboard stats
2. **Jobs Screen**: Use `JobsService` to manage jobs
3. **Wallet Screen**: Use `WalletService` for wallet operations
4. **Profile Screen**: Use `ProfileService` for profile management

All services are located in:
```
car_wash_app/lib/features/[screen]/services/[screen]_service.dart
```

Controllers are updated to use these services and fetch data from the APIs.

---

## Testing

Use the Postman collection `CarWashPro_API_Collection.postman_collection.json` to test all endpoints.

Make sure to:
1. First authenticate via `/washer/auth/login` or `/washer/auth/verify-email-otp`
2. Copy the `accessToken` from the response
3. Set it as a Bearer token in Postman's Authorization tab
4. Test the endpoints


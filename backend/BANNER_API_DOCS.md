# Banner API Documentation

## Admin Banner Endpoints

### 1. Get All Banners (Admin)
**GET** `/api/v1/admin/settings/banners`

**Auth:** ✅ Required (Admin)

**Query Parameters:**
- `sort` (optional): Sort order (default: `display_order`)
  - Values: `display_order`, `-display_order`, `created_date`, `-created_date`
- `limit` (optional): Maximum number of banners to return (default: 100)
- `is_active` (optional): Filter by active status (`true` or `false`)

**Success 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": "507f1f77bcf86cd799439011",
      "title": "Summer Sale",
      "subtitle": "Up to 30% off",
      "image_url": "http://localhost:3000/uploads/banners/banner-1234567890-image.jpg",
      "action_type": "coupon",
      "action_value": "SUMMER30",
      "display_order": 1,
      "start_date": "2024-01-01T00:00:00.000Z",
      "end_date": "2024-12-31T23:59:59.000Z",
      "is_active": true,
      "created_date": "2024-01-01T00:00:00.000Z",
      "updated_date": "2024-01-01T00:00:00.000Z"
    }
  ]
}
```

**Error 401:**
```json
{
  "success": false,
  "message": "Unauthorized"
}
```

---

### 2. Get Banner by ID (Admin)
**GET** `/api/v1/admin/settings/banners/:id`

**Auth:** ✅ Required (Admin)

**URL Parameters:**
- `id`: Banner ID (MongoDB ObjectId)

**Success 200:**
```json
{
  "success": true,
  "data": {
    "id": "507f1f77bcf86cd799439011",
    "title": "Summer Sale",
    "subtitle": "Up to 30% off",
    "image_url": "http://localhost:3000/uploads/banners/banner-1234567890-image.jpg",
    "action_type": "coupon",
    "action_value": "SUMMER30",
    "display_order": 1,
    "start_date": "2024-01-01T00:00:00.000Z",
    "end_date": "2024-12-31T23:59:59.000Z",
    "is_active": true,
    "created_date": "2024-01-01T00:00:00.000Z",
    "updated_date": "2024-01-01T00:00:00.000Z"
  }
}
```

**Error 404:**
```json
{
  "success": false,
  "message": "Banner not found"
}
```

---

### 3. Create Banner (Admin)
**POST** `/api/v1/admin/settings/banners`

**Auth:** ✅ Required (Admin)

**Content-Type:** `multipart/form-data` (for file upload) OR `application/json` (for URL only)

**Body (FormData - with image upload):**
```
title: "Summer Sale"
subtitle: "Up to 30% off"
image: [File] (optional - if provided, image_url will be ignored)
image_url: "https://example.com/image.jpg" (optional - if image file not provided)
action_type: "coupon"
action_value: "SUMMER30"
display_order: 1
start_date: "2024-01-01"
end_date: "2024-12-31"
is_active: true
```

**Body (JSON - URL only):**
```json
{
  "title": "Summer Sale",
  "subtitle": "Up to 30% off",
  "image_url": "https://example.com/image.jpg",
  "action_type": "coupon",
  "action_value": "SUMMER30",
  "display_order": 1,
  "start_date": "2024-01-01",
  "end_date": "2024-12-31",
  "is_active": true
}
```

**Field Descriptions:**
- `title` (required): Banner title (max 100 characters)
- `subtitle` (optional): Banner subtitle (max 200 characters)
- `image` (optional): Image file (JPEG, PNG, GIF, WebP - Max 5MB)
- `image_url` (optional): Image URL (required if `image` not provided)
- `action_type` (optional): Action type when banner is clicked
  - Values: `none`, `service`, `coupon`, `url` (default: `none`)
- `action_value` (optional): Value for the action (service ID, coupon code, or URL)
- `display_order` (optional): Display order for sorting (default: 0)
- `start_date` (optional): Start date for banner display (ISO date string)
- `end_date` (optional): End date for banner display (ISO date string)
- `is_active` (optional): Whether banner is active (default: `true`)

**Success 201:**
```json
{
  "success": true,
  "message": "Banner created successfully",
  "data": {
    "id": "507f1f77bcf86cd799439011",
    "title": "Summer Sale",
    "subtitle": "Up to 30% off",
    "image_url": "http://localhost:3000/uploads/banners/banner-1234567890-image.jpg",
    "action_type": "coupon",
    "action_value": "SUMMER30",
    "display_order": 1,
    "start_date": "2024-01-01T00:00:00.000Z",
    "end_date": "2024-12-31T23:59:59.000Z",
    "is_active": true,
    "created_date": "2024-01-01T00:00:00.000Z",
    "updated_date": "2024-01-01T00:00:00.000Z"
  }
}
```

**Error 400:**
```json
{
  "success": false,
  "message": "Title and image URL are required"
}
```

**Error 400 (Invalid file):**
```json
{
  "success": false,
  "message": "Only image files are allowed (jpeg, jpg, png, gif, webp)"
}
```

---

### 4. Update Banner (Admin)
**PUT** `/api/v1/admin/settings/banners/:id`

**Auth:** ✅ Required (Admin)

**Content-Type:** `multipart/form-data` (for file upload) OR `application/json` (for URL only)

**URL Parameters:**
- `id`: Banner ID (MongoDB ObjectId)

**Body (FormData - with image upload):**
```
title: "Updated Summer Sale"
subtitle: "Up to 40% off"
image: [File] (optional - if provided, image_url will be updated)
image_url: "https://example.com/new-image.jpg" (optional - if image file not provided)
action_type: "service"
action_value: "507f1f77bcf86cd799439012"
display_order: 2
start_date: "2024-06-01"
end_date: "2024-08-31"
is_active: true
```

**Body (JSON - URL only):**
```json
{
  "title": "Updated Summer Sale",
  "subtitle": "Up to 40% off",
  "image_url": "https://example.com/new-image.jpg",
  "action_type": "service",
  "action_value": "507f1f77bcf86cd799439012",
  "display_order": 2,
  "start_date": "2024-06-01",
  "end_date": "2024-08-31",
  "is_active": true
}
```

**Note:** All fields are optional. Only provided fields will be updated.

**Success 200:**
```json
{
  "success": true,
  "message": "Banner updated successfully",
  "data": {
    "id": "507f1f77bcf86cd799439011",
    "title": "Updated Summer Sale",
    "subtitle": "Up to 40% off",
    "image_url": "http://localhost:3000/uploads/banners/banner-1234567890-new-image.jpg",
    "action_type": "service",
    "action_value": "507f1f77bcf86cd799439012",
    "display_order": 2,
    "start_date": "2024-06-01T00:00:00.000Z",
    "end_date": "2024-08-31T23:59:59.000Z",
    "is_active": true,
    "created_date": "2024-01-01T00:00:00.000Z",
    "updated_date": "2024-06-01T00:00:00.000Z"
  }
}
```

**Error 404:**
```json
{
  "success": false,
  "message": "Banner not found"
}
```

**Error 400:**
```json
{
  "success": false,
  "message": "Start date must be before end date"
}
```

---

### 5. Delete Banner (Admin)
**DELETE** `/api/v1/admin/settings/banners/:id`

**Auth:** ✅ Required (Admin)

**URL Parameters:**
- `id`: Banner ID (MongoDB ObjectId)

**Success 200:**
```json
{
  "success": true,
  "message": "Banner deleted successfully"
}
```

**Error 404:**
```json
{
  "success": false,
  "message": "Banner not found"
}
```

---

## Customer Banner Endpoints

### 6. Get Active Banners (Public)
**GET** `/api/v1/customer/banners`

**Auth:** ❌ Not Required (Public)

**Description:** Returns all active banners that are currently within their display date range (if set).

**Success 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": "507f1f77bcf86cd799439011",
      "title": "Summer Sale",
      "subtitle": "Up to 30% off",
      "image_url": "http://localhost:3000/uploads/banners/banner-1234567890-image.jpg",
      "action_type": "coupon",
      "action_value": "SUMMER30"
    },
    {
      "id": "507f1f77bcf86cd799439012",
      "title": "New Service Available",
      "subtitle": "Try our premium wash",
      "image_url": "http://localhost:3000/uploads/banners/banner-1234567891-service.jpg",
      "action_type": "service",
      "action_value": "507f1f77bcf86cd799439013"
    }
  ]
}
```

**Note:** Only returns banners where:
- `is_active` is `true`
- Current date is between `start_date` and `end_date` (if dates are set)
- Sorted by `display_order` ascending

---

## Action Types

### `none`
No action when banner is clicked.

### `service`
Navigate to a specific service.
- `action_value`: Service ID

### `coupon`
Apply a coupon code.
- `action_value`: Coupon code

### `url`
Open an external URL.
- `action_value`: Full URL (e.g., `https://example.com`)

---

## Image Upload

### Supported Formats
- JPEG (.jpg, .jpeg)
- PNG (.png)
- GIF (.gif)
- WebP (.webp)

### File Size Limit
- Maximum: 5MB

### Storage Location
- Uploaded images are stored in: `backend/uploads/banners/`
- Accessible via: `http://your-domain/uploads/banners/filename.jpg`

### Image URL Format
When uploading a file, the API returns a relative URL:
```
/uploads/banners/banner-1234567890-image.jpg
```

The full URL will be:
```
http://your-domain/uploads/banners/banner-1234567890-image.jpg
```

---

## Examples

### Example 1: Create Banner with Image Upload (cURL)
```bash
curl -X POST http://localhost:3000/api/v1/admin/settings/banners \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -F "title=Summer Sale" \
  -F "subtitle=Up to 30% off" \
  -F "image=@/path/to/image.jpg" \
  -F "action_type=coupon" \
  -F "action_value=SUMMER30" \
  -F "display_order=1" \
  -F "is_active=true"
```

### Example 2: Create Banner with Image URL (cURL)
```bash
curl -X POST http://localhost:3000/api/v1/admin/settings/banners \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Summer Sale",
    "subtitle": "Up to 30% off",
    "image_url": "https://example.com/banner.jpg",
    "action_type": "coupon",
    "action_value": "SUMMER30",
    "display_order": 1,
    "is_active": true
  }'
```

### Example 3: Update Banner (cURL)
```bash
curl -X PUT http://localhost:3000/api/v1/admin/settings/banners/507f1f77bcf86cd799439011 \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Updated Title",
    "is_active": false
  }'
```

### Example 4: Get Active Banners (cURL)
```bash
curl -X GET http://localhost:3000/api/v1/customer/banners
```

### Example 5: Delete Banner (cURL)
```bash
curl -X DELETE http://localhost:3000/api/v1/admin/settings/banners/507f1f77bcf86cd799439011 \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

---

## Error Codes

| Status Code | Description |
|------------|-------------|
| 200 | Success |
| 201 | Created successfully |
| 400 | Bad Request (validation error, invalid file, etc.) |
| 401 | Unauthorized (missing or invalid token) |
| 404 | Banner not found |
| 500 | Internal server error |

---

## Notes

1. **Image Upload vs URL**: You can either upload an image file OR provide an image URL. If both are provided, the uploaded file takes precedence.

2. **Date Filtering**: Banners with `start_date` and `end_date` will only be shown to customers if the current date falls within that range.

3. **Display Order**: Lower numbers appear first. Banners are sorted by `display_order` ascending.

4. **Active Status**: Only banners with `is_active: true` are returned in the customer endpoint.

5. **Image URLs**: All image URLs returned by the API are absolute URLs (include the full domain). Relative paths are converted to absolute URLs automatically.

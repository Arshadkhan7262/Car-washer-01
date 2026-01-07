{
  "name": "AdminUser",
  "type": "object",
  "properties": {
    "name": {
      "type": "string"
    },
    "email": {
      "type": "string"
    },
    "phone": {
      "type": "string"
    },
    "avatar": {
      "type": "string"
    },
    "role": {
      "type": "string",
      "enum": [
        "super_admin",
        "business_admin",
        "branch_manager",
        "support_staff"
      ],
      "default": "support_staff"
    },
    "branch_id": {
      "type": "string"
    },
    "branch_name": {
      "type": "string"
    },
    "permissions": {
      "type": "object",
      "properties": {
        "dashboard": {
          "type": "boolean"
        },
        "bookings": {
          "type": "boolean"
        },
        "customers": {
          "type": "boolean"
        },
        "washers": {
          "type": "boolean"
        },
        "services": {
          "type": "boolean"
        },
        "pricing": {
          "type": "boolean"
        },
        "schedule": {
          "type": "boolean"
        },
        "payments": {
          "type": "boolean"
        },
        "reviews": {
          "type": "boolean"
        },
        "support": {
          "type": "boolean"
        },
        "content": {
          "type": "boolean"
        },
        "settings": {
          "type": "boolean"
        },
        "reports": {
          "type": "boolean"
        }
      }
    },
    "is_active": {
      "type": "boolean",
      "default": true
    },
    "last_login": {
      "type": "string",
      "format": "date-time"
    }
  },
  "required": [
    "name",
    "email",
    "role"
  ]
}
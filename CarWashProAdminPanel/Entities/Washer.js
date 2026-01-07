{
  "name": "Washer",
  "type": "object",
  "properties": {
    "name": {
      "type": "string"
    },
    "phone": {
      "type": "string"
    },
    "email": {
      "type": "string"
    },
    "avatar": {
      "type": "string"
    },
    "status": {
      "type": "string",
      "enum": [
        "pending",
        "active",
        "suspended"
      ],
      "default": "pending"
    },
    "online_status": {
      "type": "boolean",
      "default": false
    },
    "branch_id": {
      "type": "string"
    },
    "branch_name": {
      "type": "string"
    },
    "rating": {
      "type": "number",
      "default": 0
    },
    "total_ratings": {
      "type": "number",
      "default": 0
    },
    "jobs_completed": {
      "type": "number",
      "default": 0
    },
    "jobs_cancelled": {
      "type": "number",
      "default": 0
    },
    "wallet_balance": {
      "type": "number",
      "default": 0
    },
    "total_earnings": {
      "type": "number",
      "default": 0
    },
    "documents": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "type": {
            "type": "string"
          },
          "url": {
            "type": "string"
          },
          "verified": {
            "type": "boolean"
          }
        }
      }
    },
    "approval_note": {
      "type": "string"
    },
    "rejection_reason": {
      "type": "string"
    }
  },
  "required": [
    "name",
    "phone"
  ]
}
{
  "name": "Customer",
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
        "active",
        "blocked"
      ],
      "default": "active"
    },
    "addresses": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "label": {
            "type": "string"
          },
          "address": {
            "type": "string"
          },
          "latitude": {
            "type": "number"
          },
          "longitude": {
            "type": "number"
          }
        }
      }
    },
    "vehicles": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "type": {
            "type": "string"
          },
          "make": {
            "type": "string"
          },
          "model": {
            "type": "string"
          },
          "color": {
            "type": "string"
          },
          "plate": {
            "type": "string"
          }
        }
      }
    },
    "total_bookings": {
      "type": "number",
      "default": 0
    },
    "total_spent": {
      "type": "number",
      "default": 0
    },
    "last_booking_date": {
      "type": "string",
      "format": "date"
    },
    "admin_notes": {
      "type": "string"
    },
    "wallet_balance": {
      "type": "number",
      "default": 0
    }
  },
  "required": [
    "name",
    "phone"
  ]
}
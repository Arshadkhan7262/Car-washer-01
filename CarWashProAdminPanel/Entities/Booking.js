{
  "name": "Booking",
  "type": "object",
  "properties": {
    "booking_id": {
      "type": "string",
      "description": "Unique booking reference"
    },
    "customer_id": {
      "type": "string",
      "description": "Reference to customer"
    },
    "customer_name": {
      "type": "string"
    },
    "customer_phone": {
      "type": "string"
    },
    "customer_email": {
      "type": "string"
    },
    "vehicle_type": {
      "type": "string",
      "enum": [
        "sedan",
        "suv",
        "truck",
        "van",
        "motorcycle",
        "luxury"
      ]
    },
    "vehicle_make": {
      "type": "string"
    },
    "vehicle_model": {
      "type": "string"
    },
    "vehicle_color": {
      "type": "string"
    },
    "vehicle_plate": {
      "type": "string"
    },
    "service_id": {
      "type": "string"
    },
    "service_name": {
      "type": "string"
    },
    "addons": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "name": {
            "type": "string"
          },
          "price": {
            "type": "number"
          }
        }
      }
    },
    "booking_date": {
      "type": "string",
      "format": "date"
    },
    "time_slot": {
      "type": "string"
    },
    "location_type": {
      "type": "string",
      "enum": [
        "home",
        "branch"
      ]
    },
    "address": {
      "type": "string"
    },
    "branch_id": {
      "type": "string"
    },
    "branch_name": {
      "type": "string"
    },
    "latitude": {
      "type": "number"
    },
    "longitude": {
      "type": "number"
    },
    "customer_notes": {
      "type": "string"
    },
    "status": {
      "type": "string",
      "enum": [
        "pending",
        "accepted",
        "on_the_way",
        "in_progress",
        "completed",
        "cancelled"
      ],
      "default": "pending"
    },
    "payment_status": {
      "type": "string",
      "enum": [
        "unpaid",
        "paid",
        "refunded",
        "partial"
      ],
      "default": "unpaid"
    },
    "payment_method": {
      "type": "string",
      "enum": [
        "cash",
        "card",
        "apple_pay",
        "google_pay",
        "wallet"
      ]
    },
    "subtotal": {
      "type": "number"
    },
    "tax": {
      "type": "number"
    },
    "discount": {
      "type": "number",
      "default": 0
    },
    "coupon_code": {
      "type": "string"
    },
    "total": {
      "type": "number"
    },
    "washer_id": {
      "type": "string"
    },
    "washer_name": {
      "type": "string"
    },
    "cancel_reason": {
      "type": "string"
    },
    "before_photos": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "after_photos": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "timeline": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "status": {
            "type": "string"
          },
          "timestamp": {
            "type": "string"
          },
          "note": {
            "type": "string"
          }
        }
      }
    }
  },
  "required": [
    "customer_name",
    "service_name",
    "booking_date"
  ]
}
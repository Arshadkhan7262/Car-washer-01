{
  "name": "Review",
  "type": "object",
  "properties": {
    "booking_id": {
      "type": "string"
    },
    "customer_id": {
      "type": "string"
    },
    "customer_name": {
      "type": "string"
    },
    "washer_id": {
      "type": "string"
    },
    "washer_name": {
      "type": "string"
    },
    "service_name": {
      "type": "string"
    },
    "rating": {
      "type": "number"
    },
    "comment": {
      "type": "string"
    },
    "admin_response": {
      "type": "string"
    },
    "is_flagged": {
      "type": "boolean",
      "default": false
    },
    "flag_reason": {
      "type": "string"
    }
  },
  "required": [
    "booking_id",
    "rating"
  ]
}
{
  "name": "Coupon",
  "type": "object",
  "properties": {
    "code": {
      "type": "string"
    },
    "description": {
      "type": "string"
    },
    "discount_type": {
      "type": "string",
      "enum": [
        "percentage",
        "fixed"
      ]
    },
    "discount_value": {
      "type": "number"
    },
    "min_order_value": {
      "type": "number",
      "default": 0
    },
    "max_discount": {
      "type": "number"
    },
    "expiry_date": {
      "type": "string",
      "format": "date"
    },
    "usage_limit": {
      "type": "number"
    },
    "times_used": {
      "type": "number",
      "default": 0
    },
    "eligible_services": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "is_active": {
      "type": "boolean",
      "default": true
    }
  },
  "required": [
    "code",
    "discount_type",
    "discount_value"
  ]
}
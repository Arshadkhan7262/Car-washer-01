{
  "name": "BusinessSettings",
  "type": "object",
  "properties": {
    "business_name": {
      "type": "string"
    },
    "logo_url": {
      "type": "string"
    },
    "contact_email": {
      "type": "string"
    },
    "contact_phone": {
      "type": "string"
    },
    "address": {
      "type": "string"
    },
    "tax_rate": {
      "type": "number",
      "default": 0
    },
    "service_fee": {
      "type": "number",
      "default": 0
    },
    "currency": {
      "type": "string",
      "default": "USD"
    },
    "currency_symbol": {
      "type": "string",
      "default": "$"
    },
    "cancellation_policy": {
      "type": "string"
    },
    "cancellation_fee_percentage": {
      "type": "number",
      "default": 0
    },
    "free_cancellation_hours": {
      "type": "number",
      "default": 24
    },
    "terms_content": {
      "type": "string"
    },
    "privacy_content": {
      "type": "string"
    },
    "about_content": {
      "type": "string"
    },
    "faq_content": {
      "type": "string"
    }
  },
  "required": [
    "business_name"
  ]
}
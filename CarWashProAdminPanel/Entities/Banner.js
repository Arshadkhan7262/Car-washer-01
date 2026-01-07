{
  "name": "Banner",
  "type": "object",
  "properties": {
    "title": {
      "type": "string"
    },
    "subtitle": {
      "type": "string"
    },
    "image_url": {
      "type": "string"
    },
    "action_type": {
      "type": "string",
      "enum": [
        "none",
        "service",
        "coupon",
        "url"
      ]
    },
    "action_value": {
      "type": "string"
    },
    "display_order": {
      "type": "number",
      "default": 0
    },
    "start_date": {
      "type": "string",
      "format": "date"
    },
    "end_date": {
      "type": "string",
      "format": "date"
    },
    "is_active": {
      "type": "boolean",
      "default": true
    }
  },
  "required": [
    "title",
    "image_url"
  ]
}
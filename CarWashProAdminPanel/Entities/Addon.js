{
  "name": "Addon",
  "type": "object",
  "properties": {
    "name": {
      "type": "string"
    },
    "description": {
      "type": "string"
    },
    "price": {
      "type": "number"
    },
    "duration_minutes": {
      "type": "number"
    },
    "icon": {
      "type": "string"
    },
    "is_active": {
      "type": "boolean",
      "default": true
    },
    "compatible_services": {
      "type": "array",
      "items": {
        "type": "string"
      }
    }
  },
  "required": [
    "name",
    "price"
  ]
}
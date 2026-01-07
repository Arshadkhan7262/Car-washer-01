{
  "name": "Service",
  "type": "object",
  "properties": {
    "name": {
      "type": "string"
    },
    "description": {
      "type": "string"
    },
    "short_description": {
      "type": "string"
    },
    "icon": {
      "type": "string"
    },
    "image": {
      "type": "string"
    },
    "duration_minutes": {
      "type": "number"
    },
    "base_price": {
      "type": "number"
    },
    "pricing": {
      "type": "object",
      "properties": {
        "sedan": {
          "type": "number"
        },
        "suv": {
          "type": "number"
        },
        "truck": {
          "type": "number"
        },
        "van": {
          "type": "number"
        },
        "motorcycle": {
          "type": "number"
        },
        "luxury": {
          "type": "number"
        }
      }
    },
    "includes": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "is_popular": {
      "type": "boolean",
      "default": false
    },
    "is_active": {
      "type": "boolean",
      "default": true
    },
    "display_order": {
      "type": "number",
      "default": 0
    }
  },
  "required": [
    "name",
    "base_price"
  ]
}
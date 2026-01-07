{
  "name": "Branch",
  "type": "object",
  "properties": {
    "name": {
      "type": "string"
    },
    "address": {
      "type": "string"
    },
    "phone": {
      "type": "string"
    },
    "email": {
      "type": "string"
    },
    "latitude": {
      "type": "number"
    },
    "longitude": {
      "type": "number"
    },
    "working_hours": {
      "type": "object",
      "properties": {
        "monday": {
          "type": "object",
          "properties": {
            "open": {
              "type": "string"
            },
            "close": {
              "type": "string"
            },
            "closed": {
              "type": "boolean"
            }
          }
        },
        "tuesday": {
          "type": "object",
          "properties": {
            "open": {
              "type": "string"
            },
            "close": {
              "type": "string"
            },
            "closed": {
              "type": "boolean"
            }
          }
        },
        "wednesday": {
          "type": "object",
          "properties": {
            "open": {
              "type": "string"
            },
            "close": {
              "type": "string"
            },
            "closed": {
              "type": "boolean"
            }
          }
        },
        "thursday": {
          "type": "object",
          "properties": {
            "open": {
              "type": "string"
            },
            "close": {
              "type": "string"
            },
            "closed": {
              "type": "boolean"
            }
          }
        },
        "friday": {
          "type": "object",
          "properties": {
            "open": {
              "type": "string"
            },
            "close": {
              "type": "string"
            },
            "closed": {
              "type": "boolean"
            }
          }
        },
        "saturday": {
          "type": "object",
          "properties": {
            "open": {
              "type": "string"
            },
            "close": {
              "type": "string"
            },
            "closed": {
              "type": "boolean"
            }
          }
        },
        "sunday": {
          "type": "object",
          "properties": {
            "open": {
              "type": "string"
            },
            "close": {
              "type": "string"
            },
            "closed": {
              "type": "boolean"
            }
          }
        }
      }
    },
    "service_radius_km": {
      "type": "number"
    },
    "slot_duration_minutes": {
      "type": "number",
      "default": 60
    },
    "slots_per_hour": {
      "type": "number",
      "default": 2
    },
    "is_active": {
      "type": "boolean",
      "default": true
    }
  },
  "required": [
    "name",
    "address"
  ]
}
{
  "name": "SupportTicket",
  "type": "object",
  "properties": {
    "ticket_number": {
      "type": "string"
    },
    "customer_id": {
      "type": "string"
    },
    "customer_name": {
      "type": "string"
    },
    "customer_email": {
      "type": "string"
    },
    "booking_id": {
      "type": "string"
    },
    "category": {
      "type": "string",
      "enum": [
        "payment",
        "booking",
        "service_quality",
        "refund",
        "app_issue",
        "other"
      ]
    },
    "priority": {
      "type": "string",
      "enum": [
        "low",
        "medium",
        "high",
        "urgent"
      ],
      "default": "medium"
    },
    "status": {
      "type": "string",
      "enum": [
        "open",
        "in_progress",
        "resolved",
        "closed"
      ],
      "default": "open"
    },
    "subject": {
      "type": "string"
    },
    "messages": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "sender": {
            "type": "string"
          },
          "sender_type": {
            "type": "string"
          },
          "message": {
            "type": "string"
          },
          "timestamp": {
            "type": "string"
          },
          "attachments": {
            "type": "array",
            "items": {
              "type": "string"
            }
          }
        }
      }
    },
    "internal_notes": {
      "type": "string"
    },
    "assigned_to": {
      "type": "string"
    }
  },
  "required": [
    "customer_name",
    "category",
    "subject"
  ]
}
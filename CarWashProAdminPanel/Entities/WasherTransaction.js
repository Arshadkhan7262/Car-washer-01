{
  "name": "WasherTransaction",
  "type": "object",
  "properties": {
    "washer_id": {
      "type": "string"
    },
    "washer_name": {
      "type": "string"
    },
    "type": {
      "type": "string",
      "enum": [
        "earning",
        "withdrawal",
        "bonus",
        "deduction"
      ]
    },
    "amount": {
      "type": "number"
    },
    "booking_id": {
      "type": "string"
    },
    "status": {
      "type": "string",
      "enum": [
        "pending",
        "approved",
        "rejected",
        "completed"
      ],
      "default": "completed"
    },
    "notes": {
      "type": "string"
    },
    "bank_details": {
      "type": "string"
    }
  },
  "required": [
    "washer_id",
    "type",
    "amount"
  ]
}
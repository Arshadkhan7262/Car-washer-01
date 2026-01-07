{
  "name": "Payment",
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
    "amount": {
      "type": "number"
    },
    "method": {
      "type": "string",
      "enum": [
        "cash",
        "card",
        "apple_pay",
        "google_pay",
        "wallet"
      ]
    },
    "status": {
      "type": "string",
      "enum": [
        "pending",
        "completed",
        "failed",
        "refunded"
      ],
      "default": "pending"
    },
    "transaction_id": {
      "type": "string"
    },
    "gateway_response": {
      "type": "string"
    },
    "refund_reason": {
      "type": "string"
    },
    "refund_amount": {
      "type": "number"
    }
  },
  "required": [
    "booking_id",
    "amount"
  ]
}
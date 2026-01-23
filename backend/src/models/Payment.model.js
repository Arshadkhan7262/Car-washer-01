import mongoose from 'mongoose';

const paymentSchema = new mongoose.Schema({
  // Stripe Payment Intent ID
  stripePaymentIntentId: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },
  // Stripe Customer ID
  stripeCustomerId: {
    type: String,
    required: true,
    trim: true
  },
  // Booking reference
  booking_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Booking',
    required: true
  },
  booking_reference: {
    type: String, // Human-readable booking ID (e.g., "CW-2026-1234")
    trim: true
  },
  // Customer information
  customer_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  customer_name: {
    type: String,
    required: true,
    trim: true
  },
  customer_email: {
    type: String,
    trim: true
  },
  // Washer information (if assigned)
  washer_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Washer',
    default: null
  },
  washer_name: {
    type: String,
    default: null,
    trim: true
  },
  // Payment details
  amount: {
    type: Number,
    required: true,
    min: 0
  },
  currency: {
    type: String,
    default: 'usd',
    uppercase: true
  },
  payment_method: {
    type: String,
    enum: ['card', 'wallet', 'apple_pay', 'google_pay', 'cash'],
    default: 'card'
  },
  // Payment status
  status: {
    type: String,
    enum: ['pending', 'processing', 'succeeded', 'failed', 'canceled', 'refunded', 'partially_refunded'],
    default: 'pending'
  },
  // Stripe charge ID (after payment succeeds)
  stripeChargeId: {
    type: String,
    trim: true,
    sparse: true
  },
  // Refund information
  refund_amount: {
    type: Number,
    default: 0,
    min: 0
  },
  refund_reason: {
    type: String,
    trim: true
  },
  refunded_at: {
    type: Date,
    default: null
  },
  // Metadata
  metadata: {
    type: Map,
    of: String,
    default: {}
  },
  // Error information (if payment fails)
  error_message: {
    type: String,
    trim: true
  },
  // Timestamps
  created_date: {
    type: Date,
    default: Date.now
  },
  updated_date: {
    type: Date,
    default: Date.now
  },
  paid_at: {
    type: Date,
    default: null
  }
}, {
  timestamps: { createdAt: 'created_date', updatedAt: 'updated_date' }
});

// Indexes for faster queries
paymentSchema.index({ customer_id: 1, created_date: -1 });
paymentSchema.index({ washer_id: 1, created_date: -1 });
paymentSchema.index({ booking_id: 1 });
paymentSchema.index({ stripePaymentIntentId: 1 });
paymentSchema.index({ stripeCustomerId: 1 });
paymentSchema.index({ status: 1 });
paymentSchema.index({ created_date: -1 });

const Payment = mongoose.model('Payment', paymentSchema);

export default Payment;

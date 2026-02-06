import mongoose from 'mongoose';

const withdrawalSchema = new mongoose.Schema({
  washer_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Washer',
    required: true
  },
  user_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  amount: {
    type: Number,
    required: [true, 'Withdrawal amount is required'],
    min: [0.01, 'Amount must be greater than 0']
  },
  currency: {
    type: String,
    default: 'usd',
    uppercase: true
  },
  status: {
    type: String,
    enum: ['pending', 'approved', 'processing', 'completed', 'rejected', 'cancelled'],
    default: 'pending'
  },
  payment_method: {
    type: String,
    enum: ['stripe', 'bank_transfer', 'paypal'],
    default: 'stripe'
  },
  stripe_payout_id: {
    type: String,
    default: null
  },
  stripe_transfer_id: {
    type: String,
    default: null
  },
  // Bank account details for manual processing (if needed)
  metadata: {
    type: Map,
    of: String,
    default: {}
  },
  admin_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'AdminUser',
    default: null
  },
  admin_note: {
    type: String,
    default: null,
    trim: true
  },
  rejection_reason: {
    type: String,
    default: null,
    trim: true
  },
  requested_date: {
    type: Date,
    default: Date.now
  },
  approved_date: {
    type: Date,
    default: null
  },
  processed_date: {
    type: Date,
    default: null
  },
  completed_date: {
    type: Date,
    default: null
  }
}, {
  timestamps: { createdAt: 'created_date', updatedAt: 'updated_date' }
});

// Indexes for faster queries
withdrawalSchema.index({ washer_id: 1, status: 1 });
withdrawalSchema.index({ user_id: 1, status: 1 });
withdrawalSchema.index({ status: 1, requested_date: -1 });
withdrawalSchema.index({ created_date: -1 });

const Withdrawal = mongoose.model('Withdrawal', withdrawalSchema);

export default Withdrawal;

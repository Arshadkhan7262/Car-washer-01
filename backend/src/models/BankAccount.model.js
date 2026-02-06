import mongoose from 'mongoose';

const bankAccountSchema = new mongoose.Schema({
  washer_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Washer',
    required: true,
    unique: true
  },
  user_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  // Account holder name
  account_holder_name: {
    type: String,
    required: [true, 'Account holder name is required'],
    trim: true
  },
  // Bank account number (last 4 digits stored, full number encrypted)
  account_number: {
    type: String,
    required: [true, 'Account number is required'],
    trim: true
  },
  // Last 4 digits for display
  account_number_last4: {
    type: String,
    required: true,
    length: 4
  },
  // Routing number
  routing_number: {
    type: String,
    required: [true, 'Routing number is required'],
    trim: true,
    length: 9
  },
  // Account type
  account_type: {
    type: String,
    enum: ['checking', 'savings'],
    required: [true, 'Account type is required']
  },
  // Bank name
  bank_name: {
    type: String,
    trim: true
  },
  // Stripe bank account token (for ACH transfers)
  stripe_bank_account_token: {
    type: String,
    default: null,
    trim: true
  },
  // Stripe bank account ID (if using Stripe)
  stripe_bank_account_id: {
    type: String,
    default: null,
    trim: true
  },
  // Verification status
  is_verified: {
    type: Boolean,
    default: false
  },
  // Is this the default account
  is_default: {
    type: Boolean,
    default: true
  },
  // Status
  status: {
    type: String,
    enum: ['pending', 'verified', 'failed', 'disabled'],
    default: 'pending'
  },
  created_date: {
    type: Date,
    default: Date.now
  },
  updated_date: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: { createdAt: 'created_date', updatedAt: 'updated_date' }
});

// Indexes
bankAccountSchema.index({ washer_id: 1 });
bankAccountSchema.index({ user_id: 1 });
bankAccountSchema.index({ status: 1 });

const BankAccount = mongoose.model('BankAccount', bankAccountSchema);

export default BankAccount;

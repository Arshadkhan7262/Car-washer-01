import mongoose from 'mongoose';

const washerSchema = new mongoose.Schema({
  user_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  phone: {
    type: String,
    required: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    lowercase: true,
    trim: true
  },
  status: {
    type: String,
    enum: ['pending', 'active', 'suspended'],
    default: 'pending'
  },
  online_status: {
    type: Boolean,
    default: false
  },
  rating: {
    type: Number,
    default: 0
  },
  total_jobs: {
    type: Number,
    default: 0
  },
  completed_jobs: {
    type: Number,
    default: 0
  },
  wallet_balance: {
    type: Number,
    default: 0
  },
  total_earnings: {
    type: Number,
    default: 0
  },
  stripe_account_id: {
    type: String
  },
  stripe_account_status: {
    type: String,
    enum: ['none', 'pending', 'restricted', 'enabled'],
    default: 'none'
  },
  stripe_account_onboarding_complete: {
    type: Boolean,
    default: false
  },
  branch_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Branch'
  },
  branch_name: {
    type: String
  },
  current_location: {
    latitude: Number,
    longitude: Number,
    last_updated: Date,
    heading: Number,
    speed: Number
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
  timestamps: true
});

// Indexes
washerSchema.index({ user_id: 1 });
washerSchema.index({ status: 1 });
washerSchema.index({ email: 1 });
washerSchema.index({ phone: 1 });

const Washer = mongoose.models.Washer || mongoose.model('Washer', washerSchema);

export default Washer;

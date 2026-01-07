import mongoose from 'mongoose';

const addressSchema = new mongoose.Schema({
  customer_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  label: {
    type: String,
    enum: ['home', 'office', 'other'],
    default: 'other'
  },
  address_line: {
    type: String,
    required: true,
    trim: true
  },
  city: {
    type: String,
    trim: true
  },
  state: {
    type: String,
    trim: true
  },
  zip_code: {
    type: String,
    trim: true
  },
  country: {
    type: String,
    trim: true,
    default: 'USA'
  },
  latitude: {
    type: Number
  },
  longitude: {
    type: Number
  },
  is_default: {
    type: Boolean,
    default: false
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

// Index for faster queries
addressSchema.index({ customer_id: 1 });
addressSchema.index({ customer_id: 1, is_default: 1 });

const Address = mongoose.model('Address', addressSchema);

export default Address;




import mongoose from 'mongoose';

const serviceSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Service name is required'],
    trim: true
  },
  description: {
    type: String,
    trim: true
  },
  short_description: {
    type: String,
    trim: true
  },
  duration_minutes: {
    type: Number,
    required: true,
    default: 60
  },
  base_price: {
    type: Number,
    required: true,
    default: 0
  },
  pricing: {
    type: Map,
    of: Number,
    default: {}
  },
  includes: [{
    type: String
  }],
  is_popular: {
    type: Boolean,
    default: false
  },
  is_active: {
    type: Boolean,
    default: true
  },
  display_order: {
    type: Number,
    default: 0
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
serviceSchema.index({ is_active: 1, display_order: 1 });
serviceSchema.index({ is_popular: 1 });

const Service = mongoose.model('Service', serviceSchema);

export default Service;




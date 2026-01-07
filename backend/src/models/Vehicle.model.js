import mongoose from 'mongoose';

const vehicleSchema = new mongoose.Schema({
  customer_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  type: {
    type: String,
    enum: ['sedan', 'suv', 'truck', 'van', 'motorcycle', 'luxury'],
    required: true
  },
  brand: {
    type: String,
    trim: true
  },
  model: {
    type: String,
    trim: true
  },
  plate_number: {
    type: String,
    trim: true
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
vehicleSchema.index({ customer_id: 1 });
vehicleSchema.index({ customer_id: 1, is_default: 1 });

const Vehicle = mongoose.model('Vehicle', vehicleSchema);

export default Vehicle;




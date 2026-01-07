import mongoose from 'mongoose';

const vehicleTypeSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Vehicle type name is required'],
    trim: true,
    unique: true
  },
  display_name: {
    type: String,
    required: [true, 'Display name is required'],
    trim: true
  },
  image_url: {
    type: String,
    trim: true,
    default: ''
  },
  icon_path: {
    type: String,
    trim: true,
    default: ''
  },
  display_order: {
    type: Number,
    default: 0
  },
  is_active: {
    type: Boolean,
    default: true
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
vehicleTypeSchema.index({ is_active: 1, display_order: 1 });
vehicleTypeSchema.index({ name: 1 });

const VehicleType = mongoose.model('VehicleType', vehicleTypeSchema);

export default VehicleType;


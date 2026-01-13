/* DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
import mongoose from 'mongoose';

const draftBookingSchema = new mongoose.Schema({
  customer_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  step: {
    type: Number,
    required: true,
    min: 1,
    max: 4
  },
  service_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Service'
  },
  vehicle_type_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'VehicleType'
  },
  vehicle_type_name: {
    type: String,
    trim: true
  },
  selected_date: {
    type: Date
  },
  selected_time: {
    type: String,
    trim: true
  },
  address: {
    type: String,
    trim: true
  },
  additional_location: {
    type: String,
    trim: true
  },
  payment_method: {
    type: String,
    enum: ['cash', 'card', 'wallet', 'apple_pay', 'google_pay'],
    trim: true
  },
  coupon_code: {
    type: String,
    trim: true
  },
  expires_at: {
    type: Date,
    default: () => new Date(Date.now() + 24 * 60 * 60 * 1000) // 24 hours from now
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
draftBookingSchema.index({ customer_id: 1 });
draftBookingSchema.index({ expires_at: 1 });

// Auto-delete expired drafts
draftBookingSchema.index({ expires_at: 1 }, { expireAfterSeconds: 0 });

const DraftBooking = mongoose.model('DraftBooking', draftBookingSchema);

export default DraftBooking;
*/

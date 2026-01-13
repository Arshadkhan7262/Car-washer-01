import mongoose from 'mongoose';

const bookingSchema = new mongoose.Schema({
  booking_id: {
    type: String,
    unique: true,
    required: true,
    trim: true
  },
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
  customer_phone: {
    type: String,
    required: true,
    trim: true
  },
  service_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Service',
    required: true
  },
  service_name: {
    type: String,
    required: true,
    trim: true
  },
  vehicle_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Vehicle'
  },
  vehicle_type: {
    type: String,
    enum: ['sedan', 'suv', 'truck', 'van', 'motorcycle', 'luxury'],
    required: true
  },
  booking_date: {
    type: Date,
    required: true
  },
  time_slot: {
    type: String,
    required: true
  },
  address: {
    type: String,
    required: true
  },
  address_latitude: {
    type: Number,
    default: null
  },
  address_longitude: {
    type: Number,
    default: null
  },
  additional_location: {
    type: String,
    trim: true
  },
  status: {
    type: String,
    enum: ['pending', 'accepted', 'on_the_way', 'arrived', 'in_progress', 'completed', 'cancelled'],
    default: 'pending'
  },
  payment_status: {
    type: String,
    enum: ['unpaid', 'paid', 'refunded'],
    default: 'unpaid'
  },
  payment_method: {
    type: String,
    enum: ['cash', 'card', 'wallet', 'apple_pay', 'google_pay'],
    default: 'cash'
  },
  total: {
    type: Number,
    required: true,
    default: 0
  },
  washer_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Washer',
    default: null
  },
  washer_name: {
    type: String,
    default: null
  },
  created_date: {
    type: Date,
    default: Date.now
  },
  updated_date: {
    type: Date,
    default: Date.now
  },
  timeline: [{
    status: String,
    timestamp: Date,
    note: String
  }]
}, {
  timestamps: { createdAt: 'created_date', updatedAt: 'updated_date' }
});

// Index for faster queries
bookingSchema.index({ customer_id: 1, created_date: -1 });
bookingSchema.index({ washer_id: 1, status: 1 });
bookingSchema.index({ booking_date: 1, status: 1 });
bookingSchema.index({ status: 1 });

const Booking = mongoose.model('Booking', bookingSchema);

export default Booking;




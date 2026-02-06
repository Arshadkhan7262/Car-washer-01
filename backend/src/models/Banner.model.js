import mongoose from 'mongoose';

const bannerSchema = new mongoose.Schema({
  title: {
    type: String,
    required: [true, 'Banner title is required'],
    trim: true,
    maxlength: [100, 'Title cannot exceed 100 characters']
  },
  subtitle: {
    type: String,
    trim: true,
    maxlength: [200, 'Subtitle cannot exceed 200 characters']
  },
  image_url: {
    type: String,
    required: [true, 'Image URL is required'],
    trim: true
  },
  action_type: {
    type: String,
    enum: ['none', 'service', 'booking', 'coupon', 'url'],
    default: 'none'
  },
  action_value: {
    type: String,
    trim: true,
    default: ''
  },
  display_order: {
    type: Number,
    default: 0,
    min: [0, 'Display order must be non-negative']
  },
  start_date: {
    type: Date,
    default: null
  },
  end_date: {
    type: Date,
    default: null
  },
  is_active: {
    type: Boolean,
    default: true
  },
  created_by: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'AdminUser',
    default: null
  }
}, {
  timestamps: { createdAt: 'created_date', updatedAt: 'updated_date' }
});

// Indexes for faster queries
bannerSchema.index({ is_active: 1, display_order: 1 });
bannerSchema.index({ start_date: 1, end_date: 1 });

const Banner = mongoose.model('Banner', bannerSchema);

export default Banner;

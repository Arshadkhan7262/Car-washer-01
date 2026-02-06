import mongoose from 'mongoose';

const notificationSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true
  },
  message: {
    type: String,
    required: true,
    trim: true
  },
  target_audience: {
    type: String,
    enum: ['all', 'customer', 'washer', 'specific'],
    default: 'all'
  },
  user_ids: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  data: {
    type: mongoose.Schema.Types.Mixed,
    default: {}
  },
  sent_by: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'AdminUser'
  },
  status: {
    type: String,
    enum: ['pending', 'sending', 'completed', 'failed'],
    default: 'pending'
  },
  read_by: [{
    user_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    read_at: {
      type: Date,
      default: Date.now
    }
  }],
  created_date: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Indexes
notificationSchema.index({ target_audience: 1 });
notificationSchema.index({ user_ids: 1 });
notificationSchema.index({ created_date: -1 });
notificationSchema.index({ status: 1 });

const Notification = mongoose.models.Notification || mongoose.model('Notification', notificationSchema);

export default Notification;

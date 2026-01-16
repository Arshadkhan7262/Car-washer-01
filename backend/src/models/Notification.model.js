import mongoose from 'mongoose';

const notificationSchema = new mongoose.Schema({
  title: {
    type: String,
    required: [true, 'Notification title is required'],
    trim: true
  },
  message: {
    type: String,
    required: [true, 'Notification message is required'],
    trim: true
  },
  target_audience: {
    type: String,
    enum: ['all', 'active', 'inactive', 'new', 'specific'],
    required: true
  },
  user_ids: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  sent_to: [{
    user_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    device_count: {
      type: Number,
      default: 0
    },
    sent_at: {
      type: Date,
      default: Date.now
    }
  }],
  total_sent: {
    type: Number,
    default: 0
  },
  total_failed: {
    type: Number,
    default: 0
  },
  data: {
    type: Map,
    of: mongoose.Schema.Types.Mixed,
    default: {}
  },
  sent_by: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'AdminUser',
    required: true
  },
  status: {
    type: String,
    enum: ['pending', 'sending', 'completed', 'failed'],
    default: 'pending'
  },
  created_at: {
    type: Date,
    default: Date.now
  },
  sent_at: {
    type: Date
  }
}, {
  timestamps: true
});

// Index for faster queries
notificationSchema.index({ created_at: -1 });
notificationSchema.index({ sent_by: 1 });
notificationSchema.index({ target_audience: 1 });
notificationSchema.index({ 'sent_to.user_id': 1 });

const Notification = mongoose.model('Notification', notificationSchema);

export default Notification;


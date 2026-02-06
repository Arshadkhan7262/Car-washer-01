import mongoose from 'mongoose';

const adminSettingsSchema = new mongoose.Schema({
  key: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },
  value: {
    type: mongoose.Schema.Types.Mixed,
    required: true
  },
  description: {
    type: String,
    default: null,
    trim: true
  },
  updated_by: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'AdminUser',
    default: null
  }
}, {
  timestamps: { createdAt: 'created_date', updatedAt: 'updated_date' }
});

// Index for faster queries
adminSettingsSchema.index({ key: 1 });

const AdminSettings = mongoose.model('AdminSettings', adminSettingsSchema);

export default AdminSettings;

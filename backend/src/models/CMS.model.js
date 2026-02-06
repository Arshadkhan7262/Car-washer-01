import mongoose from 'mongoose';

const cmsVersionSchema = new mongoose.Schema({
  content: {
    type: String,
    required: true
  },
  status: {
    type: String,
    enum: ['draft', 'published'],
    required: true
  },
  updated_by: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'AdminUser',
    default: null
  },
  updated_at: {
    type: Date,
    default: Date.now
  }
}, { _id: false });

const cmsSchema = new mongoose.Schema({
  slug: {
    type: String,
    required: [true, 'CMS slug is required'],
    unique: true,
    trim: true,
    lowercase: true,
    match: [/^[a-z0-9-]+$/, 'Slug can only contain lowercase letters, numbers, and hyphens']
  },
  title: {
    type: String,
    required: [true, 'CMS title is required'],
    trim: true,
    maxlength: [200, 'Title cannot exceed 200 characters']
  },
  content: {
    type: String,
    required: true,
    default: ''
  },
  target: {
    type: String,
    enum: ['customer', 'washer', 'both'],
    required: [true, 'Target audience is required'],
    default: 'both'
  },
  status: {
    type: String,
    enum: ['draft', 'published'],
    default: 'draft',
    required: true
  },
  published_content: {
    type: String,
    default: ''
  },
  published_at: {
    type: Date,
    default: null
  },
  version_history: {
    type: [cmsVersionSchema],
    default: []
  },
  created_by: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'AdminUser',
    default: null
  },
  updated_by: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'AdminUser',
    default: null
  }
}, {
  timestamps: { createdAt: 'created_date', updatedAt: 'updated_date' }
});

// Indexes for faster queries
cmsSchema.index({ slug: 1 }, { unique: true });
cmsSchema.index({ status: 1, target: 1 });
cmsSchema.index({ updated_date: -1 });

// Pre-save hook to limit version history to last 50 versions
cmsSchema.pre('save', function(next) {
  if (this.version_history && this.version_history.length > 50) {
    this.version_history = this.version_history.slice(-50);
  }
  next();
});

const CMS = mongoose.model('CMS', cmsSchema);

export default CMS;

import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Name is required'],
    trim: true
  },
  email: {
    type: String,
    lowercase: true,
    trim: true,
    match: [/^\S+@\S+\.\S+$/, 'Please provide a valid email'],
    sparse: true, // Allow multiple null emails
    unique: true // Ensure email uniqueness at database level
  },
  phone: {
    type: String,
    required: [true, 'Phone number is required'],
    trim: true
  },
  password: {
    type: String,
    select: false,
    minlength: [6, 'Password must be at least 6 characters']
  },
  role: {
    type: String,
    enum: ['customer', 'washer'],
    default: 'customer'
  },
  // Firebase Authentication
  // firebaseUid is required for new Firebase-authenticated users
  // Existing OTP users will get this when they re-authenticate via Firebase
  firebaseUid: {
    type: String,
    trim: true,
    sparse: true // Allow null for existing users during migration
    // Note: Indexes are created explicitly below to avoid conflicts
  },
  // Google OAuth Authentication
  googleId: {
    type: String,
    trim: true,
    sparse: true // Allow null for users not using Google login
  },
  profilePicture: {
    type: String,
    trim: true
  },
  avatar: {
    type: String,
    trim: true
  },
  provider: {
    type: String,
    enum: ['email', 'google'],
    default: 'email'
  },
  // Phone is verified by Firebase for Firebase-authenticated users
  // For existing OTP users, phone_verified remains as set
  phone_verified: {
    type: Boolean,
    default: false // Will be set to true when authenticated via Firebase
  },
  email_verified: {
    type: Boolean,
    default: false
  },
  // OTP for email verification (washers and customers)
  otp: {
    code: {
      type: String,
      select: false // Do not return OTP by default
    },
    expiresAt: {
      type: Date,
      select: false // Do not return OTP expiry by default
    }
  },
  is_active: {
    type: Boolean,
    default: true
  },
  is_blocked: {
    type: Boolean,
    default: false
  },
  wallet_balance: {
    type: Number,
    default: 0
  },
  // Customer preferences (for wash_away app)
  preferences: {
    push_notification_enabled: {
      type: Boolean,
      default: true
    },
    two_factor_auth_enabled: {
      type: Boolean,
      default: false
    }
  },
  // FCM Tokens for push notifications (array to support multiple devices)
  fcm_tokens: [{
    token: {
      type: String,
      required: true,
      trim: true
    },
    device_type: {
      type: String,
      enum: ['android', 'ios', 'web'],
      default: 'android'
    },
    created_at: {
      type: Date,
      default: Date.now
    },
    updated_at: {
      type: Date,
      default: Date.now
    }
  }],
  // Gold member status (for wash_away app)
  is_gold_member: {
    type: Boolean,
    default: false
  },
  // Stripe Customer ID
  stripeCustomerId: {
    type: String,
    trim: true,
    sparse: true
  },
  lastLogin: {
    type: Date,
    default: null
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

// Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('password') || !this.password) {
    return next();
  }
  
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Method to compare password
userSchema.methods.comparePassword = async function(candidatePassword) {
  if (!this.password || !candidatePassword) {
    return false;
  }
  return await bcrypt.compare(candidatePassword, this.password);
};

// Method to remove sensitive data from JSON output
userSchema.methods.toJSON = function() {
  const obj = this.toObject();
  delete obj.password;
  return obj;
};

// Index for faster queries
// #region agent log
fetch('http://127.0.0.1:7242/ingest/6e5cc667-9ca2-482c-8249-fe079e856385',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'User.model.js:105',message:'Before registering indexes',data:{firebaseUidHasIndexTrue:true,indexesToRegister:['phone+role','firebaseUid+role','email','role+is_active','firebaseUid']},timestamp:Date.now(),sessionId:'debug-session',runId:'run1',hypothesisId:'A'})}).catch(()=>{});
// #endregion
// Compound unique index: phone + role (allows same phone for different roles)
userSchema.index({ phone: 1, role: 1 }, { unique: true });
// #region agent log
fetch('http://127.0.0.1:7242/ingest/6e5cc667-9ca2-482c-8249-fe079e856385',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'User.model.js:107',message:'Registered phone+role compound index',data:{index:'phone+role'},timestamp:Date.now(),sessionId:'debug-session',runId:'run1',hypothesisId:'D'})}).catch(()=>{});
// #endregion
// Compound unique index: firebaseUid + role (allows same Firebase UID for different roles)
// Partial index: only indexes documents where firebaseUid exists (not null)
// This allows multiple users with firebaseUid: null (email-based registration)
// Using partial index instead of sparse to properly handle null values
userSchema.index(
  { firebaseUid: 1, role: 1 }, 
  { 
    unique: true, 
    partialFilterExpression: { firebaseUid: { $exists: true } }
  }
);
// #region agent log
fetch('http://127.0.0.1:7242/ingest/6e5cc667-9ca2-482c-8249-fe079e856385',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'User.model.js:109',message:'Registered firebaseUid+role compound index',data:{index:'firebaseUid+role'},timestamp:Date.now(),sessionId:'debug-session',runId:'run1',hypothesisId:'B'})}).catch(()=>{});
// #endregion
userSchema.index({ email: 1 }, { unique: true, sparse: true });
// #region agent log
fetch('http://127.0.0.1:7242/ingest/6e5cc667-9ca2-482c-8249-fe079e856385',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'User.model.js:110',message:'Registered email index',data:{index:'email'},timestamp:Date.now(),sessionId:'debug-session',runId:'run1',hypothesisId:'C'})}).catch(()=>{});
// #endregion
userSchema.index({ role: 1, is_active: 1 });
userSchema.index({ firebaseUid: 1 }); // For quick lookups
// #region agent log
fetch('http://127.0.0.1:7242/ingest/6e5cc667-9ca2-482c-8249-fe079e856385',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({location:'User.model.js:112',message:'Registered firebaseUid single-field index (potential duplicate)',data:{index:'firebaseUid',hasIndexTrueInField:true},timestamp:Date.now(),sessionId:'debug-session',runId:'run1',hypothesisId:'A'})}).catch(()=>{});
// #endregion

const User = mongoose.model('User', userSchema);

export default User;




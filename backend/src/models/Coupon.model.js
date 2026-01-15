import mongoose from 'mongoose';

const couponSchema = new mongoose.Schema({
  code: {
    type: String,
    required: [true, 'Coupon code is required'],
    unique: true,
    uppercase: true,
    trim: true
  },
  description: {
    type: String,
    trim: true
  },
  discount_type: {
    type: String,
    enum: ['percentage', 'fixed'],
    required: [true, 'Discount type is required']
  },
  discount_value: {
    type: Number,
    required: [true, 'Discount value is required'],
    min: 0
  },
  min_order_value: {
    type: Number,
    default: 0,
    min: 0
  },
  max_discount: {
    type: Number,
    default: null,
    min: 0
  },
  valid_from: {
    type: Date,
    default: Date.now
  },
  valid_until: {
    type: Date,
    required: [true, 'Valid until date is required']
  },
  usage_limit: {
    type: Number,
    default: null,
    min: 0
  },
  times_used: {
    type: Number,
    default: 0,
    min: 0
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
});

// Method to validate coupon
couponSchema.methods.isValid = function(orderValue) {
  const now = new Date();
  
  // Check if coupon is active
  if (!this.is_active) {
    return { valid: false, message: 'Coupon is not active' };
  }
  
  // Check if coupon is within valid date range
  if (now < this.valid_from) {
    return { valid: false, message: 'Coupon is not yet valid' };
  }
  
  if (now > this.valid_until) {
    return { valid: false, message: 'Coupon has expired' };
  }
  
  // Check minimum order value
  if (orderValue < this.min_order_value) {
    return { 
      valid: false, 
      message: `Minimum order value of ${this.min_order_value} is required` 
    };
  }
  
  // Check usage limit
  if (this.usage_limit && this.times_used >= this.usage_limit) {
    return { valid: false, message: 'Coupon usage limit reached' };
  }
  
  return { valid: true };
};

// Method to calculate discount
couponSchema.methods.calculateDiscount = function(orderValue) {
  let discount = 0;
  
  if (this.discount_type === 'percentage') {
    discount = (orderValue * this.discount_value) / 100;
    
    // Apply max discount if set
    if (this.max_discount && discount > this.max_discount) {
      discount = this.max_discount;
    }
  } else if (this.discount_type === 'fixed') {
    discount = this.discount_value;
    
    // Don't allow discount to exceed order value
    if (discount > orderValue) {
      discount = orderValue;
    }
  }
  
  return Math.round(discount * 100) / 100; // Round to 2 decimal places
};

// Update updated_date before saving
couponSchema.pre('save', function(next) {
  this.updated_date = new Date();
  next();
});

const Coupon = mongoose.model('Coupon', couponSchema);

export default Coupon;

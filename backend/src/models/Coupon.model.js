import mongoose from 'mongoose';

const couponSchema = new mongoose.Schema({
  code: {
    type: String,
    required: [true, 'Coupon code is required'],
    unique: true,
    uppercase: true,
    trim: true,
    index: true
  },
  description: {
    type: String,
    trim: true
  },
  discount_type: {
    type: String,
    enum: ['percentage', 'fixed'],
    required: [true, 'Discount type is required'],
    default: 'percentage'
  },
  discount_value: {
    type: Number,
    required: [true, 'Discount value is required'],
    min: [0, 'Discount value must be positive']
  },
  min_order_value: {
    type: Number,
    default: 0,
    min: [0, 'Minimum order value must be positive']
  },
  max_discount: {
    type: Number,
    default: 0,
    min: [0, 'Maximum discount must be positive']
  },
  expiry_date: {
    type: Date,
    default: null
  },
  usage_limit: {
    type: Number,
    default: null, // null means unlimited
    min: [1, 'Usage limit must be at least 1']
  },
  times_used: {
    type: Number,
    default: 0,
    min: [0, 'Times used cannot be negative']
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
couponSchema.index({ code: 1, is_active: 1 });
couponSchema.index({ expiry_date: 1 });

// Method to check if coupon is valid
couponSchema.methods.isValid = function(orderValue = 0) {
  // Check if active
  if (!this.is_active) {
    return { valid: false, message: 'Coupon is not active' };
  }

  // Check if expired
  if (this.expiry_date && new Date(this.expiry_date) < new Date()) {
    return { valid: false, message: 'Coupon has expired' };
  }

  // Check usage limit
  if (this.usage_limit && this.times_used >= this.usage_limit) {
    return { valid: false, message: 'Coupon usage limit reached' };
  }

  // Check minimum order value
  if (this.min_order_value > 0 && orderValue < this.min_order_value) {
    return { 
      valid: false, 
      message: `Minimum order value of $${this.min_order_value} required` 
    };
  }

  return { valid: true };
};

// Method to calculate discount
couponSchema.methods.calculateDiscount = function(orderValue) {
  let discount = 0;

  if (this.discount_type === 'percentage') {
    discount = (orderValue * this.discount_value) / 100;
    // Apply max discount if set
    if (this.max_discount > 0 && discount > this.max_discount) {
      discount = this.max_discount;
    }
  } else {
    // Fixed amount
    discount = this.discount_value;
    // Don't allow discount to exceed order value
    if (discount > orderValue) {
      discount = orderValue;
    }
  }

  return Math.round(discount * 100) / 100; // Round to 2 decimal places
};

const Coupon = mongoose.model('Coupon', couponSchema);

export default Coupon;

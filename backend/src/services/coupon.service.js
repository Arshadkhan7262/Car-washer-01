import mongoose from 'mongoose';
import Coupon from '../models/Coupon.model.js';
import AppError from '../errors/AppError.js';

/**
 * Get all coupons with filters
 */
export const getAllCoupons = async (filters = {}) => {
  const {
    is_active,
    page = 1,
    limit = 20,
    sort = '-created_date'
  } = filters;

  // Build query
  const query = {};

  if (is_active !== undefined) {
    query.is_active = is_active === 'true' || is_active === true;
  }

  // Parse sort
  const sortField = sort.startsWith('-') ? sort.substring(1) : sort;
  const sortOrder = sort.startsWith('-') ? -1 : 1;
  const sortObj = { [sortField]: sortOrder };

  // Calculate pagination
  const skip = (parseInt(page) - 1) * parseInt(limit);

  // Get coupons
  const coupons = await Coupon.find(query)
    .sort(sortObj)
    .skip(skip)
    .limit(parseInt(limit))
    .lean();

  // Get total count
  const total = await Coupon.countDocuments(query);

  return {
    coupons,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total,
      totalPages: Math.ceil(total / parseInt(limit))
    }
  };
};

/**
 * Get coupon by ID
 */
export const getCouponById = async (couponId) => {
  const coupon = await Coupon.findById(couponId).lean();

  if (!coupon) {
    throw new AppError('Coupon not found', 404);
  }

  return coupon;
};

/**
 * Get coupon by code
 */
export const getCouponByCode = async (code) => {
  const coupon = await Coupon.findOne({ 
    code: code.toUpperCase().trim() 
  }).lean();

  if (!coupon) {
    throw new AppError('Coupon not found', 404);
  }

  return coupon;
};

/**
 * Create new coupon
 */
export const createCoupon = async (couponData) => {
  // Check if code already exists
  const existingCoupon = await Coupon.findOne({ 
    code: couponData.code.toUpperCase().trim() 
  });

  if (existingCoupon) {
    throw new AppError('Coupon code already exists', 400);
  }

  // Validate discount value based on type
  if (couponData.discount_type === 'percentage' && couponData.discount_value > 100) {
    throw new AppError('Percentage discount cannot exceed 100%', 400);
  }

  const coupon = await Coupon.create({
    ...couponData,
    code: couponData.code.toUpperCase().trim()
  });

  return coupon;
};

/**
 * Update coupon
 */
export const updateCoupon = async (couponId, updateData) => {
  const coupon = await Coupon.findById(couponId);

  if (!coupon) {
    throw new AppError('Coupon not found', 404);
  }

  // If code is being updated, check if new code exists
  if (updateData.code && updateData.code.toUpperCase().trim() !== coupon.code) {
    const existingCoupon = await Coupon.findOne({ 
      code: updateData.code.toUpperCase().trim() 
    });

    if (existingCoupon) {
      throw new AppError('Coupon code already exists', 400);
    }
    updateData.code = updateData.code.toUpperCase().trim();
  }

  // Validate discount value
  if (updateData.discount_type === 'percentage' && updateData.discount_value > 100) {
    throw new AppError('Percentage discount cannot exceed 100%', 400);
  }

  Object.assign(coupon, updateData);
  await coupon.save();

  return coupon;
};

/**
 * Delete coupon
 */
export const deleteCoupon = async (couponId) => {
  const coupon = await Coupon.findById(couponId);

  if (!coupon) {
    throw new AppError('Coupon not found', 404);
  }

  await Coupon.findByIdAndDelete(couponId);
  return { message: 'Coupon deleted successfully' };
};

/**
 * Validate and apply coupon
 */
export const validateCoupon = async (code, orderValue, customerId = null) => {
  // Normalize customerId to ObjectId if provided
  let normalizedCustomerId = null;
  if (customerId) {
    normalizedCustomerId = customerId instanceof mongoose.Types.ObjectId 
      ? customerId 
      : new mongoose.Types.ObjectId(customerId);
  }

  const coupon = await Coupon.findOne({ 
    code: code.toUpperCase().trim() 
  });

  if (!coupon) {
    throw new AppError('Invalid coupon code', 404);
  }

  // Check if coupon is valid (includes customer-specific checks)
  // Pass normalized customerId to isValid
  const validation = coupon.isValid(orderValue, normalizedCustomerId || customerId);
  if (!validation.valid) {
    throw new AppError(validation.message, 400);
  }

  // Calculate discount
  const discount = coupon.calculateDiscount(orderValue);
  const finalAmount = orderValue - discount;

  return {
    coupon: {
      id: coupon._id,
      code: coupon.code,
      description: coupon.description,
      discount_type: coupon.discount_type,
      discount_value: coupon.discount_value
    },
    discount,
    subtotal: orderValue,
    total: finalAmount
  };
};

/**
 * Mark coupon as used by customer
 */
export const markCouponAsUsed = async (couponId, customerId) => {
  const coupon = await Coupon.findById(couponId);
  
  if (!coupon) {
    throw new AppError('Coupon not found', 404);
  }

  if (!customerId) {
    // If no customerId, just increment usage
    coupon.times_used += 1;
    await coupon.save();
    return coupon;
  }

  // Convert customerId to ObjectId for consistent comparison
  const customerObjectId = customerId instanceof mongoose.Types.ObjectId 
    ? customerId 
    : new mongoose.Types.ObjectId(customerId);

  // Convert to string for comparison
  const customerIdStr = customerObjectId.toString();

  // Check if customer already used this coupon
  const alreadyUsed = coupon.used_by_customers.some(
    id => {
      const idStr = id instanceof mongoose.Types.ObjectId 
        ? id.toString() 
        : (id?._id ? id._id.toString() : String(id));
      return idStr === customerIdStr;
    }
  );

  // Add customer to used_by_customers if not already there
  if (!alreadyUsed) {
    // Use atomic update to ensure consistency
    const updateResult = await Coupon.findByIdAndUpdate(
      couponId,
      {
        $addToSet: { used_by_customers: customerObjectId }, // $addToSet prevents duplicates
        $inc: { times_used: 1 }
      },
      { new: true } // Return updated document
    );
    
    if (updateResult) {
      console.log(`✅ Coupon ${coupon.code} marked as used by customer ${customerIdStr}`);
      return updateResult;
    } else {
      console.error(`❌ Failed to mark coupon ${coupon.code} as used by customer ${customerIdStr}`);
      throw new AppError('Failed to mark coupon as used', 500);
    }
  } else {
    console.log(`⚠️ Customer ${customerIdStr} already used coupon ${coupon.code}`);
  }

  return coupon;
};

/**
 * Increment coupon usage (deprecated - use markCouponAsUsed instead)
 */
export const incrementCouponUsage = async (couponId) => {
  await Coupon.findByIdAndUpdate(
    couponId,
    { $inc: { times_used: 1 } }
  );
};

/**
 * Get available coupons for a customer
 */
export const getAvailableCouponsForCustomer = async (customerId) => {
  const now = new Date();
  const customerIdStr = customerId?.toString();
  
  // Build query
  const query = {
    is_active: true,
    valid_from: { $lte: now },
    valid_until: { $gte: now },
    $or: [
      { usage_limit: null },
      { $expr: { $lt: ['$times_used', '$usage_limit'] } }
    ]
  };

  // Add target type filter
  if (customerId) {
    query.$and = [
      {
        $or: [
          { target_type: 'all' },
          { target_type: 'specific', target_customer_ids: customerId }
        ]
      }
    ];
  } else {
    query.target_type = 'all';
  }
  
  const coupons = await Coupon.find(query)
    .select('code description discount_type discount_value min_order_value max_discount valid_until usage_limit times_used used_by_customers')
    .lean();

  // Filter out coupons already used by this customer
  const availableCoupons = coupons.filter(coupon => {
    if (!customerIdStr) return true;
    if (!coupon.used_by_customers || coupon.used_by_customers.length === 0) return true;
    return !coupon.used_by_customers.some(
      id => id.toString() === customerIdStr
    );
  });

  // Remove used_by_customers from response for privacy
  return availableCoupons.map(coupon => {
    const { used_by_customers, ...rest } = coupon;
    return rest;
  });
};

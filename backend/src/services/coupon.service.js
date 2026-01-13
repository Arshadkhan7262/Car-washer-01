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
export const validateCoupon = async (code, orderValue) => {
  const coupon = await Coupon.findOne({ 
    code: code.toUpperCase().trim() 
  });

  if (!coupon) {
    throw new AppError('Invalid coupon code', 404);
  }

  // Check if coupon is valid
  const validation = coupon.isValid(orderValue);
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
 * Increment coupon usage
 */
export const incrementCouponUsage = async (couponId) => {
  await Coupon.findByIdAndUpdate(
    couponId,
    { $inc: { times_used: 1 } }
  );
};

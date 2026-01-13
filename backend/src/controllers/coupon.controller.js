import * as couponService from '../services/coupon.service.js';
import AppError from '../errors/AppError.js';

/**
 * @desc    Get all coupons (Admin)
 * @route   GET /api/v1/admin/coupons
 * @access  Private (Admin)
 */
export const getAllCoupons = async (req, res, next) => {
  try {
    const filters = {
      is_active: req.query.is_active,
      page: req.query.page || 1,
      limit: req.query.limit || 20,
      sort: req.query.sort || '-created_date'
    };

    const result = await couponService.getAllCoupons(filters);

    res.status(200).json({
      success: true,
      data: result.coupons,
      pagination: result.pagination
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get coupon by ID (Admin)
 * @route   GET /api/v1/admin/coupons/:id
 * @access  Private (Admin)
 */
export const getCouponById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const coupon = await couponService.getCouponById(id);

    res.status(200).json({
      success: true,
      data: coupon
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Create new coupon (Admin)
 * @route   POST /api/v1/admin/coupons
 * @access  Private (Admin)
 */
export const createCoupon = async (req, res, next) => {
  try {
    const {
      code,
      description,
      discount_type,
      discount_value,
      min_order_value,
      max_discount,
      expiry_date,
      usage_limit,
      is_active
    } = req.body;

    // Validate required fields
    if (!code || !discount_type || discount_value === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Code, discount_type, and discount_value are required'
      });
    }

    const coupon = await couponService.createCoupon({
      code,
      description,
      discount_type,
      discount_value: parseFloat(discount_value),
      min_order_value: min_order_value ? parseFloat(min_order_value) : 0,
      max_discount: max_discount ? parseFloat(max_discount) : 0,
      expiry_date: expiry_date ? new Date(expiry_date) : null,
      usage_limit: usage_limit ? parseInt(usage_limit) : null,
      is_active: is_active !== undefined ? is_active : true
    });

    res.status(201).json({
      success: true,
      message: 'Coupon created successfully',
      data: coupon
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Update coupon (Admin)
 * @route   PUT /api/v1/admin/coupons/:id
 * @access  Private (Admin)
 */
export const updateCoupon = async (req, res, next) => {
  try {
    const { id } = req.params;
    const updateData = { ...req.body };

    // Convert numeric fields
    if (updateData.discount_value !== undefined) {
      updateData.discount_value = parseFloat(updateData.discount_value);
    }
    if (updateData.min_order_value !== undefined) {
      updateData.min_order_value = parseFloat(updateData.min_order_value);
    }
    if (updateData.max_discount !== undefined) {
      updateData.max_discount = parseFloat(updateData.max_discount);
    }
    if (updateData.usage_limit !== undefined) {
      updateData.usage_limit = updateData.usage_limit ? parseInt(updateData.usage_limit) : null;
    }
    if (updateData.expiry_date !== undefined) {
      updateData.expiry_date = updateData.expiry_date ? new Date(updateData.expiry_date) : null;
    }

    const coupon = await couponService.updateCoupon(id, updateData);

    res.status(200).json({
      success: true,
      message: 'Coupon updated successfully',
      data: coupon
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Delete coupon (Admin)
 * @route   DELETE /api/v1/admin/coupons/:id
 * @access  Private (Admin)
 */
export const deleteCoupon = async (req, res, next) => {
  try {
    const { id } = req.params;
    await couponService.deleteCoupon(id);

    res.status(200).json({
      success: true,
      message: 'Coupon deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Validate coupon code (Customer)
 * @route   POST /api/v1/customer/coupons/validate
 * @access  Private (Customer)
 */
export const validateCoupon = async (req, res, next) => {
  try {
    const { code, order_value } = req.body;

    if (!code) {
      return res.status(400).json({
        success: false,
        message: 'Coupon code is required'
      });
    }

    if (!order_value || order_value <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Valid order value is required'
      });
    }

    const result = await couponService.validateCoupon(code, parseFloat(order_value));

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

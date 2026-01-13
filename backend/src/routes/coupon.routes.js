import express from 'express';
import * as couponController from '../controllers/coupon.controller.js';
import { protect } from '../middleware/auth.middleware.js';
import { protectCustomer } from '../middleware/auth.middleware.js';

const router = express.Router();

// Admin routes
router.get('/', protect, couponController.getAllCoupons);
router.get('/:id', protect, couponController.getCouponById);
router.post('/', protect, couponController.createCoupon);
router.put('/:id', protect, couponController.updateCoupon);
router.delete('/:id', protect, couponController.deleteCoupon);

export default router;

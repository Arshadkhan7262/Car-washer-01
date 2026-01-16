import express from 'express';
import * as couponController from '../controllers/coupon.controller.js';
import { protectCustomer } from '../middleware/auth.middleware.js';

const router = express.Router();

// Customer routes
router.get('/', protectCustomer, couponController.getAvailableCoupons);
router.post('/validate', protectCustomer, couponController.validateCoupon);

export default router;




import express from 'express';
import * as bannerController from '../controllers/banner.controller.js';
import { protect } from '../middleware/auth.middleware.js';
import { uploadBannerImage } from '../middleware/bannerUpload.middleware.js';

const router = express.Router();

/**
 * Admin Banner Routes
 */

// Get all banners (Admin)
router.get('/', protect, bannerController.getAllBanners);

// Get banner by ID (Admin)
router.get('/:id', protect, bannerController.getBannerById);

// Create banner (Admin) - supports both file upload and URL
router.post(
  '/',
  protect,
  uploadBannerImage,
  bannerController.createBanner
);

// Update banner (Admin) - supports both file upload and URL
router.put(
  '/:id',
  protect,
  uploadBannerImage,
  bannerController.updateBanner
);

// Delete banner (Admin)
router.delete('/:id', protect, bannerController.deleteBanner);

export default router;

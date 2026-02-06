import express from 'express';
import * as bannerController from '../controllers/banner.controller.js';

const router = express.Router();

/**
 * Customer Banner Routes (Public)
 */

// Get active banners for customer app
router.get('/', bannerController.getActiveBanners);

export default router;

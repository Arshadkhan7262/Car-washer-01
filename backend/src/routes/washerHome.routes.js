/**
 * Washer Home Screen Routes
 * Handles dashboard statistics and home screen data
 */

import express from 'express';
import * as washerHomeController from '../controllers/washerHome.controller.js';
import { protectWasher } from '../middleware/auth.middleware.js';

const router = express.Router();

// All routes require washer authentication
router.use(protectWasher);

// Home screen routes
router.get('/stats', washerHomeController.getDashboardStats);
router.get('/stats/:period', washerHomeController.getPeriodStats);

export default router;


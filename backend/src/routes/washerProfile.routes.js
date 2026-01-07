/**
 * Washer Profile Screen Routes
 * Handles profile data and profile updates
 */

import express from 'express';
import * as washerProfileController from '../controllers/washerProfile.controller.js';
import { protectWasher } from '../middleware/auth.middleware.js';

const router = express.Router();

// All routes require washer authentication
router.use(protectWasher);

// Profile routes
router.get('/', washerProfileController.getWasherProfile);
router.put('/', washerProfileController.updateWasherProfile);
router.put('/online-status', washerProfileController.toggleOnlineStatus);

export default router;


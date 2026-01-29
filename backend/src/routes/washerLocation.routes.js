/**
 * Washer Location Routes
 * Handles location updates and retrieval
 */

import express from 'express';
import * as washerLocationController from '../controllers/washerLocation.controller.js';
import { protectWasher } from '../middleware/auth.middleware.js';

const router = express.Router();

// All routes require washer authentication
router.use(protectWasher);

// Location routes
router.put('/', washerLocationController.updateLocation);
router.get('/', washerLocationController.getLocation);

export default router;














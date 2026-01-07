/**
 * Customer Profile Screen Routes
 * Handles profile data, stats, and preferences for wash_away app
 * Separate from admin customer APIs
 */

import express from 'express';
import * as customerProfileController from '../controllers/customerProfile.controller.js';
import { protectCustomer } from '../middleware/auth.middleware.js';

const router = express.Router();

// All routes require customer authentication
router.use(protectCustomer);

// Profile routes
router.get('/', customerProfileController.getCustomerProfile);
router.put('/', customerProfileController.updateCustomerProfile);

// Stats routes
router.get('/stats', customerProfileController.getCustomerStats);

// Preferences routes
router.get('/preferences', customerProfileController.getCustomerPreferences);
router.put('/preferences', customerProfileController.updateCustomerPreferences);

export default router;




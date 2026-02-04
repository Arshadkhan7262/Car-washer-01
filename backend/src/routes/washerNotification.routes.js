import express from 'express';
import * as notificationController from '../controllers/notification.controller.js';
import { protectWasher } from '../middleware/auth.middleware.js';

const router = express.Router();

// All routes require washer authentication
router.use(protectWasher);

// Save/Update FCM token
router.post('/fcm-token', notificationController.saveWasherFcmToken);

// Remove FCM token
router.delete('/fcm-token', notificationController.removeWasherFcmToken);

export default router;

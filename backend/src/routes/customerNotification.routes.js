import express from 'express';
import * as notificationController from '../controllers/notification.controller.js';
import { protectCustomer } from '../middleware/auth.middleware.js';

const router = express.Router();

// All routes require customer authentication
router.use(protectCustomer);

// Save/Update FCM token
router.post('/fcm-token', notificationController.saveFcmToken);

// Remove FCM token
router.delete('/fcm-token', notificationController.removeFcmToken);

export default router;


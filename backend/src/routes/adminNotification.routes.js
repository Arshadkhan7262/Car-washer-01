import express from 'express';
import * as notificationController from '../controllers/notification.controller.js';
import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

// All routes require admin authentication
router.use(protect);

// Send notification
router.post('/send', notificationController.sendNotification);

// Get all notifications
router.get('/', notificationController.getNotifications);

export default router;


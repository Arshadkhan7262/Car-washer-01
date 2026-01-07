import express from 'express';
import * as dashboardController from '../controllers/dashboard.controller.js';
import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

// All dashboard routes require authentication
router.use(protect);

// Dashboard routes
router.get('/kpis', dashboardController.getKPIs);
router.get('/stats', dashboardController.getStats);
router.get('/activity', dashboardController.getActivity);

export default router;




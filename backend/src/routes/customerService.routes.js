import express from 'express';
import * as customerServiceController from '../controllers/customerService.controller.js';

const router = express.Router();

// Public routes - no authentication required
router.get('/', customerServiceController.getAllServices);
router.get('/:id', customerServiceController.getServiceById);

export default router;




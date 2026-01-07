import express from 'express';
import * as serviceController from '../controllers/service.controller.js';
import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

// All service routes require authentication
router.use(protect);

// Service routes
router.get('/', serviceController.getAllServices);
router.get('/:id', serviceController.getServiceById);
router.post('/', serviceController.createService);
router.put('/:id', serviceController.updateService);
router.delete('/:id', serviceController.deleteService);

export default router;




import express from 'express';
import * as washerController from '../controllers/washer.controller.js';
import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

// All washer routes require authentication
router.use(protect);

// Washer routes
router.get('/', washerController.getAllWashers);
router.get('/:id', washerController.getWasherById);
router.post('/', washerController.createWasher);
router.put('/:id', washerController.updateWasher);
router.delete('/:id', washerController.deleteWasher);

export default router;




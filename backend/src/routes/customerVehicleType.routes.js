import express from 'express';
import * as customerVehicleTypeController from '../controllers/customerVehicleType.controller.js';

const router = express.Router();

// Public route - no authentication required
router.get('/', customerVehicleTypeController.getAllVehicleTypes);

export default router;


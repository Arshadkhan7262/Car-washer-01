import express from 'express';
import * as vehicleTypeController from '../controllers/vehicleType.controller.js';
import { protect } from '../middleware/auth.middleware.js';
import { uploadVehicleTypeImage } from '../middleware/upload.middleware.js';

const router = express.Router();

// All routes require admin authentication
router.use(protect);

router
  .route('/')
  .get(vehicleTypeController.getAllVehicleTypes)
  .post(uploadVehicleTypeImage, vehicleTypeController.createVehicleType);

router
  .route('/:id')
  .get(vehicleTypeController.getVehicleTypeById)
  .put(uploadVehicleTypeImage, vehicleTypeController.updateVehicleType)
  .delete(vehicleTypeController.deleteVehicleType);

export default router;


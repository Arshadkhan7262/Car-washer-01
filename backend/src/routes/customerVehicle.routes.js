import express from 'express';
import {
  getCustomerVehicles,
  createCustomerVehicle,
  updateCustomerVehicle,
  deleteCustomerVehicle,
  setDefaultVehicle
} from '../controllers/customerVehicle.controller.js';
import { protectCustomer } from '../middleware/auth.middleware.js';

const router = express.Router();

// All routes require customer authentication
router.use(protectCustomer);

router.route('/')
  .get(getCustomerVehicles)
  .post(createCustomerVehicle);

router.route('/:id')
  .put(updateCustomerVehicle)
  .delete(deleteCustomerVehicle);

router.put('/:id/default', setDefaultVehicle);

export default router;


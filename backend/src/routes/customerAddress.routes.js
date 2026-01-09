import express from 'express';
import {
  getCustomerAddresses,
  createCustomerAddress,
  updateCustomerAddress,
  deleteCustomerAddress,
  setDefaultAddress
} from '../controllers/customerAddress.controller.js';
import { protectCustomer } from '../middleware/auth.middleware.js';

const router = express.Router();

// All routes require customer authentication
router.use(protectCustomer);

router.route('/')
  .get(getCustomerAddresses)
  .post(createCustomerAddress);

router.route('/:id')
  .put(updateCustomerAddress)
  .delete(deleteCustomerAddress);

router.put('/:id/default', setDefaultAddress);

export default router;


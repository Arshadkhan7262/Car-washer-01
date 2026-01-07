import express from 'express';
import * as customerController from '../controllers/customer.controller.js';
import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

// All customer routes require authentication
router.use(protect);

// Customer routes
router.post('/', customerController.createCustomer); // Create customer (Admin)
router.get('/', customerController.getAllCustomers);
router.get('/:id', customerController.getCustomerById);
router.put('/:id', customerController.updateCustomer);
router.get('/:id/bookings', customerController.getCustomerBookings);

export default router;




import express from 'express';
import * as customerBookingController from '../controllers/customerBooking.controller.js';
import { protectCustomer } from '../middleware/auth.middleware.js';

const router = express.Router();

// All routes require customer authentication
router.use(protectCustomer);

router
  .route('/')
  .post(customerBookingController.createBooking)
  .get(customerBookingController.getCustomerBookings);

router.get('/:id/track', customerBookingController.trackBooking);
router.get('/:id/washer-location', customerBookingController.getWasherLocation);
router.put('/:id/cancel', customerBookingController.cancelBooking);
router.get('/:id', customerBookingController.getCustomerBookingById);

export default router;


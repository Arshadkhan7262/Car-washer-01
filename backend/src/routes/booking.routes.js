import express from 'express';
import * as bookingController from '../controllers/booking.controller.js';
import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

// All booking routes require authentication
router.use(protect);

// Booking routes
router.get('/', bookingController.getAllBookings);
router.get('/:id', bookingController.getBookingById);
router.post('/', bookingController.createBooking);
router.put('/:id', bookingController.updateBooking);
router.put('/:id/assign-washer', bookingController.assignWasher);
router.delete('/:id', bookingController.deleteBooking);

export default router;




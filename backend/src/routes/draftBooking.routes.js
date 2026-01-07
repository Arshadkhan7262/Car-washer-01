import express from 'express';
import * as draftBookingController from '../controllers/draftBooking.controller.js';
import { protectCustomer } from '../middleware/auth.middleware.js';

const router = express.Router();

// All routes require customer authentication
router.use(protectCustomer);

router
  .route('/')
  .post(draftBookingController.saveDraft)
  .get(draftBookingController.getDraft)
  .delete(draftBookingController.deleteDraft);

router.get('/check', draftBookingController.checkDraft);

export default router;


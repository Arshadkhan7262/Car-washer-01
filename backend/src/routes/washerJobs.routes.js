/**
 * Washer Jobs Screen Routes
 * Handles job management for washer app
 */

import express from 'express';
import * as washerJobsController from '../controllers/washerJobs.controller.js';
import { protectWasher } from '../middleware/auth.middleware.js';

const router = express.Router();

// All routes require washer authentication
router.use(protectWasher);

// Jobs routes
router.get('/', washerJobsController.getWasherJobs);
router.get('/:id', washerJobsController.getJobById);
router.post('/:id/accept', washerJobsController.acceptJob);
router.post('/:id/reject', washerJobsController.rejectJob);
router.put('/:id/status', washerJobsController.updateJobStatus);
router.post('/:id/complete', washerJobsController.completeJob);

export default router;


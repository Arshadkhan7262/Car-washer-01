import express from 'express';
import * as cmsController from '../controllers/cms.controller.js';

const router = express.Router();

/**
 * Public CMS Routes (for mobile apps)
 */

// Get published CMS page by slug (Public)
router.get('/:slug', cmsController.getPublishedCMSBySlug);

export default router;

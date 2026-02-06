import express from 'express';
import * as cmsController from '../controllers/cms.controller.js';
import { protect } from '../middleware/auth.middleware.js';
import { uploadCMSImage, getCMSImageUrl } from '../middleware/cmsImageUpload.middleware.js';

const router = express.Router();

/**
 * Admin CMS Routes
 */

// Image upload route (must be before slug routes to avoid route conflict)
router.post('/upload-image', protect, uploadCMSImage, (req, res) => {
  try {
    // Handle file upload error
    if (req.fileValidationError) {
      return res.status(400).json({
        success: false,
        message: req.fileValidationError
      });
    }

    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No image file provided'
      });
    }

    // Get image URL
    const imageUrl = getCMSImageUrl(req);
    const baseUrl = `${req.protocol}://${req.get('host')}`;
    const fullImageUrl = `${baseUrl}${imageUrl}`;

    res.status(200).json({
      success: true,
      message: 'Image uploaded successfully',
      data: {
        url: fullImageUrl,
        path: imageUrl
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to upload image'
    });
  }
});

// Get all CMS pages (Admin)
router.get('/', protect, cmsController.getAllCMS);

// Get CMS page by slug (Admin)
router.get('/:slug', protect, cmsController.getCMSBySlug);

// Create or update CMS page (Admin)
router.put('/:slug', protect, cmsController.upsertCMS);

// Publish CMS page (Admin)
router.post('/:slug/publish', protect, cmsController.publishCMS);

// Rollback CMS page (Admin)
router.post('/:slug/rollback', protect, cmsController.rollbackCMS);

// Delete CMS page (Admin)
router.delete('/:slug', protect, cmsController.deleteCMS);

export default router;

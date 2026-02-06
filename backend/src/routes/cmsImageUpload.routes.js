import express from 'express';
import { uploadCMSImage, getCMSImageUrl } from '../middleware/cmsImageUpload.middleware.js';
import { protect } from '../middleware/auth.middleware.js';

const router = express.Router();

/**
 * CMS Image Upload Route (Admin)
 * POST /api/v1/admin/cms/upload-image
 */
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

export default router;

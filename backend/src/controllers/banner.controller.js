import * as bannerService from '../services/banner.service.js';
import { getBannerImageUrl } from '../middleware/bannerUpload.middleware.js';
import AppError from '../errors/AppError.js';

/**
 * @desc    Get all banners (Admin)
 * @route   GET /api/v1/admin/settings/banners
 * @access  Private (Admin)
 */
export const getAllBanners = async (req, res, next) => {
  try {
    const filters = {
      is_active: req.query.is_active,
      sort: req.query.sort || 'display_order',
      limit: req.query.limit || 100
    };

    const banners = await bannerService.getAllBanners(filters);

    // Add full URL to image_url
    const baseUrl = `${req.protocol}://${req.get('host')}`;
    const bannersWithUrls = banners.map(banner => ({
      ...banner,
      image_url: banner.image_url ? `${baseUrl}${banner.image_url}` : '',
      id: banner._id.toString()
    }));

    res.status(200).json({
      success: true,
      data: bannersWithUrls
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get banner by ID (Admin)
 * @route   GET /api/v1/admin/settings/banners/:id
 * @access  Private (Admin)
 */
export const getBannerById = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (!id || !/^[0-9a-fA-F]{24}$/.test(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid banner ID format.'
      });
    }

    const banner = await bannerService.getBannerById(id);

    // Add full URL to image_url
    const baseUrl = `${req.protocol}://${req.get('host')}`;
    const bannerWithUrl = {
      ...banner,
      image_url: banner.image_url ? `${baseUrl}${banner.image_url}` : '',
      id: banner._id.toString()
    };

    res.status(200).json({
      success: true,
      data: bannerWithUrl
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Create banner (Admin)
 * @route   POST /api/v1/admin/settings/banners
 * @access  Private (Admin)
 */
export const createBanner = async (req, res, next) => {
  try {
    // Handle file upload error
    if (req.fileValidationError) {
      return res.status(400).json({
        success: false,
        message: req.fileValidationError
      });
    }

    const {
      title,
      subtitle,
      image_url, // Optional: can use URL instead of file upload
      action_type,
      action_value,
      display_order,
      start_date,
      end_date,
      is_active
    } = req.body;

    if (!title) {
      return res.status(400).json({
        success: false,
        message: 'Title is required'
      });
    }

    // Get image URL from uploaded file OR use provided URL
    let finalImageUrl = image_url;
    const uploadedImageUrl = getBannerImageUrl(req);
    
    if (uploadedImageUrl) {
      finalImageUrl = uploadedImageUrl;
    } else if (!image_url) {
      return res.status(400).json({
        success: false,
        message: 'Either image file or image URL is required'
      });
    }

    const adminId = req.admin?.id || null;

    const banner = await bannerService.createBanner({
      title,
      subtitle,
      image_url: finalImageUrl,
      action_type: action_type || 'none',
      action_value: action_value || '',
      display_order: display_order || 0,
      start_date: start_date || null,
      end_date: end_date || null,
      is_active: is_active !== undefined ? is_active : true
    }, adminId);

    // Add full URL to image_url
    const baseUrl = `${req.protocol}://${req.get('host')}`;
    const bannerWithUrl = {
      ...banner.toObject(),
      image_url: `${baseUrl}${banner.image_url}`,
      id: banner._id.toString()
    };

    res.status(201).json({
      success: true,
      message: 'Banner created successfully',
      data: bannerWithUrl
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Update banner (Admin)
 * @route   PUT /api/v1/admin/settings/banners/:id
 * @access  Private (Admin)
 */
export const updateBanner = async (req, res, next) => {
  try {
    // Handle file upload error
    if (req.fileValidationError) {
      return res.status(400).json({
        success: false,
        message: req.fileValidationError
      });
    }

    const { id } = req.params;

    if (!id || !/^[0-9a-fA-F]{24}$/.test(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid banner ID format.'
      });
    }

    const {
      title,
      subtitle,
      image_url,
      action_type,
      action_value,
      display_order,
      start_date,
      end_date,
      is_active
    } = req.body;

    // Get image URL from uploaded file OR use provided URL
    let finalImageUrl = image_url;
    const uploadedImageUrl = getBannerImageUrl(req);
    
    if (uploadedImageUrl) {
      finalImageUrl = uploadedImageUrl;
    }

    const adminId = req.admin?.id || null;

    const updateData = {};
    if (title !== undefined) updateData.title = title;
    if (subtitle !== undefined) updateData.subtitle = subtitle;
    if (finalImageUrl !== undefined) updateData.image_url = finalImageUrl;
    if (action_type !== undefined) updateData.action_type = action_type;
    if (action_value !== undefined) updateData.action_value = action_value;
    if (display_order !== undefined) updateData.display_order = display_order;
    if (start_date !== undefined) updateData.start_date = start_date;
    if (end_date !== undefined) updateData.end_date = end_date;
    if (is_active !== undefined) updateData.is_active = is_active;

    const banner = await bannerService.updateBanner(id, updateData, adminId);

    // Add full URL to image_url
    const baseUrl = `${req.protocol}://${req.get('host')}`;
    const bannerWithUrl = {
      ...banner.toObject(),
      image_url: `${baseUrl}${banner.image_url}`,
      id: banner._id.toString()
    };

    res.status(200).json({
      success: true,
      message: 'Banner updated successfully',
      data: bannerWithUrl
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Delete banner (Admin)
 * @route   DELETE /api/v1/admin/settings/banners/:id
 * @access  Private (Admin)
 */
export const deleteBanner = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (!id || !/^[0-9a-fA-F]{24}$/.test(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid banner ID format.'
      });
    }

    await bannerService.deleteBanner(id);

    res.status(200).json({
      success: true,
      message: 'Banner deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get active banners for customer app
 * @route   GET /api/v1/customer/banners
 * @access  Public
 */
export const getActiveBanners = async (req, res, next) => {
  try {
    const filters = {
      is_active: true,
      sort: 'display_order',
      limit: 50
    };

    const banners = await bannerService.getAllBanners(filters);

    // Add full URL to image_url
    const baseUrl = `${req.protocol}://${req.get('host')}`;
    const bannersWithUrls = banners.map(banner => ({
      id: banner._id.toString(),
      title: banner.title,
      subtitle: banner.subtitle,
      image_url: banner.image_url ? `${baseUrl}${banner.image_url}` : '',
      action_type: banner.action_type,
      action_value: banner.action_value
    }));

    res.status(200).json({
      success: true,
      data: bannersWithUrls
    });
  } catch (error) {
    next(error);
  }
};

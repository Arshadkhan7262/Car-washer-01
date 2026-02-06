import Banner from '../models/Banner.model.js';
import AppError from '../errors/AppError.js';

/**
 * Get all banners with filters
 */
export const getAllBanners = async (filters = {}) => {
  try {
    const {
      is_active,
      sort = 'display_order',
      limit = 100
    } = filters;

    const query = {};

    // Filter by active status
    if (is_active !== undefined) {
      query.is_active = is_active === 'true' || is_active === true;
    }

    // Filter by date range (only show active banners within date range)
    const now = new Date();
    query.$or = [
      { start_date: null, end_date: null }, // No date restrictions
      { start_date: { $lte: now }, end_date: null }, // Started but no end
      { start_date: null, end_date: { $gte: now } }, // No start but ends in future
      { start_date: { $lte: now }, end_date: { $gte: now } } // Within date range
    ];

    const banners = await Banner.find(query)
      .sort(sort)
      .limit(parseInt(limit))
      .populate('created_by', 'name email')
      .lean();

    return banners;
  } catch (error) {
    throw new AppError('Failed to fetch banners', 500);
  }
};

/**
 * Get banner by ID
 */
export const getBannerById = async (id) => {
  try {
    const banner = await Banner.findById(id)
      .populate('created_by', 'name email')
      .lean();

    if (!banner) {
      throw new AppError('Banner not found', 404);
    }

    return banner;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to fetch banner', 500);
  }
};

/**
 * Create banner
 */
export const createBanner = async (bannerData, adminId = null) => {
  try {
    const {
      title,
      subtitle,
      image_url,
      action_type = 'none',
      action_value = '',
      display_order = 0,
      start_date,
      end_date,
      is_active = true
    } = bannerData;

    if (!title || !image_url) {
      throw new AppError('Title and image URL are required', 400);
    }

    // Validate date range
    if (start_date && end_date && new Date(start_date) > new Date(end_date)) {
      throw new AppError('Start date must be before end date', 400);
    }

    const banner = await Banner.create({
      title,
      subtitle,
      image_url,
      action_type,
      action_value,
      display_order: parseInt(display_order) || 0,
      start_date: start_date ? new Date(start_date) : null,
      end_date: end_date ? new Date(end_date) : null,
      is_active,
      created_by: adminId
    });

    return banner;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to create banner', 500);
  }
};

/**
 * Update banner
 */
export const updateBanner = async (id, bannerData, adminId = null) => {
  try {
    const banner = await Banner.findById(id);

    if (!banner) {
      throw new AppError('Banner not found', 404);
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
    } = bannerData;

    // Update fields
    if (title !== undefined) banner.title = title;
    if (subtitle !== undefined) banner.subtitle = subtitle;
    if (image_url !== undefined) banner.image_url = image_url;
    if (action_type !== undefined) banner.action_type = action_type;
    if (action_value !== undefined) banner.action_value = action_value;
    if (display_order !== undefined) banner.display_order = parseInt(display_order) || 0;
    if (start_date !== undefined) banner.start_date = start_date ? new Date(start_date) : null;
    if (end_date !== undefined) banner.end_date = end_date ? new Date(end_date) : null;
    if (is_active !== undefined) banner.is_active = is_active;

    // Validate date range
    if (banner.start_date && banner.end_date && banner.start_date > banner.end_date) {
      throw new AppError('Start date must be before end date', 400);
    }

    await banner.save();

    return banner;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to update banner', 500);
  }
};

/**
 * Delete banner
 */
export const deleteBanner = async (id) => {
  try {
    const banner = await Banner.findByIdAndDelete(id);

    if (!banner) {
      throw new AppError('Banner not found', 404);
    }

    return banner;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to delete banner', 500);
  }
};

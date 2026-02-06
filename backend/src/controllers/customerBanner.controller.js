import * as bannerService from '../services/banner.service.js';

/**
 * @desc    Get active banners for customer app (public - no auth)
 * @route   GET /api/v1/customer/banners
 * @access  Public
 */
export const getActiveBanners = async (req, res, next) => {
  try {
    const banners = await bannerService.getActiveBanners();

    res.status(200).json({
      success: true,
      data: banners
    });
  } catch (error) {
    next(error);
  }
};

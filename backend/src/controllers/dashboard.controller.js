import * as dashboardService from '../services/dashboard.service.js';

/**
 * @desc    Get Dashboard KPIs
 * @route   GET /api/v1/admin/dashboard/kpis
 * @access  Private (Admin)
 */
export const getKPIs = async (req, res, next) => {
  try {
    const kpis = await dashboardService.getDashboardKPIs();

    res.status(200).json({
      success: true,
      data: kpis
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get Dashboard Stats (Bookings trend, Revenue trend, Service popularity)
 * @route   GET /api/v1/admin/dashboard/stats
 * @access  Private (Admin)
 */
export const getStats = async (req, res, next) => {
  try {
    const { period = 'week' } = req.query;
    
    const stats = await dashboardService.getDashboardStats(period);

    res.status(200).json({
      success: true,
      data: stats
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get Recent Activity Feed
 * @route   GET /api/v1/admin/dashboard/activity
 * @access  Private (Admin)
 */
export const getActivity = async (req, res, next) => {
  try {
    const { limit = 10 } = req.query;
    const limitNum = parseInt(limit, 10) || 10;

    const activities = await dashboardService.getRecentActivity(limitNum);

    res.status(200).json({
      success: true,
      data: activities
    });
  } catch (error) {
    next(error);
  }
};




import * as serviceService from '../services/service.service.js';

/**
 * @desc    Get all active services (public endpoint for customers)
 * @route   GET /api/v1/customer/services
 * @access  Public
 */
export const getAllServices = async (req, res, next) => {
  try {
    const filters = {
      is_active: true, // Only return active services
      is_popular: req.query.is_popular, // Optional filter for popular services
      sort: req.query.sort || 'display_order',
      limit: req.query.limit || 50
    };

    const services = await serviceService.getAllServices(filters);

    res.status(200).json({
      success: true,
      data: services
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get service by ID (public endpoint for customers)
 * @route   GET /api/v1/customer/services/:id
 * @access  Public
 */
export const getServiceById = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Validate ObjectId format
    if (!id || id === ':id' || !/^[0-9a-fA-F]{24}$/.test(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid service ID format. Please provide a valid MongoDB ObjectId.'
      });
    }

    const service = await serviceService.getServiceById(id);

    // Only return if service is active
    if (!service.is_active) {
      return res.status(404).json({
        success: false,
        message: 'Service not found'
      });
    }

    res.status(200).json({
      success: true,
      data: service
    });
  } catch (error) {
    next(error);
  }
};




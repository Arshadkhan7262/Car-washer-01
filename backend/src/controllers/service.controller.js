import * as serviceService from '../services/service.service.js';

/**
 * @desc    Get all services
 * @route   GET /api/v1/admin/services
 * @access  Private (Admin)
 */
export const getAllServices = async (req, res, next) => {
  try {
    const filters = {
      is_active: req.query.is_active,
      is_popular: req.query.is_popular,
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
 * @desc    Get service by ID
 * @route   GET /api/v1/admin/services/:id
 * @access  Private (Admin)
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

    res.status(200).json({
      success: true,
      data: service
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Create new service
 * @route   POST /api/v1/admin/services
 * @access  Private (Admin)
 */
export const createService = async (req, res, next) => {
  try {
    const service = await serviceService.createService(req.body);

    res.status(201).json({
      success: true,
      data: service
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Update service
 * @route   PUT /api/v1/admin/services/:id
 * @access  Private (Admin)
 */
export const updateService = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Validate ObjectId format
    if (!id || id === ':id' || !/^[0-9a-fA-F]{24}$/.test(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid service ID format. Please provide a valid MongoDB ObjectId.'
      });
    }

    const service = await serviceService.updateService(id, req.body);

    res.status(200).json({
      success: true,
      data: service
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Delete service
 * @route   DELETE /api/v1/admin/services/:id
 * @access  Private (Admin)
 */
export const deleteService = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Validate ObjectId format
    if (!id || id === ':id' || !/^[0-9a-fA-F]{24}$/.test(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid service ID format. Please provide a valid MongoDB ObjectId.'
      });
    }

    const result = await serviceService.deleteService(id);

    res.status(200).json({
      success: true,
      message: result.message
    });
  } catch (error) {
    next(error);
  }
};


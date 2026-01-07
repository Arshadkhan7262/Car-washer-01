import * as washerService from '../services/washer.service.js';

/**
 * @desc    Get all washers with filters
 * @route   GET /api/v1/admin/washers
 * @access  Private (Admin)
 */
export const getAllWashers = async (req, res, next) => {
  try {
    const filters = {
      status: req.query.status,
      online_status: req.query.online_status,
      search: req.query.search,
      page: req.query.page || 1,
      limit: req.query.limit || 20,
      sort: req.query.sort || '-created_date'
    };

    const result = await washerService.getAllWashers(filters);

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get washer by ID with profile
 * @route   GET /api/v1/admin/washers/:id
 * @access  Private (Admin)
 */
export const getWasherById = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Validate ObjectId format
    if (!id || id === ':id' || !/^[0-9a-fA-F]{24}$/.test(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid washer ID format. Please provide a valid MongoDB ObjectId.'
      });
    }

    const washer = await washerService.getWasherById(id);

    res.status(200).json({
      success: true,
      data: washer
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Create new washer
 * @route   POST /api/v1/admin/washers
 * @access  Private (Admin)
 */
export const createWasher = async (req, res, next) => {
  try {
    const { user_id, name, phone, email, status, online_status } = req.body;

    if (!user_id && !phone) {
      return res.status(400).json({
        success: false,
        message: 'Either user_id or phone is required'
      });
    }

    const washerData = {
      user_id,
      name,
      phone,
      email,
      status,
      online_status
    };

    const washer = await washerService.createWasher(washerData);

    res.status(201).json({
      success: true,
      data: washer
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Update washer
 * @route   PUT /api/v1/admin/washers/:id
 * @access  Private (Admin)
 */
export const updateWasher = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Validate ObjectId format
    if (!id || id === ':id' || !/^[0-9a-fA-F]{24}$/.test(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid washer ID format. Please provide a valid MongoDB ObjectId.'
      });
    }

    const washer = await washerService.updateWasher(id, req.body);

    res.status(200).json({
      success: true,
      data: washer
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Delete washer
 * @route   DELETE /api/v1/admin/washers/:id
 * @access  Private (Admin)
 */
export const deleteWasher = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Validate ObjectId format
    if (!id || id === ':id' || !/^[0-9a-fA-F]{24}$/.test(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid washer ID format. Please provide a valid MongoDB ObjectId.'
      });
    }

    const result = await washerService.deleteWasher(id);

    res.status(200).json({
      success: true,
      message: result.message
    });
  } catch (error) {
    next(error);
  }
};


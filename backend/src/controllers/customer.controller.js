import * as customerService from '../services/customer.service.js';

/**
 * @desc    Get all customers with filters
 * @route   GET /api/v1/admin/customers
 * @access  Private (Admin)
 */
export const getAllCustomers = async (req, res, next) => {
  try {
    const filters = {
      is_active: req.query.is_active,
      is_blocked: req.query.is_blocked,
      search: req.query.search,
      page: req.query.page || 1,
      limit: req.query.limit || 20,
      sort: req.query.sort || '-created_date'
    };

    const result = await customerService.getAllCustomers(filters);

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get customer by ID with profile
 * @route   GET /api/v1/admin/customers/:id
 * @access  Private (Admin)
 */
export const getCustomerById = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Validate ObjectId format
    if (!id || id === ':id' || !/^[0-9a-fA-F]{24}$/.test(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid customer ID format. Please provide a valid MongoDB ObjectId.'
      });
    }

    const customer = await customerService.getCustomerById(id);

    res.status(200).json({
      success: true,
      data: customer
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Create customer (Admin)
 * @route   POST /api/v1/admin/customers
 * @access  Private (Admin)
 */
export const createCustomer = async (req, res, next) => {
  try {
    const customer = await customerService.createCustomer(req.body);

    res.status(201).json({
      success: true,
      data: customer,
      message: 'Customer created successfully. Email is verified and account is active.'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Update customer
 * @route   PUT /api/v1/admin/customers/:id
 * @access  Private (Admin)
 */
export const updateCustomer = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Validate ObjectId format
    if (!id || id === ':id' || !/^[0-9a-fA-F]{24}$/.test(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid customer ID format. Please provide a valid MongoDB ObjectId.'
      });
    }

    const customer = await customerService.updateCustomer(id, req.body);

    res.status(200).json({
      success: true,
      data: customer
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get customer booking history
 * @route   GET /api/v1/admin/customers/:id/bookings
 * @access  Private (Admin)
 */
export const getCustomerBookings = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Validate ObjectId format
    if (!id || id === ':id' || !/^[0-9a-fA-F]{24}$/.test(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid customer ID format. Please provide a valid MongoDB ObjectId.'
      });
    }

    const filters = {
      status: req.query.status,
      page: req.query.page || 1,
      limit: req.query.limit || 20,
      sort: req.query.sort || '-created_date'
    };

    const result = await customerService.getCustomerBookings(id, filters);

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};


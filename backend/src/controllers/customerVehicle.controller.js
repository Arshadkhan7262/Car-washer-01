/**
 * Customer Vehicle Controller
 * Handles HTTP requests for customer vehicle management (wash_away app)
 */

import * as customerVehicleService from '../services/customerVehicle.service.js';

/**
 * @desc    Get all customer vehicles
 * @route   GET /api/v1/customer/vehicles
 * @access  Private (Customer)
 */
export const getCustomerVehicles = async (req, res, next) => {
  try {
    const customerId = req.customer.id;

    if (!customerId) {
      return res.status(400).json({
        success: false,
        message: 'Customer ID not found in token'
      });
    }

    const vehicles = await customerVehicleService.getCustomerVehicles(customerId);

    res.status(200).json({
      success: true,
      data: vehicles
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Create a new customer vehicle
 * @route   POST /api/v1/customer/vehicles
 * @access  Private (Customer)
 */
export const createCustomerVehicle = async (req, res, next) => {
  try {
    const customerId = req.customer.id;

    if (!customerId) {
      return res.status(400).json({
        success: false,
        message: 'Customer ID not found in token'
      });
    }

    const vehicle = await customerVehicleService.createCustomerVehicle(customerId, req.body);

    res.status(201).json({
      success: true,
      data: vehicle
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Update a customer vehicle
 * @route   PUT /api/v1/customer/vehicles/:id
 * @access  Private (Customer)
 */
export const updateCustomerVehicle = async (req, res, next) => {
  try {
    const customerId = req.customer.id;
    const vehicleId = req.params.id;

    if (!customerId) {
      return res.status(400).json({
        success: false,
        message: 'Customer ID not found in token'
      });
    }

    const vehicle = await customerVehicleService.updateCustomerVehicle(customerId, vehicleId, req.body);

    res.status(200).json({
      success: true,
      data: vehicle
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Delete a customer vehicle
 * @route   DELETE /api/v1/customer/vehicles/:id
 * @access  Private (Customer)
 */
export const deleteCustomerVehicle = async (req, res, next) => {
  try {
    const customerId = req.customer.id;
    const vehicleId = req.params.id;

    if (!customerId) {
      return res.status(400).json({
        success: false,
        message: 'Customer ID not found in token'
      });
    }

    await customerVehicleService.deleteCustomerVehicle(customerId, vehicleId);

    res.status(200).json({
      success: true,
      message: 'Vehicle deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Set a vehicle as default
 * @route   PUT /api/v1/customer/vehicles/:id/default
 * @access  Private (Customer)
 */
export const setDefaultVehicle = async (req, res, next) => {
  try {
    const customerId = req.customer.id;
    const vehicleId = req.params.id;

    if (!customerId) {
      return res.status(400).json({
        success: false,
        message: 'Customer ID not found in token'
      });
    }

    const vehicle = await customerVehicleService.setDefaultVehicle(customerId, vehicleId);

    res.status(200).json({
      success: true,
      data: vehicle
    });
  } catch (error) {
    next(error);
  }
};


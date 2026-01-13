/**
 * Customer Address Controller
 * Handles HTTP requests for customer address management (wash_away app)
 */

import * as customerAddressService from '../services/customerAddress.service.js';

/**
 * @desc    Get all customer addresses
 * @route   GET /api/v1/customer/addresses
 * @access  Private (Customer)
 */
export const getCustomerAddresses = async (req, res, next) => {
  try {
    const customerId = req.customer.id;

    if (!customerId) {
      return res.status(400).json({
        success: false,
        message: 'Customer ID not found in token'
      });
    }

    const addresses = await customerAddressService.getCustomerAddresses(customerId);

    res.status(200).json({
      success: true,
      data: addresses
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Create a new customer address
 * @route   POST /api/v1/customer/addresses
 * @access  Private (Customer)
 */
export const createCustomerAddress = async (req, res, next) => {
  try {
    const customerId = req.customer.id;

    if (!customerId) {
      return res.status(400).json({
        success: false,
        message: 'Customer ID not found in token'
      });
    }

    const address = await customerAddressService.createCustomerAddress(customerId, req.body);

    res.status(201).json({
      success: true,
      data: address
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Update a customer address
 * @route   PUT /api/v1/customer/addresses/:id
 * @access  Private (Customer)
 */
export const updateCustomerAddress = async (req, res, next) => {
  try {
    const customerId = req.customer.id;
    const addressId = req.params.id;

    if (!customerId) {
      return res.status(400).json({
        success: false,
        message: 'Customer ID not found in token'
      });
    }

    const address = await customerAddressService.updateCustomerAddress(customerId, addressId, req.body);

    res.status(200).json({
      success: true,
      data: address
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Delete a customer address
 * @route   DELETE /api/v1/customer/addresses/:id
 * @access  Private (Customer)
 */
export const deleteCustomerAddress = async (req, res, next) => {
  try {
    const customerId = req.customer.id;
    const addressId = req.params.id;

    if (!customerId) {
      return res.status(400).json({
        success: false,
        message: 'Customer ID not found in token'
      });
    }

    await customerAddressService.deleteCustomerAddress(customerId, addressId);

    res.status(200).json({
      success: true,
      message: 'Address deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Set an address as default
 * @route   PUT /api/v1/customer/addresses/:id/default
 * @access  Private (Customer)
 */
export const setDefaultAddress = async (req, res, next) => {
  try {
    const customerId = req.customer.id;
    const addressId = req.params.id;

    if (!customerId) {
      return res.status(400).json({
        success: false,
        message: 'Customer ID not found in token'
      });
    }

    const address = await customerAddressService.setDefaultAddress(customerId, addressId);

    res.status(200).json({
      success: true,
      data: address
    });
  } catch (error) {
    next(error);
  }
};


import * as vehicleTypeService from '../services/vehicleType.service.js';
import { getImageUrl } from '../middleware/upload.middleware.js';
import AppError from '../errors/AppError.js';

/**
 * @desc    Get all vehicle types
 * @route   GET /api/v1/admin/vehicle-types
 * @access  Private (Admin)
 */
export const getAllVehicleTypes = async (req, res, next) => {
  try {
    const filters = {
      is_active: req.query.is_active,
      sort: req.query.sort || 'display_order',
      limit: req.query.limit || 50
    };

    const vehicleTypes = await vehicleTypeService.getAllVehicleTypes(filters);

    // Add full URL to image_url
    const baseUrl = `${req.protocol}://${req.get('host')}`;
    const vehicleTypesWithUrls = vehicleTypes.map(vt => ({
      ...vt.toObject(),
      image_url: vt.image_url ? `${baseUrl}${vt.image_url}` : ''
    }));

    res.status(200).json({
      success: true,
      data: vehicleTypesWithUrls
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get vehicle type by ID
 * @route   GET /api/v1/admin/vehicle-types/:id
 * @access  Private (Admin)
 */
export const getVehicleTypeById = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (!id || id === ':id' || !/^[0-9a-fA-F]{24}$/.test(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid vehicle type ID format.'
      });
    }

    const vehicleType = await vehicleTypeService.getVehicleTypeById(id);

    res.status(200).json({
      success: true,
      data: vehicleType
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Create vehicle type
 * @route   POST /api/v1/admin/vehicle-types
 * @access  Private (Admin)
 */
export const createVehicleType = async (req, res, next) => {
  try {
    // Handle file upload error
    if (req.fileValidationError) {
      return res.status(400).json({
        success: false,
        message: req.fileValidationError
      });
    }

    const { name, display_name } = req.body;

    if (!name || !display_name) {
      return res.status(400).json({
        success: false,
        message: 'Name and display_name are required'
      });
    }

    // Get image URL from uploaded file
    const imageUrl = getImageUrl(req);
    if (!imageUrl) {
      return res.status(400).json({
        success: false,
        message: 'Image is required'
      });
    }

    const vehicleType = await vehicleTypeService.createVehicleType({
      name,
      display_name,
      image_url: imageUrl,
      display_order: 0,
      is_active: true
    });

    // Add full URL to response
    const baseUrl = `${req.protocol}://${req.get('host')}`;
    const vehicleTypeObj = vehicleType.toObject();
    vehicleTypeObj.image_url = `${baseUrl}${imageUrl}`;

    res.status(201).json({
      success: true,
      data: vehicleTypeObj
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Update vehicle type
 * @route   PUT /api/v1/admin/vehicle-types/:id
 * @access  Private (Admin)
 */
export const updateVehicleType = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (!id || id === ':id' || !/^[0-9a-fA-F]{24}$/.test(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid vehicle type ID format.'
      });
    }

    // Handle file upload error
    if (req.fileValidationError) {
      return res.status(400).json({
        success: false,
        message: req.fileValidationError
      });
    }

    const updateData = { ...req.body };

    // If new image is uploaded, update image_url
    const imageUrl = getImageUrl(req);
    if (imageUrl) {
      updateData.image_url = imageUrl;
    }

    const vehicleType = await vehicleTypeService.updateVehicleType(id, updateData);

    // Add full URL to response
    const baseUrl = `${req.protocol}://${req.get('host')}`;
    const vehicleTypeObj = vehicleType.toObject();
    if (vehicleTypeObj.image_url) {
      vehicleTypeObj.image_url = `${baseUrl}${vehicleTypeObj.image_url}`;
    }

    res.status(200).json({
      success: true,
      data: vehicleTypeObj
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Delete vehicle type
 * @route   DELETE /api/v1/admin/vehicle-types/:id
 * @access  Private (Admin)
 */
export const deleteVehicleType = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (!id || id === ':id' || !/^[0-9a-fA-F]{24}$/.test(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid vehicle type ID format.'
      });
    }

    await vehicleTypeService.deleteVehicleType(id);

    res.status(200).json({
      success: true,
      message: 'Vehicle type deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};


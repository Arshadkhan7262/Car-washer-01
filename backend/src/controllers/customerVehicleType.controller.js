import * as vehicleTypeService from '../services/vehicleType.service.js';

/**
 * @desc    Get all active vehicle types (for customers)
 * @route   GET /api/v1/customer/vehicle-types
 * @access  Public
 */
export const getAllVehicleTypes = async (req, res, next) => {
  try {
    const vehicleTypes = await vehicleTypeService.getAllVehicleTypes({
      is_active: true,
      sort: 'display_order',
      limit: 50
    });

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


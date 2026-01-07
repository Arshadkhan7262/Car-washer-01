import VehicleType from '../models/VehicleType.model.js';
import AppError from '../errors/AppError.js';

/**
 * Get all vehicle types
 */
export const getAllVehicleTypes = async (filters = {}) => {
  const query = {};
  
  if (filters.is_active !== undefined) {
    query.is_active = filters.is_active === 'true' || filters.is_active === true;
  }

  const sort = filters.sort || 'display_order';
  const limit = parseInt(filters.limit) || 50;

  const vehicleTypes = await VehicleType.find(query)
    .sort({ [sort]: 1 })
    .limit(limit);

  return vehicleTypes;
};

/**
 * Get vehicle type by ID
 */
export const getVehicleTypeById = async (id) => {
  const vehicleType = await VehicleType.findById(id);
  
  if (!vehicleType) {
    throw new AppError('Vehicle type not found', 404);
  }

  return vehicleType;
};

/**
 * Create vehicle type
 */
export const createVehicleType = async (data) => {
  // Check if vehicle type with same name already exists
  const existing = await VehicleType.findOne({ name: data.name.toLowerCase() });
  if (existing) {
    throw new AppError('Vehicle type with this name already exists', 400);
  }

  const vehicleType = await VehicleType.create({
    name: data.name.toLowerCase(),
    display_name: data.display_name,
    image_url: data.image_url || '',
    icon_path: data.icon_path || '',
    display_order: data.display_order || 0,
    is_active: data.is_active !== undefined ? data.is_active : true
  });

  return vehicleType;
};

/**
 * Update vehicle type
 */
export const updateVehicleType = async (id, data) => {
  const vehicleType = await VehicleType.findById(id);
  
  if (!vehicleType) {
    throw new AppError('Vehicle type not found', 404);
  }

  // Check if name is being changed and if it conflicts with existing
  if (data.name && data.name.toLowerCase() !== vehicleType.name) {
    const existing = await VehicleType.findOne({ name: data.name.toLowerCase() });
    if (existing) {
      throw new AppError('Vehicle type with this name already exists', 400);
    }
    data.name = data.name.toLowerCase();
  }

  Object.assign(vehicleType, data);
  await vehicleType.save();

  return vehicleType;
};

/**
 * Delete vehicle type
 */
export const deleteVehicleType = async (id) => {
  const vehicleType = await VehicleType.findById(id);
  
  if (!vehicleType) {
    throw new AppError('Vehicle type not found', 404);
  }

  await VehicleType.findByIdAndDelete(id);
  return { message: 'Vehicle type deleted successfully' };
};


import Vehicle from '../models/Vehicle.model.js';
import AppError from '../errors/AppError.js';

/**
 * Get all vehicles for a customer
 */
export const getCustomerVehicles = async (customerId) => {
  const vehicles = await Vehicle.find({ customer_id: customerId })
    .sort({ is_default: -1, created_date: -1 })
    .lean();

  // Map backend fields to frontend expected format
  return vehicles.map(vehicle => ({
    _id: vehicle._id,
    id: vehicle._id.toString(),
    make: vehicle.brand || '',
    model: vehicle.model || '',
    plate_number: vehicle.plate_number || '',
    color: vehicle.color || '', // Note: backend model may not have color field
    type: vehicle.type ? vehicle.type.charAt(0).toUpperCase() + vehicle.type.slice(1) : '',
    is_default: vehicle.is_default || false,
    created_date: vehicle.created_date,
    updated_date: vehicle.updated_date
  }));
};

/**
 * Create a new vehicle for a customer
 */
export const createCustomerVehicle = async (customerId, vehicleData) => {
  const { make, model, plate_number, color, type, is_default } = vehicleData;

  // Normalize type to lowercase for enum
  const normalizedType = type ? type.toLowerCase() : 'sedan';
  const validTypes = ['sedan', 'suv', 'truck', 'van', 'motorcycle', 'luxury'];
  if (!validTypes.includes(normalizedType)) {
    throw new AppError(`Invalid vehicle type. Must be one of: ${validTypes.join(', ')}`, 400);
  }

  // Check if plate number already exists
  const existingVehicle = await Vehicle.findOne({ plate_number });
  if (existingVehicle && existingVehicle.customer_id.toString() !== customerId.toString()) {
    throw new AppError('Plate number already registered to another customer', 400);
  }

  // If setting as default, unset other defaults
  if (is_default) {
    await Vehicle.updateMany(
      { customer_id: customerId, is_default: true },
      { is_default: false }
    );
  }

  const vehicle = new Vehicle({
    customer_id: customerId,
    brand: make,
    model,
    plate_number,
    color, // Store color even if model doesn't have it yet
    type: normalizedType,
    is_default: is_default || false
  });

  await vehicle.save();

  return {
    _id: vehicle._id,
    id: vehicle._id.toString(),
    make: vehicle.brand,
    model: vehicle.model,
    plate_number: vehicle.plate_number,
    color: vehicle.color || '',
    type: vehicle.type ? vehicle.type.charAt(0).toUpperCase() + vehicle.type.slice(1) : '',
    is_default: vehicle.is_default,
    created_date: vehicle.created_date,
    updated_date: vehicle.updated_date
  };
};

/**
 * Update a vehicle
 */
export const updateCustomerVehicle = async (customerId, vehicleId, vehicleData) => {
  const vehicle = await Vehicle.findOne({
    _id: vehicleId,
    customer_id: customerId
  });

  if (!vehicle) {
    throw new AppError('Vehicle not found', 404);
  }

  const { make, model, plate_number, color, type, is_default } = vehicleData;

  if (make !== undefined) vehicle.brand = make;
  if (model !== undefined) vehicle.model = model;
  if (plate_number !== undefined) {
    // Check if plate number already exists for another vehicle
    const existingVehicle = await Vehicle.findOne({ 
      plate_number,
      _id: { $ne: vehicleId }
    });
    if (existingVehicle) {
      throw new AppError('Plate number already registered to another vehicle', 400);
    }
    vehicle.plate_number = plate_number;
  }
  if (color !== undefined) vehicle.color = color;
  
  if (type) {
    const normalizedType = type.toLowerCase();
    const validTypes = ['sedan', 'suv', 'truck', 'van', 'motorcycle', 'luxury'];
    if (!validTypes.includes(normalizedType)) {
      throw new AppError(`Invalid vehicle type. Must be one of: ${validTypes.join(', ')}`, 400);
    }
    vehicle.type = normalizedType;
  }

  // Handle default flag
  if (is_default !== undefined) {
    if (is_default && !vehicle.is_default) {
      // Unset other defaults
      await Vehicle.updateMany(
        { customer_id: customerId, is_default: true, _id: { $ne: vehicleId } },
        { is_default: false }
      );
    }
    vehicle.is_default = is_default;
  }

  await vehicle.save();

  return {
    _id: vehicle._id,
    id: vehicle._id.toString(),
    make: vehicle.brand,
    model: vehicle.model,
    plate_number: vehicle.plate_number,
    color: vehicle.color || '',
    type: vehicle.type ? vehicle.type.charAt(0).toUpperCase() + vehicle.type.slice(1) : '',
    is_default: vehicle.is_default,
    created_date: vehicle.created_date,
    updated_date: vehicle.updated_date
  };
};

/**
 * Delete a vehicle
 */
export const deleteCustomerVehicle = async (customerId, vehicleId) => {
  const vehicle = await Vehicle.findOneAndDelete({
    _id: vehicleId,
    customer_id: customerId
  });

  if (!vehicle) {
    throw new AppError('Vehicle not found', 404);
  }

  return { success: true };
};

/**
 * Set a vehicle as default
 */
export const setDefaultVehicle = async (customerId, vehicleId) => {
  const vehicle = await Vehicle.findOne({
    _id: vehicleId,
    customer_id: customerId
  });

  if (!vehicle) {
    throw new AppError('Vehicle not found', 404);
  }

  // Unset other defaults
  await Vehicle.updateMany(
    { customer_id: customerId, is_default: true, _id: { $ne: vehicleId } },
    { is_default: false }
  );

  // Set this as default
  vehicle.is_default = true;
  await vehicle.save();

  return {
    _id: vehicle._id,
    id: vehicle._id.toString(),
    make: vehicle.brand,
    model: vehicle.model,
    plate_number: vehicle.plate_number,
    color: vehicle.color || '',
    type: vehicle.type ? vehicle.type.charAt(0).toUpperCase() + vehicle.type.slice(1) : '',
    is_default: vehicle.is_default,
    created_date: vehicle.created_date,
    updated_date: vehicle.updated_date
  };
};


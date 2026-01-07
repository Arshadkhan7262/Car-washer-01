import Service from '../models/Service.model.js';
import AppError from '../errors/AppError.js';

/**
 * Get all services
 */
export const getAllServices = async (filters = {}) => {
  const {
    is_active,
    is_popular,
    sort = 'display_order',
    limit = 50
  } = filters;

  const query = {};

  if (is_active !== undefined) {
    query.is_active = is_active === 'true' || is_active === true;
  }

  if (is_popular !== undefined) {
    query.is_popular = is_popular === 'true' || is_popular === true;
  }

  // Parse sort
  const sortField = sort.startsWith('-') ? sort.substring(1) : sort;
  const sortOrder = sort.startsWith('-') ? -1 : 1;
  const sortObj = { [sortField]: sortOrder };

  const services = await Service.find(query)
    .sort(sortObj)
    .limit(parseInt(limit))
    .lean();

  return services;
};

/**
 * Get service by ID
 */
export const getServiceById = async (serviceId) => {
  const service = await Service.findById(serviceId).lean();

  if (!service) {
    throw new AppError('Service not found', 404);
  }

  return service;
};

/**
 * Create new service
 */
export const createService = async (serviceData) => {
  // Validate required fields
  if (!serviceData.name || !serviceData.base_price) {
    throw new AppError('Service name and base price are required', 400);
  }

  // Convert pricing object to Map if provided
  if (serviceData.pricing && typeof serviceData.pricing === 'object' && !(serviceData.pricing instanceof Map)) {
    const pricingMap = new Map();
    Object.entries(serviceData.pricing).forEach(([key, value]) => {
      pricingMap.set(key, parseFloat(value));
    });
    serviceData.pricing = pricingMap;
  }

  const service = await Service.create(serviceData);

  return await Service.findById(service._id).lean();
};

/**
 * Update service
 */
export const updateService = async (serviceId, updateData) => {
  const service = await Service.findById(serviceId);

  if (!service) {
    throw new AppError('Service not found', 404);
  }

  // Convert pricing object to Map if provided
  if (updateData.pricing && typeof updateData.pricing === 'object' && !(updateData.pricing instanceof Map)) {
    const pricingMap = new Map();
    Object.entries(updateData.pricing).forEach(([key, value]) => {
      pricingMap.set(key, parseFloat(value));
    });
    updateData.pricing = pricingMap;
  }

  Object.assign(service, updateData);
  await service.save();

  return await Service.findById(serviceId).lean();
};

/**
 * Delete service
 */
export const deleteService = async (serviceId) => {
  const service = await Service.findById(serviceId);

  if (!service) {
    throw new AppError('Service not found', 404);
  }

  await Service.findByIdAndDelete(serviceId);

  return { message: 'Service deleted successfully' };
};


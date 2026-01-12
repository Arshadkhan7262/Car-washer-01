import Address from '../models/Address.model.js';
import AppError from '../errors/AppError.js';

/**
 * Get all addresses for a customer
 */
export const getCustomerAddresses = async (customerId) => {
  const addresses = await Address.find({ customer_id: customerId })
    .sort({ is_default: -1, created_date: -1 })
    .lean();

  // Map backend fields to frontend expected format
  return addresses.map(addr => ({
    _id: addr._id,
    id: addr._id.toString(),
    label: addr.label ? addr.label.charAt(0).toUpperCase() + addr.label.slice(1) : 'Other',
    full_address: addr.address_line || '',
    latitude: addr.latitude,
    longitude: addr.longitude,
    is_default: addr.is_default || false,
    created_date: addr.created_date,
    updated_date: addr.updated_date
  }));
};

/**
 * Create a new address for a customer
 */
export const createCustomerAddress = async (customerId, addressData) => {
  const { label, full_address, latitude, longitude, is_default } = addressData;

  // Normalize label to lowercase for enum
  const normalizedLabel = label ? label.toLowerCase() : 'other';
  if (!['home', 'office', 'other'].includes(normalizedLabel)) {
    throw new AppError('Invalid label. Must be Home, Office, or Other', 400);
  }

  // If setting as default, unset other defaults
  if (is_default) {
    await Address.updateMany(
      { customer_id: customerId, is_default: true },
      { is_default: false }
    );
  }

  const address = new Address({
    customer_id: customerId,
    label: normalizedLabel,
    address_line: full_address,
    latitude,
    longitude,
    is_default: is_default || false
  });

  await address.save();

  return {
    _id: address._id,
    id: address._id.toString(),
    label: label,
    full_address: address.address_line,
    latitude: address.latitude,
    longitude: address.longitude,
    is_default: address.is_default,
    created_date: address.created_date,
    updated_date: address.updated_date
  };
};

/**
 * Update an address
 */
export const updateCustomerAddress = async (customerId, addressId, addressData) => {
  const address = await Address.findOne({
    _id: addressId,
    customer_id: customerId
  });

  if (!address) {
    throw new AppError('Address not found', 404);
  }

  const { label, full_address, latitude, longitude, is_default } = addressData;

  if (label) {
    const normalizedLabel = label.toLowerCase();
    if (!['home', 'office', 'other'].includes(normalizedLabel)) {
      throw new AppError('Invalid label. Must be Home, Office, or Other', 400);
    }
    address.label = normalizedLabel;
  }

  if (full_address !== undefined) {
    address.address_line = full_address;
  }
  if (latitude !== undefined) address.latitude = latitude;
  if (longitude !== undefined) address.longitude = longitude;

  // Handle default flag
  if (is_default !== undefined) {
    if (is_default && !address.is_default) {
      // Unset other defaults
      await Address.updateMany(
        { customer_id: customerId, is_default: true, _id: { $ne: addressId } },
        { is_default: false }
      );
    }
    address.is_default = is_default;
  }

  await address.save();

  return {
    _id: address._id,
    id: address._id.toString(),
    label: address.label ? address.label.charAt(0).toUpperCase() + address.label.slice(1) : 'Other',
    full_address: address.address_line,
    latitude: address.latitude,
    longitude: address.longitude,
    is_default: address.is_default,
    created_date: address.created_date,
    updated_date: address.updated_date
  };
};

/**
 * Delete an address
 */
export const deleteCustomerAddress = async (customerId, addressId) => {
  const address = await Address.findOneAndDelete({
    _id: addressId,
    customer_id: customerId
  });

  if (!address) {
    throw new AppError('Address not found', 404);
  }

  return { success: true };
};

/**
 * Set an address as default
 */
export const setDefaultAddress = async (customerId, addressId) => {
  const address = await Address.findOne({
    _id: addressId,
    customer_id: customerId
  });

  if (!address) {
    throw new AppError('Address not found', 404);
  }

  // Unset other defaults
  await Address.updateMany(
    { customer_id: customerId, is_default: true, _id: { $ne: addressId } },
    { is_default: false }
  );

  // Set this as default
  address.is_default = true;
  await address.save();

  return {
    _id: address._id,
    id: address._id.toString(),
    label: address.label ? address.label.charAt(0).toUpperCase() + address.label.slice(1) : 'Other',
    full_address: address.address_line,
    latitude: address.latitude,
    longitude: address.longitude,
    is_default: address.is_default,
    created_date: address.created_date,
    updated_date: address.updated_date
  };
};


import User from '../models/User.model.js';
import Booking from '../models/Booking.model.js';
import Vehicle from '../models/Vehicle.model.js';
import Address from '../models/Address.model.js';
import AppError from '../errors/AppError.js';

/**
 * Get all customers with filters
 */
export const getAllCustomers = async (filters = {}) => {
  const {
    is_active,
    is_blocked,
    role = 'customer',
    search,
    page = 1,
    limit = 20,
    sort = '-created_date'
  } = filters;

  const query = { role };

  if (is_active !== undefined) {
    query.is_active = is_active === 'true' || is_active === true;
  }

  if (is_blocked !== undefined) {
    query.is_blocked = is_blocked === 'true' || is_blocked === true;
  }

  if (search) {
    query.$or = [
      { name: { $regex: search, $options: 'i' } },
      { email: { $regex: search, $options: 'i' } },
      { phone: { $regex: search, $options: 'i' } }
    ];
  }

  // Parse sort
  const sortField = sort.startsWith('-') ? sort.substring(1) : sort;
  const sortOrder = sort.startsWith('-') ? -1 : 1;
  const sortObj = { [sortField]: sortOrder };

  // Calculate pagination
  const skip = (parseInt(page) - 1) * parseInt(limit);

  const customers = await User.find(query)
    .select('-password')
    .sort(sortObj)
    .skip(skip)
    .limit(parseInt(limit))
    .lean();

  const total = await User.countDocuments(query);

  return {
    customers,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total,
      totalPages: Math.ceil(total / parseInt(limit))
    }
  };
};

/**
 * Get customer by ID with profile details
 */
export const getCustomerById = async (customerId) => {
  const customer = await User.findById(customerId)
    .select('-password')
    .lean();

  if (!customer) {
    throw new AppError('Customer not found', 404);
  }

  if (customer.role !== 'customer') {
    throw new AppError('User is not a customer', 400);
  }

  // Get vehicles
  const vehicles = await Vehicle.find({ customer_id: customerId })
    .sort({ is_default: -1, created_date: -1 })
    .lean();

  // Get addresses
  const addresses = await Address.find({ customer_id: customerId })
    .sort({ is_default: -1, created_date: -1 })
    .lean();

  // Get booking count
  const bookingCount = await Booking.countDocuments({ customer_id: customerId });

  return {
    ...customer,
    vehicles,
    addresses,
    bookingCount
  };
};

/**
 * Update customer
 * If admin adds customer (sets email), auto-verify email and set active
 */
export const updateCustomer = async (customerId, updateData) => {
  const customer = await User.findById(customerId);

  if (!customer) {
    throw new AppError('Customer not found', 404);
  }

  if (customer.role !== 'customer') {
    throw new AppError('User is not a customer', 400);
  }

  // Don't allow role change
  if (updateData.role && updateData.role !== 'customer') {
    delete updateData.role;
  }

  // If admin is adding/updating email, auto-verify it and ensure account is active
  if (updateData.email) {
    updateData.email_verified = true; // Admin-added customers have verified email
    updateData.is_active = true; // Customers are always active
  }

  // If admin is explicitly setting is_active or email_verified, respect those values
  // But ensure customers are always active
  if (updateData.is_active !== undefined) {
    updateData.is_active = true; // Customers are always active (can't be deactivated via this endpoint)
  }

  Object.assign(customer, updateData);
  await customer.save();

  return await User.findById(customerId).select('-password').lean();
};

/**
 * Create customer (for admin)
 * Admin-created customers: email_verified=true, is_active=true
 */
export const createCustomer = async (customerData) => {
  // Check if email already exists
  if (customerData.email) {
    const normalizedEmail = customerData.email.toLowerCase().trim();
    const existingEmail = await User.findOne({ email: normalizedEmail, role: 'customer' });
    if (existingEmail) {
      throw new AppError('Email already registered', 400);
    }
    customerData.email = normalizedEmail;
  }

  // Check if phone already exists
  if (customerData.phone) {
    const existingPhone = await User.findOne({ phone: customerData.phone, role: 'customer' });
    if (existingPhone) {
      throw new AppError('Phone number already registered', 400);
    }
  }

  // Admin-created customers: email verified and active by default
  const customer = await User.create({
    ...customerData,
    role: 'customer',
    email_verified: customerData.email ? true : false, // Auto-verify email if provided
    is_active: true, // Customers are always active
  });

  return await User.findById(customer._id).select('-password').lean();
};

/**
 * Get customer booking history
 */
export const getCustomerBookings = async (customerId, filters = {}) => {
  const customer = await User.findById(customerId);

  if (!customer) {
    throw new AppError('Customer not found', 404);
  }

  const {
    status,
    page = 1,
    limit = 20,
    sort = '-created_date'
  } = filters;

  const query = { customer_id: customerId };

  if (status) {
    query.status = status;
  }

  // Parse sort
  const sortField = sort.startsWith('-') ? sort.substring(1) : sort;
  const sortOrder = sort.startsWith('-') ? -1 : 1;
  const sortObj = { [sortField]: sortOrder };

  // Calculate pagination
  const skip = (parseInt(page) - 1) * parseInt(limit);

  const bookings = await Booking.find(query)
    .sort(sortObj)
    .skip(skip)
    .limit(parseInt(limit))
    .populate('service_id', 'name base_price')
    .populate('washer_id', 'name phone')
    .lean();

  const total = await Booking.countDocuments(query);

  return {
    bookings,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total,
      totalPages: Math.ceil(total / parseInt(limit))
    }
  };
};




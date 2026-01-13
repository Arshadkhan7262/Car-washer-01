import mongoose from 'mongoose';
import Booking from '../models/Booking.model.js';
import User from '../models/User.model.js';
import Service from '../models/Service.model.js';
import Washer from '../models/Washer.model.js';
import AppError from '../errors/AppError.js';
import * as couponService from './coupon.service.js';

/**
 * Generate unique booking ID
 */
const generateBookingId = async () => {
  const prefix = 'CW';
  const year = new Date().getFullYear();
  const random = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
  const bookingId = `${prefix}-${year}-${random}`;
  
  // Check if ID exists
  const exists = await Booking.findOne({ booking_id: bookingId });
  if (exists) {
    return generateBookingId(); // Recursive call if exists
  }
  
  return bookingId;
};

/**
 * Get all bookings with filters
 */
export const getAllBookings = async (filters = {}) => {
  const {
    status,
    dateFrom,
    dateTo,
    paymentMethod,
    paymentStatus,
    washerId,
    customerId,
    page = 1,
    limit = 20,
    sort = '-created_date'
  } = filters;

  // Build query
  const query = {};

  if (status) {
    query.status = status;
  }

  if (paymentMethod) {
    query.payment_method = paymentMethod;
  }

  if (paymentStatus) {
    query.payment_status = paymentStatus;
  }

  if (washerId) {
    query.washer_id = washerId;
  }

  if (customerId) {
    query.customer_id = customerId;
  }

  if (dateFrom || dateTo) {
    query.booking_date = {};
    if (dateFrom) {
      query.booking_date.$gte = new Date(dateFrom);
    }
    if (dateTo) {
      const endDate = new Date(dateTo);
      endDate.setHours(23, 59, 59, 999);
      query.booking_date.$lte = endDate;
    }
  }

  // Parse sort
  const sortField = sort.startsWith('-') ? sort.substring(1) : sort;
  const sortOrder = sort.startsWith('-') ? -1 : 1;
  const sortObj = { [sortField]: sortOrder };

  // Calculate pagination
  const skip = (parseInt(page) - 1) * parseInt(limit);

  // Get bookings
  const bookings = await Booking.find(query)
    .sort(sortObj)
    .skip(skip)
    .limit(parseInt(limit))
    .populate('customer_id', 'name email phone')
    .populate('service_id', 'name base_price')
    .populate('washer_id', 'name phone status')
    .lean();

  // Get total count
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

/**
 * Get booking by ID
 */
export const getBookingById = async (bookingId) => {
  let booking;
  
  // Check if it's a valid MongoDB ObjectId (24 hex characters)
  if (mongoose.Types.ObjectId.isValid(bookingId) && String(new mongoose.Types.ObjectId(bookingId)) === bookingId) {
    // It's a valid MongoDB ObjectId - use findById
    booking = await Booking.findById(bookingId)
      .populate('customer_id', 'name email phone')
      .populate('service_id', 'name description base_price pricing duration_minutes')
      .populate('washer_id', 'name phone email status rating')
      .lean();
  } else {
    // Assume it's a human-readable booking_id (e.g., "CW-2026-6393")
    booking = await Booking.findOne({ booking_id: bookingId })
      .populate('customer_id', 'name email phone')
      .populate('service_id', 'name description base_price pricing duration_minutes')
      .populate('washer_id', 'name phone email status rating')
      .lean();
  }

  if (!booking) {
    throw new AppError('Booking not found', 404);
  }

  return booking;
};

/**
 * Create new booking
 */
export const createBooking = async (bookingData) => {
  // Validate customer exists
  const customer = await User.findById(bookingData.customer_id);
  if (!customer) {
    throw new AppError('Customer not found', 404);
  }

  // Validate service exists
  const service = await Service.findById(bookingData.service_id);
  if (!service) {
    throw new AppError('Service not found', 404);
  }

  if (!service.is_active) {
    throw new AppError('Service is not active', 400);
  }

  // Generate booking ID
  const bookingId = await generateBookingId();

  // Calculate price based on vehicle type
  let subtotal = service.base_price;
  if (service.pricing && service.pricing.get(bookingData.vehicle_type)) {
    subtotal = service.pricing.get(bookingData.vehicle_type);
  }

  // Handle coupon if provided
  let couponCode = null;
  let discount = 0;
  let total = subtotal;

  if (bookingData.coupon_code) {
    try {
      const couponResult = await couponService.validateCoupon(
        bookingData.coupon_code,
        subtotal
      );
      
      couponCode = couponResult.coupon.code;
      discount = couponResult.discount;
      total = couponResult.total;

      // Increment coupon usage
      await couponService.incrementCouponUsage(couponResult.coupon.id);
    } catch (error) {
      // If coupon validation fails, throw error
      throw new AppError(error.message || 'Invalid coupon code', error.statusCode || 400);
    }
  }

  // Create booking
  const booking = await Booking.create({
    booking_id: bookingId,
    customer_id: bookingData.customer_id,
    customer_name: customer.name,
    customer_phone: customer.phone,
    service_id: bookingData.service_id,
    service_name: service.name,
    vehicle_id: bookingData.vehicle_id || null,
    vehicle_type: bookingData.vehicle_type,
    booking_date: new Date(bookingData.booking_date),
    time_slot: bookingData.time_slot,
    address: bookingData.address,
    additional_location: bookingData.additional_location || null,
    address_latitude: bookingData.address_latitude || null,
    address_longitude: bookingData.address_longitude || null,
    status: bookingData.status || 'pending',
    payment_status: bookingData.payment_status || 'unpaid',
    payment_method: bookingData.payment_method || 'cash',
    subtotal: subtotal,
    coupon_code: couponCode,
    discount: discount,
    total: total,
    washer_id: bookingData.washer_id || null,
    washer_name: bookingData.washer_name || null,
    timeline: [{
      status: bookingData.status || 'pending',
      timestamp: new Date(),
      note: 'Booking created'
    }]
  });

  return await Booking.findById(booking._id)
    .populate('customer_id', 'name email phone')
    .populate('service_id', 'name base_price')
    .populate('washer_id', 'name phone')
    .lean();
};

/**
 * Update booking
 */
export const updateBooking = async (bookingId, updateData) => {
  const booking = await Booking.findById(bookingId);
  
  if (!booking) {
    throw new AppError('Booking not found', 404);
  }

  // If status is being updated, add to timeline
  if (updateData.status && updateData.status !== booking.status) {
    if (!updateData.timeline) {
      updateData.timeline = booking.timeline || [];
    }
    updateData.timeline.push({
      status: updateData.status,
      timestamp: new Date(),
      note: updateData.status_note || updateData.note || `Status changed to ${updateData.status}`
    });
  }

  // If washer is being assigned, validate washer exists and add to timeline
  if (updateData.washer_id) {
    const washer = await Washer.findById(updateData.washer_id);
    if (!washer) {
      throw new AppError('Washer not found', 404);
    }
    if (washer.status !== 'active') {
      throw new AppError('Washer is not active', 400);
    }
    updateData.washer_name = washer.name;
    
    // Set status to 'pending' when washer is assigned (waiting for washer acceptance)
    if (!updateData.status) {
      updateData.status = 'pending';
    }
    
    // Add to timeline
    if (!updateData.timeline) {
      updateData.timeline = booking.timeline || [];
    }
    updateData.timeline.push({
      status: 'pending',
      timestamp: new Date(),
      note: `Washer ${washer.name} assigned - waiting for acceptance`
    });
  }

  // Update booking
  Object.assign(booking, updateData);
  await booking.save();

  return await Booking.findById(bookingId)
    .populate('customer_id', 'name email phone')
    .populate('service_id', 'name base_price')
    .populate('washer_id', 'name phone')
    .lean();
};

/**
 * Cancel booking by customer
 * Customers can only cancel bookings that haven't started (pending or accepted)
 */
export const cancelBookingByCustomer = async (bookingId, customerId, reason = '') => {
  const booking = await Booking.findById(bookingId);
  
  if (!booking) {
    throw new AppError('Booking not found', 404);
  }

  // Verify booking belongs to customer
  if (booking.customer_id.toString() !== customerId.toString()) {
    throw new AppError('You do not have permission to cancel this booking', 403);
  }

  // Check if booking can be cancelled
  // Customers can only cancel if status is 'pending' or 'accepted'
  // Once washer is on_the_way or started, cancellation should go through admin
  const cancellableStatuses = ['pending', 'accepted'];
  if (!cancellableStatuses.includes(booking.status)) {
    throw new AppError(
      `Cannot cancel booking with status: ${booking.status}. Please contact support for assistance.`,
      400
    );
  }

  // Mark as cancelled
  booking.status = 'cancelled';
  booking.timeline.push({
    status: 'cancelled',
    timestamp: new Date(),
    note: reason || 'Booking cancelled by customer'
  });
  await booking.save();

  return booking;
};

/**
 * Delete/Cancel booking (Admin only)
 */
export const deleteBooking = async (bookingId) => {
  const booking = await Booking.findById(bookingId);
  
  if (!booking) {
    throw new AppError('Booking not found', 404);
  }

  // Instead of deleting, mark as cancelled
  booking.status = 'cancelled';
  booking.timeline.push({
    status: 'cancelled',
    timestamp: new Date(),
    note: 'Booking cancelled by admin'
  });
  await booking.save();

  return booking;
};




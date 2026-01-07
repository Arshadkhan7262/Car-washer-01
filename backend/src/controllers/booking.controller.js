import * as bookingService from '../services/booking.service.js';

/**
 * @desc    Get all bookings with filters
 * @route   GET /api/v1/admin/bookings
 * @access  Private (Admin)
 */
export const getAllBookings = async (req, res, next) => {
  try {
    const filters = {
      status: req.query.status,
      dateFrom: req.query.dateFrom,
      dateTo: req.query.dateTo,
      paymentMethod: req.query.paymentMethod,
      paymentStatus: req.query.paymentStatus,
      washerId: req.query.washerId,
      customerId: req.query.customerId,
      page: req.query.page || 1,
      limit: req.query.limit || 20,
      sort: req.query.sort || '-created_date'
    };

    const result = await bookingService.getAllBookings(filters);

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get booking by ID
 * @route   GET /api/v1/admin/bookings/:id
 * @access  Private (Admin)
 */
export const getBookingById = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Validate ObjectId format
    if (!id || id === ':id' || !/^[0-9a-fA-F]{24}$/.test(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid booking ID format. Please provide a valid MongoDB ObjectId.'
      });
    }

    const booking = await bookingService.getBookingById(id);

    res.status(200).json({
      success: true,
      data: booking
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Create new booking
 * @route   POST /api/v1/admin/bookings
 * @access  Private (Admin)
 */
export const createBooking = async (req, res, next) => {
  try {
    const {
      customer_id,
      service_id,
      vehicle_id,
      vehicle_type,
      booking_date,
      time_slot,
      address,
      status,
      payment_status,
      payment_method,
      washer_id
    } = req.body;

    // Validate required fields
    if (!customer_id || !service_id || !vehicle_type || !booking_date || !time_slot || !address) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: customer_id, service_id, vehicle_type, booking_date, time_slot, address'
      });
    }

    const bookingData = {
      customer_id,
      service_id,
      vehicle_id,
      vehicle_type,
      booking_date,
      time_slot,
      address,
      status,
      payment_status,
      payment_method,
      washer_id
    };

    const booking = await bookingService.createBooking(bookingData);

    res.status(201).json({
      success: true,
      data: booking
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Update booking
 * @route   PUT /api/v1/admin/bookings/:id
 * @access  Private (Admin)
 */
export const updateBooking = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Validate ObjectId format
    if (!id || id === ':id' || !/^[0-9a-fA-F]{24}$/.test(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid booking ID format. Please provide a valid MongoDB ObjectId.'
      });
    }

    const booking = await bookingService.updateBooking(id, req.body);

    res.status(200).json({
      success: true,
      data: booking
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Assign washer to booking
 * @route   PUT /api/v1/admin/bookings/:id/assign-washer
 * @access  Private (Admin)
 */
export const assignWasher = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { washer_id, washer_name } = req.body;

    if (!id || id === ':id' || !/^[0-9a-fA-F]{24}$/.test(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid booking ID format.'
      });
    }

    if (!washer_id) {
      return res.status(400).json({
        success: false,
        message: 'washer_id is required'
      });
    }

    const updateData = {
      washer_id,
      washer_name: washer_name || undefined
    };

    const booking = await bookingService.updateBooking(id, updateData);

    res.status(200).json({
      success: true,
      message: 'Washer assigned successfully',
      data: booking
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Delete/Cancel booking
 * @route   DELETE /api/v1/admin/bookings/:id
 * @access  Private (Admin)
 */
export const deleteBooking = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Validate ObjectId format
    if (!id || id === ':id' || !/^[0-9a-fA-F]{24}$/.test(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid booking ID format. Please provide a valid MongoDB ObjectId.'
      });
    }

    const booking = await bookingService.deleteBooking(id);

    res.status(200).json({
      success: true,
      message: 'Booking cancelled successfully',
      data: booking
    });
  } catch (error) {
    next(error);
  }
};


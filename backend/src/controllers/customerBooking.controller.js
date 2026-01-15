import * as bookingService from '../services/booking.service.js';
import * as washerLocationService from '../services/washerLocation.service.js';
// DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
// import * as draftBookingService from '../services/draftBooking.service.js';
import * as vehicleTypeService from '../services/vehicleType.service.js';
import AppError from '../errors/AppError.js';

/**
 * Map vehicle type name/display name to Booking enum value
 * Valid enum values: ['sedan', 'suv', 'truck', 'van', 'motorcycle', 'luxury']
 */
const mapVehicleTypeToEnum = (vehicleTypeName) => {
  if (!vehicleTypeName) return null;
  
  const normalized = vehicleTypeName.toLowerCase().trim();
  
  // Direct matches
  const enumValues = ['sedan', 'suv', 'truck', 'van', 'motorcycle', 'luxury'];
  if (enumValues.includes(normalized)) {
    return normalized;
  }
  
  // Mapping for common variations
  const mapping = {
    'bike': 'motorcycle',
    'bicycle': 'motorcycle',
    'motorcycle': 'motorcycle',
    'motorbike': 'motorcycle',
    'car': 'sedan',
    'sedan': 'sedan',
    'suv': 'suv',
    'sport utility vehicle': 'suv',
    'truck': 'truck',
    'pickup': 'truck',
    'pickup truck': 'truck',
    'van': 'van',
    'luxury': 'luxury',
    'luxury car': 'luxury',
    'premium': 'luxury'
  };
  
  return mapping[normalized] || 'sedan'; // Default to sedan if no match
};

/**
 * @desc    Create booking (confirm booking)
 * @route   POST /api/v1/customer/bookings
 * @access  Private (Customer)
 */
export const createBooking = async (req, res, next) => {
  try {
    const customerId = req.customer._id;
    const {
      service_id,
      vehicle_type_id,
      vehicle_type_name,
      booking_date,
      time_slot,
      address,
      address_latitude,
      address_longitude,
      additional_location,
      payment_method,
      coupon_code
    } = req.body;

    // Validate required fields
    if (!service_id || !vehicle_type_name || !booking_date || !time_slot || !address) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: service_id, vehicle_type_name, booking_date, time_slot, address'
      });
    }

    // Map vehicle_type_name to enum value
    // If vehicle_type_id is provided, try to fetch the actual name from DB first
    let vehicleTypeEnum;
    if (vehicle_type_id) {
      try {
        const vehicleType = await vehicleTypeService.getVehicleTypeById(vehicle_type_id);
        if (vehicleType) {
          // Use the name field from VehicleType, which should match enum
          vehicleTypeEnum = mapVehicleTypeToEnum(vehicleType.name);
        } else {
          // Fallback to vehicle_type_name if vehicle_type_id not found
          vehicleTypeEnum = mapVehicleTypeToEnum(vehicle_type_name);
        }
      } catch (error) {
        // If fetching fails, use vehicle_type_name
        vehicleTypeEnum = mapVehicleTypeToEnum(vehicle_type_name);
      }
    } else {
      vehicleTypeEnum = mapVehicleTypeToEnum(vehicle_type_name);
    }

    // Determine payment status based on payment method
    let paymentStatus = 'unpaid';
    if (payment_method === 'card' || payment_method === 'wallet' || payment_method === 'apple_pay' || payment_method === 'google_pay') {
      paymentStatus = 'paid'; // Assume paid for non-cash methods
    }

    const bookingData = {
      customer_id: customerId,
      service_id,
      vehicle_id: vehicle_type_id || null,
      vehicle_type: vehicleTypeEnum,
      booking_date,
      time_slot,
      address: additional_location ? `${address}, ${additional_location}` : address,
      address_latitude: address_latitude || null,
      address_longitude: address_longitude || null,
      additional_location: additional_location || null,
      payment_method: payment_method || 'cash',
      payment_status: paymentStatus,
      status: 'pending',
      coupon_code: coupon_code || null
    };

    const booking = await bookingService.createBooking(bookingData);

    // DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
    // Delete draft booking after successful booking creation
    // await draftBookingService.deleteDraftBooking(customerId);

    res.status(201).json({
      success: true,
      data: {
        booking_id: booking.booking_id,
        booking: booking
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get customer bookings
 * @route   GET /api/v1/customer/bookings
 * @access  Private (Customer)
 */
export const getCustomerBookings = async (req, res, next) => {
  try {
    const customerId = req.customer._id;
    const filters = {
      customerId,
      status: req.query.status,
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
 * @desc    Get customer booking by ID
 * @route   GET /api/v1/customer/bookings/:id
 * @access  Private (Customer)
 */
export const getCustomerBookingById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const customerId = req.customer._id;

    if (!id || id === ':id') {
      return res.status(400).json({
        success: false,
        message: 'Booking ID is required.'
      });
    }

    // Let getBookingById handle both ObjectId and human-readable booking_id formats
    const booking = await bookingService.getBookingById(id);

    // Verify booking belongs to customer
    const bookingCustomerId = booking.customer_id?._id || booking.customer_id;
    if (bookingCustomerId.toString() !== customerId.toString()) {
      return res.status(403).json({
        success: false,
        message: 'You do not have permission to view this booking'
      });
    }

    res.status(200).json({
      success: true,
      data: booking
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get booking tracking details
 * @route   GET /api/v1/customer/bookings/:id/track
 * @access  Private (Customer)
 */
export const trackBooking = async (req, res, next) => {
  try {
    const { id } = req.params;
    const customerId = req.customer._id;

    if (!id || id === ':id') {
      return res.status(400).json({
        success: false,
        message: 'Booking ID is required.'
      });
    }

    // Let getBookingById handle both ObjectId and human-readable booking_id formats
    const booking = await bookingService.getBookingById(id);

    // Verify booking belongs to customer
    const bookingCustomerId = booking.customer_id?._id || booking.customer_id;
    if (bookingCustomerId.toString() !== customerId.toString()) {
      return res.status(403).json({
        success: false,
        message: 'You do not have permission to track this booking'
      });
    }

    // Map booking status to customer tracking status
    // If washer is assigned but status is still pending -> washerAssigned
    // pending (no washer) -> confirmed (waiting for washer assignment)
    // accepted -> washerAssigned
    // on_the_way -> onTheWay
    // arrived -> arrived
    // in_progress -> washing
    // completed -> completed
    let trackingStatus = 'confirmed';
    
    // Check if washer is assigned (even if status is still pending)
    const hasWasher = booking.washer_id && booking.washer_name;
    
    if (booking.status === 'pending' && hasWasher) {
      // Washer assigned but not yet accepted
      trackingStatus = 'washerAssigned';
    } else {
      const statusMap = {
        'pending': 'confirmed',
        'accepted': 'washerAssigned',
        'on_the_way': 'onTheWay',
        'arrived': 'arrived',
        'in_progress': 'washing',
        'completed': 'completed',
        'cancelled': 'cancelled'
      };
      
      if (statusMap[booking.status]) {
        trackingStatus = statusMap[booking.status];
      }
    }

    // Get washer location if washer is assigned
    let washerLocation = null;
    if (booking.washer_id && booking.washer_id._id) {
      try {
        washerLocation = await washerLocationService.getWasherLocation(booking.washer_id._id.toString());
      } catch (error) {
        // If location fetch fails, continue without location data
        console.error('Failed to fetch washer location:', error.message);
      }
    }

    // Format tracking data
    const trackingData = {
      booking_id: booking.booking_id,
      status: trackingStatus,
      booking_status: booking.status,
      washer_name: booking.washer_name || null,
      washer_id: booking.washer_id ? booking.washer_id._id : null,
      washer_location: washerLocation,
      timeline: booking.timeline || [],
      booking_date: booking.booking_date,
      time_slot: booking.time_slot,
      address: booking.address,
      address_latitude: booking.address_latitude || null,
      address_longitude: booking.address_longitude || null,
      service_name: booking.service_name,
      vehicle_type: booking.vehicle_type,
      total: booking.total,
      payment_status: booking.payment_status,
      payment_method: booking.payment_method,
      created_date: booking.created_date,
      updated_date: booking.updated_date
    };

    res.status(200).json({
      success: true,
      data: trackingData
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get washer location for a booking
 * @route   GET /api/v1/customer/bookings/:id/washer-location
 * @access  Private (Customer)
 */
export const getWasherLocation = async (req, res, next) => {
  try {
    const { id } = req.params;
    const customerId = req.customer._id;

    if (!id || id === ':id') {
      return res.status(400).json({
        success: false,
        message: 'Booking ID is required.'
      });
    }

    // Get booking to verify ownership and get washer ID
    const booking = await bookingService.getBookingById(id);

    // Verify booking belongs to customer
    const bookingCustomerId = booking.customer_id?._id || booking.customer_id;
    if (bookingCustomerId.toString() !== customerId.toString()) {
      return res.status(403).json({
        success: false,
        message: 'You do not have permission to view this booking'
      });
    }

    // Check if washer is assigned
    if (!booking.washer_id || !booking.washer_id._id) {
      return res.status(200).json({
        success: true,
        data: null,
        message: 'No washer assigned to this booking yet'
      });
    }

    // Get washer location
    const washerLocation = await washerLocationService.getWasherLocation(
      booking.washer_id._id.toString()
    );

    if (!washerLocation) {
      return res.status(200).json({
        success: true,
        data: null,
        message: 'Washer location not available'
      });
    }

    res.status(200).json({
      success: true,
      data: washerLocation
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Cancel booking (Customer)
 * @route   PUT /api/v1/customer/bookings/:id/cancel
 * @access  Private (Customer)
 */
export const cancelBooking = async (req, res, next) => {
  try {
    const { id } = req.params;
    const customerId = req.customer._id;
    const { reason } = req.body;

    if (!id || id === ':id') {
      return res.status(400).json({
        success: false,
        message: 'Booking ID is required.'
      });
    }

    const booking = await bookingService.cancelBookingByCustomer(id, customerId, reason);

    res.status(200).json({
      success: true,
      message: 'Booking cancelled successfully',
      data: booking
    });
  } catch (error) {
    next(error);
  }
};


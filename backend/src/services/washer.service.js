import Washer from '../models/Washer.model.js';
import User from '../models/User.model.js';
import Booking from '../models/Booking.model.js';
import AppError from '../errors/AppError.js';

/**
 * Get all washers with filters
 */
export const getAllWashers = async (filters = {}) => {
  const {
    status,
    online_status,
    search,
    page = 1,
    limit = 20,
    sort = '-created_date'
  } = filters;

  const query = {};

  if (status) {
    query.status = status;
  }

  if (online_status !== undefined) {
    query.online_status = online_status === 'true' || online_status === true;
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

  const washers = await Washer.find(query)
    .populate('user_id', 'name email phone email_verified')
    .sort(sortObj)
    .skip(skip)
    .limit(parseInt(limit))
    .lean();

  const total = await Washer.countDocuments(query);

  // Transform washers with additional computed fields for admin panel
  const transformedWashers = await Promise.all(washers.map(async (washer) => {
    const washerId = washer._id.toString();
    
    // Get job statistics
    const totalJobs = await Booking.countDocuments({ washer_id: washerId });
    const completedJobs = await Booking.countDocuments({
      washer_id: washerId,
      status: 'completed'
    });
    const cancelledJobs = await Booking.countDocuments({
      washer_id: washerId,
      status: 'cancelled'
    });
    
    // Calculate total earnings from completed bookings
    const earningsData = await Booking.aggregate([
      {
        $match: {
          washer_id: washerId,
          status: 'completed',
          payment_status: 'paid'
        }
      },
      {
        $group: {
          _id: null,
          total: { $sum: '$total' }
        }
      }
    ]);
    
    const totalEarnings = earningsData.length > 0 ? earningsData[0].total : (washer.total_earnings || 0);
    
    return {
      ...washer,
      id: washerId,
      _id: washerId,
      email_verified: washer.user_id?.email_verified || false,
      // Map fields for admin panel compatibility
      jobs_completed: washer.completed_jobs || completedJobs,
      total_jobs: washer.total_jobs || totalJobs,
      jobs_cancelled: cancelledJobs,
      total_ratings: 0, // TODO: Calculate from reviews if review system exists
      total_earnings: totalEarnings,
      wallet_balance: washer.wallet_balance || 0,
      branch_name: washer.branch_name || null,
      branch_id: washer.branch_id || null,
      // Include current location with address
      current_location: washer.current_location || null
    };
  }));

  return {
    washers: transformedWashers,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total,
      totalPages: Math.ceil(total / parseInt(limit))
    }
  };
};

/**
 * Get washer by ID with profile details
 */
export const getWasherById = async (washerId) => {
  const washer = await Washer.findById(washerId)
    .populate('user_id', 'name email phone email_verified')
    .lean();

  if (!washer) {
    throw new AppError('Washer not found', 404);
  }

  // Get job statistics
  const totalJobs = await Booking.countDocuments({ washer_id: washerId });
  const completedJobs = await Booking.countDocuments({
    washer_id: washerId,
    status: 'completed'
  });
  const cancelledJobs = await Booking.countDocuments({
    washer_id: washerId,
    status: 'cancelled'
  });
  const pendingJobs = await Booking.countDocuments({
    washer_id: washerId,
    status: { $in: ['pending', 'accepted', 'on_the_way', 'in_progress'] }
  });

  // Get recent jobs
  const recentJobs = await Booking.find({ washer_id: washerId })
    .sort({ created_date: -1 })
    .limit(10)
    .select('booking_id customer_name service_name status total created_date')
    .lean();

  // Calculate total earnings from completed bookings
  const earningsData = await Booking.aggregate([
    {
      $match: {
        washer_id: washerId,
        status: 'completed',
        payment_status: 'paid'
      }
    },
    {
      $group: {
        _id: null,
        total: { $sum: '$total' }
      }
    }
  ]);

  const totalEarnings = earningsData.length > 0 ? earningsData[0].total : (washer.total_earnings || 0);

  // Transform _id to id for frontend compatibility with admin panel fields
  return {
    ...washer,
    id: washer._id.toString(),
    _id: washer._id.toString(),
    email_verified: washer.user_id?.email_verified || false,
    jobs_completed: washer.completed_jobs || completedJobs,
    total_jobs: washer.total_jobs || totalJobs,
    jobs_cancelled: cancelledJobs,
    total_ratings: 0, // TODO: Calculate from reviews if review system exists
    total_earnings: totalEarnings,
    wallet_balance: washer.wallet_balance || 0,
    // Include current location with address
    current_location: washer.current_location || null,
    performance: {
      totalJobs,
      completedJobs,
      cancelledJobs,
      pendingJobs,
      totalEarnings,
      walletBalance: washer.wallet_balance || 0
    },
    recentJobs
  };
};

/**
 * Create new washer (Admin only)
 * When admin creates a washer, email should be verified and status should be active by default
 */
export const createWasher = async (washerData) => {
  const normalizedEmail = washerData.email ? washerData.email.toLowerCase().trim() : null;
  
  // Check if user exists by email or phone
  let user = null;
  
  if (normalizedEmail) {
    user = await User.findOne({ 
      email: normalizedEmail,
      role: 'washer'
    });
  }
  
  if (!user && washerData.phone) {
    user = await User.findOne({ 
      phone: washerData.phone,
      role: 'washer'
    });
  }

  if (!user) {
    // Create new user if doesn't exist
    if (!washerData.phone) {
      throw new AppError('Phone number is required', 400);
    }

    if (!washerData.name) {
      throw new AppError('Name is required', 400);
    }

    user = await User.create({
      name: washerData.name,
      phone: washerData.phone,
      email: normalizedEmail,
      role: 'washer',
      is_active: true,
      email_verified: true, // Admin-created washers have verified email
      phone_verified: false
    });
  } else {
    // User exists - update if needed
    if (washerData.name && user.name !== washerData.name) {
      user.name = washerData.name;
    }
    if (normalizedEmail && user.email !== normalizedEmail) {
      user.email = normalizedEmail;
      user.email_verified = true; // Admin-created washers have verified email
    }
    if (washerData.phone && user.phone !== washerData.phone) {
      user.phone = washerData.phone;
    }
    
    // Ensure user role is washer
    if (user.role !== 'washer') {
      user.role = 'washer';
    }
    
    user.is_active = true;
    await user.save();
  }

  // Check if washer already exists for this user
  const existingWasher = await Washer.findOne({ user_id: user._id });
  if (existingWasher) {
    // Return existing washer instead of throwing error (idempotent behavior)
    const existingWasherPopulated = await Washer.findById(existingWasher._id)
      .populate('user_id', 'name email phone email_verified')
      .lean();
    
    return {
      ...existingWasherPopulated,
      id: existingWasherPopulated._id.toString(),
      _id: existingWasherPopulated._id.toString(),
      email_verified: existingWasherPopulated.user_id?.email_verified || true,
      jobs_completed: existingWasherPopulated.completed_jobs || 0,
      total_jobs: existingWasherPopulated.total_jobs || 0,
      jobs_cancelled: existingWasherPopulated.cancelled_jobs || 0,
      total_ratings: existingWasherPopulated.total_ratings || 0,
      total_earnings: existingWasherPopulated.total_earnings || 0,
      wallet_balance: existingWasherPopulated.wallet_balance || 0
    };
  }

  // Check if phone is already used by another washer
  if (washerData.phone) {
    const phoneExists = await Washer.findOne({ phone: washerData.phone });
    if (phoneExists) {
      throw new AppError('Phone number already registered as washer', 400);
    }
  }

  // Create washer with admin defaults
  const washer = await Washer.create({
    user_id: user._id,
    name: washerData.name || user.name,
    phone: washerData.phone || user.phone,
    email: normalizedEmail || user.email,
    status: washerData.status || 'active', // Admin-created washers are active by default
    online_status: washerData.online_status || false,
    branch_id: washerData.branch_id || null,
    branch_name: washerData.branch_name || null
  });

  const createdWasher = await Washer.findById(washer._id)
    .populate('user_id', 'name email phone email_verified')
    .lean();

  // Transform _id to id and add computed fields
  return {
    ...createdWasher,
    id: createdWasher._id.toString(),
    _id: createdWasher._id.toString(),
    email_verified: createdWasher.user_id?.email_verified || true,
    jobs_completed: 0,
    total_jobs: 0,
    jobs_cancelled: 0,
    total_ratings: 0,
    total_earnings: 0,
    wallet_balance: 0
  };
};

/**
 * Update washer
 */
export const updateWasher = async (washerId, updateData) => {
  console.log('🔧 updateWasher called:', { washerId, updateData });
  
  const washer = await Washer.findById(washerId);

  if (!washer) {
    throw new AppError('Washer not found', 404);
  }

  console.log('📋 Current washer status:', washer.status);

  // Update fields explicitly
  if (updateData.name !== undefined) {
    washer.name = updateData.name;
    console.log('✅ Updated name:', updateData.name);
  }
  if (updateData.phone !== undefined) {
    washer.phone = updateData.phone;
    console.log('✅ Updated phone:', updateData.phone);
  }
  if (updateData.email !== undefined) {
    const normalizedEmail = updateData.email.toLowerCase().trim();
    washer.email = normalizedEmail;
    console.log('✅ Updated email:', normalizedEmail);
    
    // Also update user email if exists
    const user = await User.findById(washer.user_id);
    if (user) {
      user.email = normalizedEmail;
      await user.save();
    }
  }
  if (updateData.status !== undefined) {
    console.log('🔄 Changing status from', washer.status, 'to', updateData.status);
    washer.status = updateData.status;
    console.log('✅ Updated status:', washer.status);
  }
  if (updateData.online_status !== undefined) {
    washer.online_status = updateData.online_status;
    console.log('✅ Updated online_status:', updateData.online_status);
  }
  if (updateData.rating !== undefined) {
    washer.rating = updateData.rating;
    console.log('✅ Updated rating:', updateData.rating);
  }
  if (updateData.branch_id !== undefined) {
    washer.branch_id = updateData.branch_id;
    console.log('✅ Updated branch_id:', updateData.branch_id);
  }
  if (updateData.branch_name !== undefined) {
    washer.branch_name = updateData.branch_name;
    console.log('✅ Updated branch_name:', updateData.branch_name);
  }

  // If status is being changed to active, ensure user is also active
  if (updateData.status === 'active') {
    const user = await User.findById(washer.user_id);
    if (user) {
      user.is_active = true;
      await user.save();
      console.log('✅ Activated user account');
    }
  }

  // If status is being changed to suspended or inactive, we might want to deactivate user
  if (updateData.status === 'suspended' || updateData.status === 'inactive') {
    const user = await User.findById(washer.user_id);
    if (user) {
      user.is_active = false;
      await user.save();
      console.log('✅ Deactivated user account');
    }
  }

  await washer.save();
  console.log('💾 Washer saved. New status:', washer.status);

  // Return updated washer with populated user and computed fields
  const updatedWasher = await Washer.findById(washerId)
    .populate('user_id', 'name email phone email_verified')
    .lean();

  // Get job statistics for admin panel
  const washerIdStr = washerId.toString();
  const totalJobs = await Booking.countDocuments({ washer_id: washerIdStr });
  const completedJobs = await Booking.countDocuments({
    washer_id: washerIdStr,
    status: 'completed'
  });
  const cancelledJobs = await Booking.countDocuments({
    washer_id: washerIdStr,
    status: 'cancelled'
  });
  
  const earningsData = await Booking.aggregate([
    {
      $match: {
        washer_id: washerIdStr,
        status: 'completed',
        payment_status: 'paid'
      }
    },
    {
      $group: {
        _id: null,
        total: { $sum: '$total' }
      }
    }
  ]);
  
  const totalEarnings = earningsData.length > 0 ? earningsData[0].total : (updatedWasher.total_earnings || 0);

  // Transform _id to id for frontend compatibility with admin panel fields
  return {
    ...updatedWasher,
    id: updatedWasher._id.toString(),
    _id: updatedWasher._id.toString(),
    email_verified: updatedWasher.user_id?.email_verified || false,
    jobs_completed: updatedWasher.completed_jobs || completedJobs,
    total_jobs: updatedWasher.total_jobs || totalJobs,
    jobs_cancelled: cancelledJobs,
    total_ratings: 0, // TODO: Calculate from reviews if review system exists
    total_earnings: totalEarnings,
    wallet_balance: updatedWasher.wallet_balance || 0
  };
};

/**
 * Delete washer
 */
export const deleteWasher = async (washerId) => {
  const washer = await Washer.findById(washerId);

  if (!washer) {
    throw new AppError('Washer not found', 404);
  }

  // Check if washer has active bookings
  const activeBookings = await Booking.countDocuments({
    washer_id: washerId,
    status: { $in: ['pending', 'accepted', 'on_the_way', 'in_progress'] }
  });

  if (activeBookings > 0) {
    throw new AppError('Cannot delete washer with active bookings', 400);
  }

  await Washer.findByIdAndDelete(washerId);

  return { message: 'Washer deleted successfully' };
};




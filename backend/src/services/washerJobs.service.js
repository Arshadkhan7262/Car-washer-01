/**
 * Washer Jobs Screen Service
 * Handles job management for washer app
 */

import Booking from '../models/Booking.model.js';
import Washer from '../models/Washer.model.js';
import AppError from '../errors/AppError.js';
import mongoose from 'mongoose';
import { sendNotificationToUser } from './notification.service.js';

/**
 * Get all jobs for washer with filters
 */
export const getWasherJobs = async (userId, filters = {}) => {
  try {
    // Get washer by user_id
    const washer = await Washer.findOne({ user_id: userId });
    if (!washer) {
      throw new AppError('Washer not found', 404);
    }
    
    const washerId = washer._id.toString();
    // Convert washerId string to ObjectId for query (MongoDB requires ObjectId for matching)
    const washerObjectId = new mongoose.Types.ObjectId(washerId);
    
    const {
      status,
      page = 1,
      limit = 20,
      sort = '-created_date'
    } = filters;

    const query = { washer_id: washerObjectId };

    // Filter by status if provided
    if (status) {
      query.status = status;
    } else {
      // Exclude cancelled jobs by default (they can be shown if status='cancelled' is explicitly requested)
      query.status = { $ne: 'cancelled' };
    }

    // Parse sort
    const sortField = sort.startsWith('-') ? sort.substring(1) : sort;
    const sortOrder = sort.startsWith('-') ? -1 : 1;
    const sortObj = { [sortField]: sortOrder };

    // Calculate pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const jobs = await Booking.find(query)
      .populate('customer_id', 'name phone email')
      .populate('service_id', 'name base_price')
      .sort(sortObj)
      .skip(skip)
      .limit(parseInt(limit))
      .lean();

    const total = await Booking.countDocuments(query);

    // Map booking status to job status for UI
    // pending -> newJob (assigned but not accepted)
    // accepted, on_the_way, arrived, in_progress -> active
    // completed -> done
    const mappedJobs = jobs.map(job => {
      let jobStatus = 'newJob'; // Default for pending
      
      if (job.status === 'accepted' || job.status === 'on_the_way' || job.status === 'arrived' || job.status === 'in_progress') {
        jobStatus = 'active';
      } else if (job.status === 'completed') {
        jobStatus = 'done';
      }

      return {
        ...job,
        jobStatus // Add jobStatus for UI compatibility
      };
    });

    return {
      jobs: mappedJobs,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        totalPages: Math.ceil(total / parseInt(limit))
      }
    };
  } catch (error) {
    throw new AppError('Failed to fetch jobs', 500);
  }
};

/**
 * Get job by ID
 */
export const getJobById = async (jobId, userId) => {
  try {
    // Get washer by user_id
    const washer = await Washer.findOne({ user_id: userId });
    if (!washer) {
      throw new AppError('Washer not found', 404);
    }
    
    const washerId = washer._id.toString();
    // Convert washerId string to ObjectId for query
    const washerObjectId = new mongoose.Types.ObjectId(washerId);
    
    const job = await Booking.findOne({
      _id: jobId,
      washer_id: washerObjectId
    })
      .populate('customer_id', 'name phone email')
      .populate('service_id', 'name base_price description')
      .populate('vehicle_id')
      .lean();

    if (!job) {
      throw new AppError('Job not found', 404);
    }

    return job;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to fetch job', 500);
  }
};

/**
 * Accept a job
 */
export const acceptJob = async (jobId, userId) => {
  try {
    // Get washer by user_id
    const washer = await Washer.findOne({ user_id: userId });
    if (!washer) {
      throw new AppError('Washer not found', 404);
    }
    
    const washerId = washer._id.toString();
    
    const job = await Booking.findById(jobId);

    if (!job) {
      throw new AppError('Job not found', 404);
    }

    // Check if job is already assigned to another washer
    if (job.washer_id && job.washer_id.toString() !== washerId) {
      throw new AppError('Job is already assigned to another washer', 400);
    }

    // Check if job is in valid status
    if (job.status !== 'pending') {
      throw new AppError(`Cannot accept job with status: ${job.status}`, 400);
    }

    // Update job
    job.washer_id = washerId;
    job.status = 'accepted';
    job.timeline = job.timeline || [];
    job.timeline.push({
      status: 'accepted',
      timestamp: new Date(),
      note: 'Job accepted by washer'
    });
    await job.save();

    return job;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to accept job', 500);
  }
};

/**
 * Update job status
 */
export const updateJobStatus = async (jobId, userId, newStatus, note = '') => {
  try {
    // Get washer by user_id
    const washer = await Washer.findOne({ user_id: userId });
    if (!washer) {
      throw new AppError('Washer not found', 404);
    }
    
    const washerId = washer._id.toString();
    
    const validStatuses = ['accepted', 'on_the_way', 'arrived', 'in_progress', 'completed', 'cancelled'];
    
    if (!validStatuses.includes(newStatus)) {
      throw new AppError(`Invalid status: ${newStatus}`, 400);
    }

    // Convert washerId string to ObjectId for query
    const washerObjectId = new mongoose.Types.ObjectId(washerId);
    
    const job = await Booking.findOne({
      _id: jobId,
      washer_id: washerObjectId
    });

    if (!job) {
      throw new AppError('Job not found or not assigned to this washer', 404);
    }

    // Validate status transition
    const statusFlow = {
      'pending': ['accepted', 'cancelled'],
      'accepted': ['on_the_way', 'cancelled'],
      'on_the_way': ['arrived', 'cancelled'],
      'arrived': ['in_progress', 'cancelled'],
      'in_progress': ['completed', 'cancelled'],
      'completed': [],
      'cancelled': []
    };

    const allowedStatuses = statusFlow[job.status] || [];
    if (!allowedStatuses.includes(newStatus)) {
      throw new AppError(`Cannot change status from ${job.status} to ${newStatus}`, 400);
    }

    // Update job status
    job.status = newStatus;
    job.timeline = job.timeline || [];
    job.timeline.push({
      status: newStatus,
      timestamp: new Date(),
      note: note || `Status changed to ${newStatus}`
    });

    // If completed, update payment status and washer stats
    if (newStatus === 'completed') {
      job.payment_status = 'paid'; // Auto-mark as paid when completed
      
      // Update washer stats
      const washer = await Washer.findById(washerId);
      if (washer) {
        washer.completed_jobs = (washer.completed_jobs || 0) + 1;
        washer.total_jobs = (washer.total_jobs || 0) + 1;
        washer.total_earnings = (washer.total_earnings || 0) + (job.total || 0);
        washer.wallet_balance = (washer.wallet_balance || 0) + (job.total || 0);
        await washer.save();
      }
    }

    await job.save();

    // Send notification to customer about status change
    try {
      const statusMessages = {
        'accepted': { title: 'Washer Accepted', body: 'Your washer has accepted the booking and is preparing', status: 'accepted' },
        'on_the_way': { title: 'Washer On The Way', body: 'Your washer is on the way to your location', status: 'onTheWay' },
        'arrived': { title: 'Washer Arrived', body: 'Your washer has arrived at your location', status: 'arrived' },
        'in_progress': { title: 'Washing Started', body: 'Your car wash has started', status: 'washing' },
        'completed': { title: 'Service Completed', body: 'Your car wash service has been completed', status: 'completed' },
        'cancelled': { title: 'Booking Cancelled', body: 'Your booking has been cancelled by the washer', status: 'cancelled' },
      };

      const message = statusMessages[newStatus];
      if (message) {
        const bookingId = job.booking_id || job._id.toString();
        await sendNotificationToUser(
          job.customer_id.toString(),
          message.title,
          message.body,
          {
            type: 'booking_status',
            booking_id: bookingId,
            status: message.status,
            screen: 'track_order', // Navigation screen
            action: 'navigate', // Action to perform
          }
        );
        console.log(`✅ Sent ${newStatus} notification to customer for booking ${bookingId}`);
      }
    } catch (notifError) {
      // Don't fail the update if notification fails
      console.error('❌ Failed to send status notification:', notifError.message);
    }

    return job;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to update job status', 500);
  }
};

/**
 * Reject a job
 */
export const rejectJob = async (jobId, userId, reason = '') => {
  try {
    // Get washer by user_id
    const washer = await Washer.findOne({ user_id: userId });
    if (!washer) {
      throw new AppError('Washer not found', 404);
    }
    
    const washerId = washer._id.toString();
    
    const job = await Booking.findById(jobId);

    if (!job) {
      throw new AppError('Job not found', 404);
    }

    // Check if job is assigned to this washer
    if (!job.washer_id || job.washer_id.toString() !== washerId) {
      throw new AppError('Job is not assigned to you', 403);
    }

    // Check if job is in pending status (assigned but not accepted)
    if (job.status !== 'pending') {
      throw new AppError(`Cannot reject job with status: ${job.status}`, 400);
    }

    // Update job: remove washer assignment and set to cancelled
    job.washer_id = null;
    job.washer_name = null;
    job.status = 'cancelled';
    job.timeline = job.timeline || [];
    job.timeline.push({
      status: 'cancelled',
      timestamp: new Date(),
      note: reason || 'Job rejected by washer'
    });
    await job.save();

    return job;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to reject job', 500);
  }
};

/**
 * Complete a job (convenience method)
 */
export const completeJob = async (jobId, userId, note = '') => {
  return await updateJobStatus(jobId, userId, 'completed', note);
};


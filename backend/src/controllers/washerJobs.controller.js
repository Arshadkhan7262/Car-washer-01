/**
 * Washer Jobs Screen Controller
 * Handles HTTP requests for job management
 */

import * as washerJobsService from '../services/washerJobs.service.js';

/**
 * @desc    Get all jobs for washer
 * @route   GET /api/v1/washer/jobs
 * @access  Private (Washer)
 */
export const getWasherJobs = async (req, res, next) => {
  try {
    const userId = req.washer.id; // User ID from token
    
    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'User ID not found in token'
      });
    }

    const filters = {
      status: req.query.status,
      page: req.query.page || 1,
      limit: req.query.limit || 20,
      sort: req.query.sort || '-created_date'
    };

    const result = await washerJobsService.getWasherJobs(userId, filters);

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get job by ID
 * @route   GET /api/v1/washer/jobs/:id
 * @access  Private (Washer)
 */
export const getJobById = async (req, res, next) => {
  try {
    const userId = req.washer.id; // User ID from token
    const { id } = req.params;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'User ID not found in token'
      });
    }

    const job = await washerJobsService.getJobById(id, userId);

    res.status(200).json({
      success: true,
      data: job
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Accept a job
 * @route   POST /api/v1/washer/jobs/:id/accept
 * @access  Private (Washer)
 */
export const acceptJob = async (req, res, next) => {
  try {
    const userId = req.washer.id; // User ID from token
    const { id } = req.params;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'User ID not found in token'
      });
    }

    const job = await washerJobsService.acceptJob(id, userId);

    res.status(200).json({
      success: true,
      data: job,
      message: 'Job accepted successfully'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Update job status
 * @route   PUT /api/v1/washer/jobs/:id/status
 * @access  Private (Washer)
 */
export const updateJobStatus = async (req, res, next) => {
  try {
    const userId = req.washer.id; // User ID from token
    const { id } = req.params;
    const { status, note } = req.body;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'User ID not found in token'
      });
    }

    if (!status) {
      return res.status(400).json({
        success: false,
        message: 'Status is required'
      });
    }

    const job = await washerJobsService.updateJobStatus(id, userId, status, note);

    res.status(200).json({
      success: true,
      data: job,
      message: `Job status updated to ${status}`
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Reject a job
 * @route   POST /api/v1/washer/jobs/:id/reject
 * @access  Private (Washer)
 */
export const rejectJob = async (req, res, next) => {
  try {
    const userId = req.washer.id; // User ID from token
    const { id } = req.params;
    const { reason } = req.body;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'User ID not found in token'
      });
    }

    const job = await washerJobsService.rejectJob(id, userId, reason);

    res.status(200).json({
      success: true,
      data: job,
      message: 'Job rejected successfully'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Complete a job
 * @route   POST /api/v1/washer/jobs/:id/complete
 * @access  Private (Washer)
 */
export const completeJob = async (req, res, next) => {
  try {
    const userId = req.washer.id; // User ID from token
    const { id } = req.params;
    const { note } = req.body;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'User ID not found in token'
      });
    }

    const job = await washerJobsService.completeJob(id, userId, note);

    res.status(200).json({
      success: true,
      data: job,
      message: 'Job completed successfully'
    });
  } catch (error) {
    next(error);
  }
};


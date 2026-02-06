import * as stripeConnectService from '../services/stripeConnect.service.js';
import Washer from '../models/Washer.model.js';
import AppError from '../errors/AppError.js';

/**
 * @desc    Create Stripe Connect account for washer
 * @route   POST /api/v1/washer/stripe-connect/create
 * @access  Private (Washer)
 */
export const createStripeConnectAccount = async (req, res, next) => {
  try {
    const userId = req.washer.id;
    const washer = await Washer.findOne({ user_id: userId });
    
    if (!washer) {
      return res.status(404).json({
        success: false,
        message: 'Washer not found'
      });
    }

    const result = await stripeConnectService.createStripeConnectAccount(userId, washer._id);

    res.status(200).json({
      success: true,
      data: result,
      message: 'Stripe Connect account created. Please complete the setup to receive payouts.'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get Stripe Connect account onboarding link
 * @route   GET /api/v1/washer/stripe-connect/onboarding-link
 * @access  Private (Washer)
 */
export const getOnboardingLink = async (req, res, next) => {
  try {
    const userId = req.washer.id;
    const washer = await Washer.findOne({ user_id: userId });
    
    if (!washer) {
      return res.status(404).json({
        success: false,
        message: 'Washer not found'
      });
    }

    const result = await stripeConnectService.getAccountOnboardingLink(washer._id, userId);

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get Stripe Connect account status
 * @route   GET /api/v1/washer/stripe-connect/status
 * @access  Private (Washer)
 */
export const getAccountStatus = async (req, res, next) => {
  try {
    const userId = req.washer.id;
    const washer = await Washer.findOne({ user_id: userId });
    
    if (!washer) {
      return res.status(404).json({
        success: false,
        message: 'Washer not found'
      });
    }

    const result = await stripeConnectService.getAccountStatus(washer._id, userId);

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

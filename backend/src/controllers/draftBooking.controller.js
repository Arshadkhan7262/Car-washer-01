/* DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
import * as draftBookingService from '../services/draftBooking.service.js';

/**
 * @desc    Save draft booking
 * @route   POST /api/v1/customer/bookings/draft
 * @access  Private (Customer)
 */
export const saveDraft = async (req, res, next) => {
  try {
    const customerId = req.customer._id;
    const {
      step,
      service_id,
      vehicle_type_id,
      vehicle_type_name,
      selected_date,
      selected_time,
      address,
      additional_location,
      payment_method,
      coupon_code
    } = req.body;

    if (!step || step < 1 || step > 4) {
      return res.status(400).json({
        success: false,
        message: 'Step must be between 1 and 4'
      });
    }

    const draftData = {
      step,
      service_id: service_id || undefined,
      vehicle_type_id: vehicle_type_id || undefined,
      vehicle_type_name: vehicle_type_name || undefined,
      selected_date: selected_date ? new Date(selected_date) : undefined,
      selected_time: selected_time || undefined,
      address: address || undefined,
      additional_location: additional_location || undefined,
      payment_method: payment_method || undefined,
      coupon_code: coupon_code || undefined
    };

    // Remove undefined fields
    Object.keys(draftData).forEach(key => {
      if (draftData[key] === undefined) {
        delete draftData[key];
      }
    });

    const draft = await draftBookingService.saveDraftBooking(customerId, draftData);

    res.status(200).json({
      success: true,
      data: {
        draft_id: draft._id,
        step: draft.step,
        last_updated: draft.updated_date
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get draft booking
 * @route   GET /api/v1/customer/bookings/draft
 * @access  Private (Customer)
 */
export const getDraft = async (req, res, next) => {
  try {
    const customerId = req.customer._id;

    const draft = await draftBookingService.getDraftBooking(customerId);

    if (!draft) {
      return res.status(404).json({
        success: false,
        message: 'No draft booking found'
      });
    }

    res.status(200).json({
      success: true,
      data: draft
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Delete draft booking
 * @route   DELETE /api/v1/customer/bookings/draft
 * @access  Private (Customer)
 */
export const deleteDraft = async (req, res, next) => {
  try {
    const customerId = req.customer._id;

    const deleted = await draftBookingService.deleteDraftBooking(customerId);

    if (!deleted) {
      return res.status(404).json({
        success: false,
        message: 'No draft booking found'
      });
    }

    res.status(200).json({
      success: true,
      message: 'Draft booking deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Check if draft exists
 * @route   GET /api/v1/customer/bookings/draft/check
 * @access  Private (Customer)
 */
export const checkDraft = async (req, res, next) => {
  try {
    const customerId = req.customer._id;

    const result = await draftBookingService.checkDraftExists(customerId);

    res.status(200).json({
      success: true,
      ...result
    });
  } catch (error) {
    next(error);
  }
};
*/

import DraftBooking from '../models/DraftBooking.model.js';
import AppError from '../errors/AppError.js';

/**
 * Save or update draft booking
 */
export const saveDraftBooking = async (customerId, draftData) => {
  // Find existing draft
  let draft = await DraftBooking.findOne({ customer_id: customerId });

  if (draft) {
    // Update existing draft
    Object.assign(draft, draftData);
    draft.updated_date = new Date();
    draft.expires_at = new Date(Date.now() + 24 * 60 * 60 * 1000); // Reset expiry
    await draft.save();
  } else {
    // Create new draft
    draft = await DraftBooking.create({
      customer_id: customerId,
      ...draftData,
      expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000)
    });
  }

  return draft;
};

/**
 * Get draft booking for customer
 * Returns IDs as strings (not populated objects) for consistent frontend handling
 */
export const getDraftBooking = async (customerId) => {
  // Don't populate - return IDs as strings for consistent frontend handling
  const draft = await DraftBooking.findOne({ customer_id: customerId });

  if (!draft) {
    return null;
  }

  // Check if expired
  if (draft.expires_at < new Date()) {
    await DraftBooking.findByIdAndDelete(draft._id);
    return null;
  }

  return draft;
};

/**
 * Delete draft booking
 */
export const deleteDraftBooking = async (customerId) => {
  const result = await DraftBooking.deleteOne({ customer_id: customerId });
  return result.deletedCount > 0;
};

/**
 * Check if draft exists
 */
export const checkDraftExists = async (customerId) => {
  const draft = await DraftBooking.findOne({ customer_id: customerId });

  if (!draft) {
    return { has_draft: false };
  }

  // Check if expired
  if (draft.expires_at < new Date()) {
    await DraftBooking.findByIdAndDelete(draft._id);
    return { has_draft: false };
  }

  return {
    has_draft: true,
    step: draft.step,
    last_updated: draft.updated_date
  };
};


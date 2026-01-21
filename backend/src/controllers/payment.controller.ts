import { Request, Response, NextFunction } from 'express';
import * as paymentService from '../services/payment.service.js';
import { sendResponse } from '../utils/response.js';
import { AppError } from '../errors/AppError.js';

/**
 * Create a payment intent
 * POST /api/v1/payments/create-intent
 */
export const createPaymentIntent = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { amount, currency, customerId, metadata } = req.body;
    
    // Validate required fields
    if (!amount || amount <= 0) {
      throw new AppError('Amount is required and must be greater than 0', 400);
    }
    
    // Amount from Flutter is already in cents (amount * 100)
    const paymentIntent = await paymentService.createPaymentIntent({
      amount: parseFloat(amount), // Already in cents from Flutter
      currency: currency || 'usd',
      customerId,
      metadata,
    });
    
    sendResponse(res, 201, {
      success: true,
      message: 'Payment intent created successfully',
      data: paymentIntent,
    });
  } catch (error: any) {
    next(error);
  }
};

/**
 * Confirm a payment intent
 * POST /api/v1/payments/confirm
 */
export const confirmPayment = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { paymentIntentId } = req.body;
    
    if (!paymentIntentId) {
      throw new AppError('Payment intent ID is required', 400);
    }
    
    const paymentIntent = await paymentService.confirmPaymentIntent(paymentIntentId);
    
    sendResponse(res, 200, {
      success: true,
      message: 'Payment confirmed successfully',
      data: paymentIntent,
    });
  } catch (error: any) {
    next(error);
  }
};

/**
 * Get payment intent details
 * GET /api/v1/payments/intent/:id
 */
export const getPaymentIntent = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { id } = req.params;
    
    if (!id) {
      throw new AppError('Payment intent ID is required', 400);
    }
    
    const paymentIntent = await paymentService.getPaymentIntent(id);
    
    sendResponse(res, 200, {
      success: true,
      message: 'Payment intent retrieved successfully',
      data: paymentIntent,
    });
  } catch (error: any) {
    next(error);
  }
};


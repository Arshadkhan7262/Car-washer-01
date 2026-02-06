import express from 'express';
import getStripeInstance from '../config/stripe.config.js';
import Withdrawal from '../models/Withdrawal.model.js';
import Washer from '../models/Washer.model.js';

const router = express.Router();

/**
 * Stripe Webhook Handler
 * Handles Stripe events for transfers and account updates
 * Mounted at /stripe/webhook in index.routes.js
 */

// Stripe webhook endpoint (must be POST and use raw body)
router.post('/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  const stripe = getStripeInstance();
  const sig = req.headers['stripe-signature'];
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

  let event;

  try {
    // Verify webhook signature
    event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
  } catch (err) {
    console.error('❌ [StripeWebhook] Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  try {
    // Handle the event
    switch (event.type) {
      case 'transfer.created':
        await handleTransferCreated(event.data.object);
        break;

      case 'transfer.paid':
        await handleTransferPaid(event.data.object);
        break;

      case 'transfer.failed':
        await handleTransferFailed(event.data.object);
        break;

      case 'account.updated':
        await handleAccountUpdated(event.data.object);
        break;

      default:
        console.log(`ℹ️ [StripeWebhook] Unhandled event type: ${event.type}`);
    }

    // Return a response to acknowledge receipt of the event
    res.json({ received: true });
  } catch (error) {
    console.error('❌ [StripeWebhook] Error processing webhook:', error);
    res.status(500).json({ error: 'Webhook processing failed' });
  }
});

/**
 * Handle transfer.created event
 */
async function handleTransferCreated(transfer) {
  try {
    const withdrawalId = transfer.metadata?.withdrawal_id;
    if (!withdrawalId) {
      console.log('⚠️ [StripeWebhook] Transfer created but no withdrawal_id in metadata');
      return;
    }

    const withdrawal = await Withdrawal.findById(withdrawalId);
    if (withdrawal) {
      withdrawal.stripe_transfer_id = transfer.id;
      await withdrawal.save();
      console.log(`✅ [StripeWebhook] Transfer ${transfer.id} linked to withdrawal ${withdrawalId}`);
    }
  } catch (error) {
    console.error('❌ [StripeWebhook] Error handling transfer.created:', error);
  }
}

/**
 * Handle transfer.paid event
 */
async function handleTransferPaid(transfer) {
  try {
    const withdrawalId = transfer.metadata?.withdrawal_id;
    if (!withdrawalId) {
      return;
    }

    const withdrawal = await Withdrawal.findById(withdrawalId).populate('washer_id');
    if (withdrawal && withdrawal.status === 'processing') {
      // Transfer is confirmed paid by Stripe
      withdrawal.status = 'completed';
      withdrawal.completed_date = new Date();
      await withdrawal.save();
      console.log(`✅ [StripeWebhook] Withdrawal ${withdrawalId} confirmed paid via transfer ${transfer.id}`);
    }
  } catch (error) {
    console.error('❌ [StripeWebhook] Error handling transfer.paid:', error);
  }
}

/**
 * Handle transfer.failed event
 */
async function handleTransferFailed(transfer) {
  try {
    const withdrawalId = transfer.metadata?.withdrawal_id;
    if (!withdrawalId) {
      return;
    }

    const withdrawal = await Withdrawal.findById(withdrawalId).populate('washer_id');
    if (withdrawal && withdrawal.status === 'processing') {
      // Revert withdrawal status and refund wallet
      const washer = withdrawal.washer_id;
      washer.wallet_balance = (washer.wallet_balance || 0) + withdrawal.amount;
      await washer.save();

      withdrawal.status = 'approved'; // Back to approved so admin can retry
      withdrawal.processed_date = null;
      await withdrawal.save();
      console.log(`⚠️ [StripeWebhook] Transfer ${transfer.id} failed for withdrawal ${withdrawalId}. Wallet refunded.`);
    }
  } catch (error) {
    console.error('❌ [StripeWebhook] Error handling transfer.failed:', error);
  }
}

/**
 * Handle account.updated event (Stripe Connect account status changes)
 */
async function handleAccountUpdated(account) {
  try {
    const washer = await Washer.findOne({ stripe_account_id: account.id });
    if (!washer) {
      return;
    }

    // Update account status based on Stripe account
    let status = 'pending';
    let onboardingComplete = false;

    if (account.details_submitted && account.charges_enabled && account.payouts_enabled) {
      status = 'enabled';
      onboardingComplete = true;
    } else if (account.details_submitted) {
      status = 'restricted';
    }

    washer.stripe_account_status = status;
    washer.stripe_account_onboarding_complete = onboardingComplete;
    await washer.save();
    console.log(`✅ [StripeWebhook] Updated Stripe account status for washer ${washer._id}: ${status}`);
  } catch (error) {
    console.error('❌ [StripeWebhook] Error handling account.updated:', error);
  }
}

export default router;

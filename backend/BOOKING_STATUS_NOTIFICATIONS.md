# Booking Status Notifications - Backend Implementation Guide

This guide shows how to send real-time notifications to customers when booking status changes (washer assigned, on the way, arrived, etc.).

## Overview

When a washer or admin updates a booking status, the backend should send a Firebase Cloud Messaging (FCM) notification to the customer with:
- **type**: `'booking_status'`
- **booking_id**: The booking ID
- **status**: The new status (e.g., 'washerAssigned', 'onTheWay', 'arrived', etc.)

## Implementation Examples

### 1. When Washer is Assigned

**Location**: `backend/src/controllers/booking.controller.js` or wherever washer assignment happens

```javascript
import { sendNotificationToUser } from '../services/notification.service.js';
import Booking from '../models/Booking.model.js';
import User from '../models/User.model.js';

// Example: When admin assigns a washer to a booking
export const assignWasher = async (req, res, next) => {
  try {
    const { bookingId } = req.params;
    const { washerId } = req.body;

    // Update booking with washer
    const booking = await Booking.findOne({ booking_id: bookingId });
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    const previousWasherId = booking.washer_id;
    booking.washer_id = washerId;
    booking.status = 'accepted'; // or 'washerAssigned' depending on your status flow
    await booking.save();

    // Get washer name for notification
    const washer = await User.findById(washerId);
    const washerName = washer?.name || 'A washer';

    // Send notification if washer was just assigned (not reassigned)
    if (!previousWasherId && washerId) {
      await sendNotificationToUser(
        booking.customer_id.toString(),
        'Washer Assigned',
        `${washerName} has been assigned to your booking`,
        {
          type: 'booking_status',
          booking_id: booking.booking_id,
          status: 'washerAssigned',
          washer_name: washerName,
        }
      );
    }

    res.json({
      success: true,
      message: 'Washer assigned successfully',
      data: booking,
    });
  } catch (error) {
    next(error);
  }
};
```

### 2. When Status Changes to "On The Way"

**Location**: `backend/src/controllers/booking.controller.js` or washer location update service

```javascript
// Example: When washer updates status to "on the way"
export const updateBookingStatus = async (req, res, next) => {
  try {
    const { bookingId } = req.params;
    const { status } = req.body;

    const booking = await Booking.findOne({ booking_id: bookingId });
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    const previousStatus = booking.status;
    booking.status = status;
    await booking.save();

    // Send notification for specific status changes
    if (status === 'accepted' && previousStatus !== 'accepted') {
      // Status changed to "on the way" (accepted means washer is heading to location)
      await sendNotificationToUser(
        booking.customer_id.toString(),
        'Washer On The Way',
        'Your washer is on the way to your location',
        {
          type: 'booking_status',
          booking_id: booking.booking_id,
          status: 'onTheWay',
        }
      );
    }

    res.json({
      success: true,
      message: 'Status updated successfully',
      data: booking,
    });
  } catch (error) {
    next(error);
  }
};
```

### 3. When Washer Arrives

```javascript
// When status changes to "arrived"
if (status === 'arrived' && previousStatus !== 'arrived') {
  await sendNotificationToUser(
    booking.customer_id.toString(),
    'Washer Arrived',
    'Your washer has arrived at your location',
    {
      type: 'booking_status',
      booking_id: booking.booking_id,
      status: 'arrived',
    }
  );
}
```

### 4. When Washing Starts

```javascript
// When status changes to "washing" or "in_progress"
if ((status === 'washing' || status === 'in_progress') && 
    previousStatus !== 'washing' && previousStatus !== 'in_progress') {
  await sendNotificationToUser(
    booking.customer_id.toString(),
    'Washing Started',
    'Your car wash has started',
    {
      type: 'booking_status',
      booking_id: booking.booking_id,
      status: 'washing',
    }
  );
}
```

### 5. When Service is Completed

```javascript
// When status changes to "completed"
if (status === 'completed' && previousStatus !== 'completed') {
  await sendNotificationToUser(
    booking.customer_id.toString(),
    'Service Completed',
    'Your car wash service has been completed',
    {
      type: 'booking_status',
      booking_id: booking.booking_id,
      status: 'completed',
    }
  );
}
```

## Complete Example: Update Booking Status Function

Here's a complete function that handles all status changes:

```javascript
import { sendNotificationToUser } from '../services/notification.service.js';
import Booking from '../models/Booking.model.js';

export const updateBookingStatus = async (req, res, next) => {
  try {
    const { bookingId } = req.params;
    const { status } = req.body;

    const booking = await Booking.findOne({ booking_id: bookingId });
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    const previousStatus = booking.status;
    booking.status = status;
    await booking.save();

    // Map backend status to frontend status
    const statusMessages = {
      'accepted': { title: 'Washer On The Way', body: 'Your washer is on the way to your location', status: 'onTheWay' },
      'arrived': { title: 'Washer Arrived', body: 'Your washer has arrived at your location', status: 'arrived' },
      'washing': { title: 'Washing Started', body: 'Your car wash has started', status: 'washing' },
      'in_progress': { title: 'Washing Started', body: 'Your car wash has started', status: 'washing' },
      'completed': { title: 'Service Completed', body: 'Your car wash service has been completed', status: 'completed' },
    };

    // Send notification if status changed and has a message
    if (previousStatus !== status && statusMessages[status]) {
      const message = statusMessages[status];
      await sendNotificationToUser(
        booking.customer_id.toString(),
        message.title,
        message.body,
        {
          type: 'booking_status',
          booking_id: booking.booking_id,
          status: message.status,
        }
      );
    }

    res.json({
      success: true,
      message: 'Status updated successfully',
      data: booking,
    });
  } catch (error) {
    next(error);
  }
};
```

## Notification Data Payload Format

The notification data payload should always include:

```javascript
{
  type: 'booking_status',        // Required: Identifies this as a booking status notification
  booking_id: 'BOOKING123',       // Required: The booking ID
  status: 'washerAssigned',      // Required: The new status
  washer_name: 'John Doe',       // Optional: Washer name (if applicable)
}
```

## Status Mapping

| Backend Status | Frontend Status | Notification Title |
|----------------|----------------|-------------------|
| `accepted` | `onTheWay` | "Washer On The Way" |
| `arrived` | `arrived` | "Washer Arrived" |
| `washing` / `in_progress` | `washing` | "Washing Started" |
| `completed` | `completed` | "Service Completed" |

## Testing

To test notifications:

1. **Update booking status** via admin/washer API
2. **Check customer app** - should receive notification immediately
3. **If tracking screen is open** - should update automatically without polling

## Notes

- Notifications are sent **in addition to** the existing polling mechanism (5-second refresh)
- Notifications provide **instant updates** when status changes
- If customer is not on tracking screen, they'll still receive the notification
- If customer is on tracking screen, the screen will refresh immediately when notification is received

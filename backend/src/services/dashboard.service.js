import Booking from '../models/Booking.model.js';
import User from '../models/User.model.js';
import Washer from '../models/Washer.model.js';
import Service from '../models/Service.model.js';

/**
 * Get Dashboard KPIs
 */
export const getDashboardKPIs = async () => {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  // Today's bookings
  const todayBookings = await Booking.countDocuments({
    booking_date: {
      $gte: today,
      $lt: tomorrow
    }
  });

  // Today's revenue
  const todayRevenueData = await Booking.aggregate([
    {
      $match: {
        booking_date: {
          $gte: today,
          $lt: tomorrow
        },
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
  const todayRevenue = todayRevenueData.length > 0 ? todayRevenueData[0].total : 0;

  // This month's revenue
  const monthStart = new Date(today.getFullYear(), today.getMonth(), 1);
  const monthEnd = new Date(today.getFullYear(), today.getMonth() + 1, 1);
  
  const monthRevenueData = await Booking.aggregate([
    {
      $match: {
        booking_date: {
          $gte: monthStart,
          $lt: monthEnd
        },
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
  const thisMonthRevenue = monthRevenueData.length > 0 ? monthRevenueData[0].total : 0;

  // Pending jobs
  const pendingJobs = await Booking.countDocuments({
    status: 'pending'
  });

  // Active washers (online and active status)
  const activeWashers = await Washer.countDocuments({
    status: 'active',
    online_status: true
  });

  return {
    todayBookings,
    revenue: {
      today: todayRevenue,
      thisMonth: thisMonthRevenue
    },
    activeWashers,
    pendingJobs
  };
};

/**
 * Get Dashboard Stats (Bookings trend, Revenue trend, Service popularity)
 */
export const getDashboardStats = async (period = 'week') => {
  const now = new Date();
  let startDate;
  let labels = [];
  let groupBy;

  // Determine date range and grouping based on period
  switch (period) {
    case 'day':
      startDate = new Date(now);
      startDate.setDate(startDate.getDate() - 6); // Last 7 days
      groupBy = { $dateToString: { format: '%Y-%m-%d', date: '$booking_date' } };
      // Generate labels for last 7 days
      for (let i = 6; i >= 0; i--) {
        const date = new Date(now);
        date.setDate(date.getDate() - i);
        labels.push(date.toLocaleDateString('en-US', { weekday: 'short' }));
      }
      break;
    case 'week':
      startDate = new Date(now);
      startDate.setDate(startDate.getDate() - 27); // Last 4 weeks
      groupBy = { $dateToString: { format: '%Y-W%V', date: '$booking_date' } };
      labels = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
      break;
    case 'month':
      startDate = new Date(now);
      startDate.setMonth(startDate.getMonth() - 11); // Last 12 months
      groupBy = { $dateToString: { format: '%Y-%m', date: '$booking_date' } };
      labels = Array.from({ length: 12 }, (_, i) => {
        const date = new Date(now);
        date.setMonth(date.getMonth() - (11 - i));
        return date.toLocaleDateString('en-US', { month: 'short' });
      });
      break;
    default:
      startDate = new Date(now);
      startDate.setDate(startDate.getDate() - 27);
      groupBy = { $dateToString: { format: '%Y-W%V', date: '$booking_date' } };
      labels = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
  }

  // Bookings trend
  const bookingsTrend = await Booking.aggregate([
    {
      $match: {
        booking_date: { $gte: startDate }
      }
    },
    {
      $group: {
        _id: groupBy,
        count: { $sum: 1 }
      }
    },
    {
      $sort: { _id: 1 }
    }
  ]);

  // Revenue trend
  const revenueTrend = await Booking.aggregate([
    {
      $match: {
        booking_date: { $gte: startDate },
        payment_status: 'paid'
      }
    },
    {
      $group: {
        _id: groupBy,
        total: { $sum: '$total' }
      }
    },
    {
      $sort: { _id: 1 }
    }
  ]);

  // Service popularity
  const servicePopularity = await Booking.aggregate([
    {
      $match: {
        booking_date: { $gte: startDate }
      }
    },
    {
      $group: {
        _id: '$service_name',
        count: { $sum: 1 },
        revenue: { $sum: '$total' }
      }
    },
    {
      $sort: { count: -1 }
    },
    {
      $limit: 10
    }
  ]);

  // Format bookings trend
  const bookingsValues = bookingsTrend.map(item => item.count);
  // Pad with zeros if needed
  while (bookingsValues.length < labels.length) {
    bookingsValues.push(0);
  }

  // Format revenue trend
  const revenueValues = revenueTrend.map(item => item.total || 0);
  // Pad with zeros if needed
  while (revenueValues.length < labels.length) {
    revenueValues.push(0);
  }

  // Format service popularity
  const serviceData = servicePopularity.map(item => ({
    name: item._id || 'Unknown',
    bookings: item.count,
    revenue: item.revenue || 0
  }));

  return {
    bookingsTrend: {
      labels,
      values: bookingsValues.slice(0, labels.length)
    },
    revenueTrend: {
      labels,
      values: revenueValues.slice(0, labels.length)
    },
    servicePopularity: serviceData
  };
};

/**
 * Get Recent Activity Feed
 */
export const getRecentActivity = async (limit = 10) => {
  // Get recent bookings
  const recentBookings = await Booking.find()
    .sort({ created_date: -1 })
    .limit(limit)
    .select('booking_id customer_name service_name status created_date')
    .lean();

  // Format activities
  const activities = recentBookings.map(booking => {
    let type = 'booking_created';
    let message = '';

    switch (booking.status) {
      case 'completed':
        type = 'booking_completed';
        message = `Booking #${booking.booking_id || booking._id.toString().slice(-6)} completed`;
        break;
      case 'cancelled':
        type = 'booking_cancelled';
        message = `Booking #${booking.booking_id || booking._id.toString().slice(-6)} cancelled`;
        break;
      case 'accepted':
        type = 'booking_accepted';
        message = `Booking #${booking.booking_id || booking._id.toString().slice(-6)} accepted`;
        break;
      case 'in_progress':
        type = 'booking_in_progress';
        message = `Booking #${booking.booking_id || booking._id.toString().slice(-6)} in progress`;
        break;
      default:
        type = 'booking_created';
        message = `New booking #${booking.booking_id || booking._id.toString().slice(-6)} created`;
    }

    return {
      id: booking._id.toString(),
      type,
      message,
      description: `${booking.customer_name} - ${booking.service_name}`,
      timestamp: booking.created_date
    };
  });

  return activities;
};


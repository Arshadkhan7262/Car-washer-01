import express from 'express';
import authRoutes from './auth.routes.js';
import firebaseAuthRoutes from './firebaseAuth.routes.js';
import customerAuthRoutes from './customerAuth.routes.js';
import washerAuthRoutes from './washerAuth.routes.js';
import authGoogleRoutes from './authGoogle.routes.js';
import dashboardRoutes from './dashboard.routes.js';
import bookingRoutes from './booking.routes.js';
import serviceRoutes from './service.routes.js';
import customerRoutes from './customer.routes.js';
import washerRoutes from './washer.routes.js';
import couponRoutes from './coupon.routes.js';
import adminNotificationRoutes from './adminNotification.routes.js';

// Washer App Screen-specific routes
import washerHomeRoutes from './washerHome.routes.js';
import washerJobsRoutes from './washerJobs.routes.js';
import washerWalletRoutes from './washerWallet.routes.js';
import washerProfileRoutes from './washerProfile.routes.js';
import washerLocationRoutes from './washerLocation.routes.js';

const router = express.Router();

// Health check
router.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Server is running',
    timestamp: new Date().toISOString()
  });
});

// Authentication routes
router.use('/admin/auth', authRoutes); // Admin uses email/password
router.use('/auth', firebaseAuthRoutes); // Firebase auth for Customers (legacy)
router.use('/auth', authGoogleRoutes); // Google OAuth authentication (POST /auth/google/customer)
router.use('/customer/auth', customerAuthRoutes); // Customer email/password authentication
router.use('/washer/auth', washerAuthRoutes); // Washer email/password authentication (no Firebase)

// Admin API routes
router.use('/admin/dashboard', dashboardRoutes);
router.use('/admin/bookings', bookingRoutes);
router.use('/admin/services', serviceRoutes);
router.use('/admin/customers', customerRoutes);
router.use('/admin/washers', washerRoutes);
router.use('/admin/coupons', couponRoutes);
router.use('/admin/notifications', adminNotificationRoutes); // Notifications: send push notifications

// Washer App Screen-specific API routes
router.use('/washer/home', washerHomeRoutes); // Home screen: dashboard stats
router.use('/washer/jobs', washerJobsRoutes); // Jobs screen: job management
router.use('/washer/wallet', washerWalletRoutes); // Wallet screen: balance, transactions, withdrawals
router.use('/washer/profile', washerProfileRoutes); // Profile screen: profile data and updates
router.use('/washer/location', washerLocationRoutes); // Location: update and get washer location

// Customer App (wash_away) Screen-specific API routes
import customerProfileRoutes from './customerProfile.routes.js';
import customerServiceRoutes from './customerService.routes.js';
import customerVehicleTypeRoutes from './customerVehicleType.routes.js';
import customerBookingRoutes from './customerBooking.routes.js';
// DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
// import draftBookingRoutes from './draftBooking.routes.js';
import customerAddressRoutes from './customerAddress.routes.js';
import customerVehicleRoutes from './customerVehicle.routes.js';
router.use('/customer/profile', customerProfileRoutes); // Profile screen: profile data, stats, and preferences
router.use('/customer/services', customerServiceRoutes); // Services: public endpoint for customers to view services
router.use('/customer/vehicle-types', customerVehicleTypeRoutes); // Vehicle types: public endpoint for customers to view vehicle types
router.use('/customer/bookings', customerBookingRoutes); // Bookings: customer booking management
// DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
// router.use('/customer/bookings/draft', draftBookingRoutes); // Draft bookings: save/load booking progress
router.use('/customer/addresses', customerAddressRoutes); // Addresses: customer address management
router.use('/customer/vehicles', customerVehicleRoutes); // Vehicles: customer vehicle management
import customerCouponRoutes from './customerCoupon.routes.js';
router.use('/customer/coupons', customerCouponRoutes); // Coupons: customer coupon validation
import customerNotificationRoutes from './customerNotification.routes.js';
router.use('/customer/notifications', customerNotificationRoutes); // Notifications: FCM token management

// Admin Vehicle Type routes
import vehicleTypeRoutes from './vehicleType.routes.js';
router.use('/admin/vehicle-types', vehicleTypeRoutes); // Vehicle types: admin CRUD operations

export default router;







import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { connectDatabase } from './src/config/database.config.js';
import cmsRoutes from './src/routes/cms.routes.js';
import publicCMSRoutes from './src/routes/publicCMS.routes.js';
import adminBankAccountRoutes from './src/routes/adminBankAccount.routes.js';
import bankAccountRoutes from './src/routes/bankAccount.routes.js';
import withdrawalRoutes from './src/routes/withdrawal.routes.js';
import bannerRoutes from './src/routes/banner.routes.js';
import customerBannerRoutes from './src/routes/customerBanner.routes.js';
import stripeConnectRoutes from './src/routes/stripeConnect.routes.js';

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static files from uploads directory
app.use('/uploads', express.static('uploads'));

// Health check
app.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Server is running',
    timestamp: new Date().toISOString()
  });
});

// API Routes
app.use('/api/v1/admin/cms', cmsRoutes);
app.use('/api/v1/cms', publicCMSRoutes);
app.use('/api/v1/admin/bank-accounts', adminBankAccountRoutes);
app.use('/api/v1/washer/bank-account', bankAccountRoutes);
app.use('/api/v1/admin/withdrawal', withdrawalRoutes);
app.use('/api/v1/washer/withdrawal', withdrawalRoutes);
app.use('/api/v1/admin/settings/banners', bannerRoutes);
app.use('/api/v1/customer/banners', customerBannerRoutes);
app.use('/api/v1/washer/stripe-connect', stripeConnectRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(err.statusCode || 500).json({
    success: false,
    message: err.message || 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

// Start server
async function startServer() {
  try {
    // Connect to database
    await connectDatabase();
    console.log('✅ MongoDB connected');

    // Start server
    app.listen(PORT, () => {
      console.log(`🚀 Server running on port ${PORT}`);
      console.log(`📍 Health check: http://localhost:${PORT}/health`);
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
}

startServer();

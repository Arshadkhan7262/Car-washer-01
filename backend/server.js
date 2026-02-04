import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import os from 'os';
import path from 'path';
import { fileURLToPath } from 'url';
import connectDatabase from './src/config/database.config.js';
import errorHandler from './src/errors/errorHandler.js';
import routes from './src/routes/index.routes.js';
import getStripeInstance from './src/config/stripe.config.js';
// Initialize Firebase Admin SDK early (required for notifications)
import './src/config/firebase.config.js';

// Load environment variables from backend/.env (same dir as server.js)
dotenv.config({ path: path.join(path.dirname(fileURLToPath(import.meta.url)), '.env') });

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();

// Middleware
app.use(cors());

// Stripe webhook needs raw body for signature verification
// Must be before express.json() middleware
app.use('/api/v1/stripe/webhook', express.raw({ type: 'application/json' }));

// Increase body parser limit for large Firebase tokens
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Serve static files from uploads directory
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Enhanced Request logging middleware
app.use((req, res, next) => {
  const startTime = Date.now();
  const timestamp = new Date().toISOString();
  
  // Log incoming request
  console.log(`\n📥 [${timestamp}] ${req.method} ${req.originalUrl || req.url}`);
  console.log(`   IP: ${req.ip || req.connection.remoteAddress || 'unknown'}`);
  
  // Log request body (if present and not too large)
  if (req.body && Object.keys(req.body).length > 0) {
    const bodyStr = JSON.stringify(req.body);
    if (bodyStr.length < 500) {
      console.log(`   Body: ${bodyStr}`);
    } else {
      console.log(`   Body: [Large payload - ${bodyStr.length} chars]`);
    }
  }
  
  // Log query parameters (if present)
  if (req.query && Object.keys(req.query).length > 0) {
    console.log(`   Query: ${JSON.stringify(req.query)}`);
  }
  
  // Log response when it finishes (only once)
  let responseLogged = false;
  
  const logResponse = () => {
    if (responseLogged) return;
    responseLogged = true;
    
    const duration = Date.now() - startTime;
    const statusCode = res.statusCode;
    const statusEmoji = statusCode >= 200 && statusCode < 300 ? '✅' : 
                        statusCode >= 400 && statusCode < 500 ? '⚠️' : 
                        statusCode >= 500 ? '❌' : 'ℹ️';
    
    console.log(`${statusEmoji} [${new Date().toISOString()}] ${req.method} ${req.originalUrl || req.url} - ${statusCode} (${duration}ms)`);
  };
  
  const originalSend = res.send;
  const originalJson = res.json;
  
  res.send = function(data) {
    logResponse();
    return originalSend.call(this, data);
  };
  
  res.json = function(data) {
    logResponse();
    return originalJson.call(this, data);
  };
  
  // Also log on finish event (for cases where send/json might not be called)
  res.on('finish', logResponse);
  
  next();
});

// Routes
app.use('/api/v1', routes);

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.originalUrl} not found`
  });
});

// Global error handler
app.use(errorHandler);

// Connect to database and start server
const PORT = process.env.PORT || 3000;

// Get local IP address for network access
const getLocalIP = () => {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      // Skip internal (loopback) and non-IPv4 addresses
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return 'localhost';
};

const localIP = getLocalIP();

const startServer = async () => {
  try {
    // Connect to MongoDB (non-blocking - server will start even if MongoDB fails)
    connectDatabase().catch((error) => {
      console.error('⚠️ MongoDB connection failed, but server will continue running');
      console.error('   You can still test API endpoints, but database operations will fail');
      console.error('   Fix MongoDB connection to enable full functionality');
    });

    // Start server - bind to 0.0.0.0 to allow network access
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`🚀 Server running on port ${PORT}`);
      console.log(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`🌐 Local API URL: http://localhost:${PORT}/api/v1`);
      console.log(`🌐 Network API URL: http://${localIP}:${PORT}/api/v1`);
      console.log(`\n💡 Use the Network API URL to access from other devices on the same network`);
      console.log(`⚠️ Note: MongoDB connection may still be in progress...`);
      try {
        getStripeInstance();
      } catch (e) {
        console.warn('⚠️ Stripe not configured:', e.message);
      }
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error.message || error);
    process.exit(1);
  }
};

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
  console.error('❌ UNHANDLED REJECTION! Shutting down...');
  console.error('Error:', err);
  // Don't exit - let server continue, but log the error
});

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  console.error('❌ UNCAUGHT EXCEPTION! Shutting down...');
  console.error('Error:', err);
  // Don't exit - let server continue, but log the error
});

startServer();

// Handle unhandled promise rejections (don't exit - log and continue)
process.on('unhandledRejection', (err) => {
  console.error('❌ UNHANDLED REJECTION:', err);
  console.error('Stack:', err.stack);
  // Don't exit - let server continue, but log the error
});

// Handle uncaught exceptions (don't exit - log and continue)
process.on('uncaughtException', (err) => {
  console.error('❌ UNCAUGHT EXCEPTION:', err);
  console.error('Stack:', err.stack);
  // Don't exit - let server continue, but log the error
});









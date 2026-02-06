/**
 * API Request Logger Middleware
 * Logs all incoming API requests with detailed information
 * 
 * Logs:
 * - Timestamp (ISO format)
 * - HTTP method (GET, POST, PUT, DELETE)
 * - Full API path
 * - Client IP address
 * - HTTP response status code
 * - Request execution time in milliseconds
 */

/**
 * Fields to exclude from request body logging (sensitive data)
 */
const SENSITIVE_FIELDS = [
  'password',
  'token',
  'accessToken',
  'refreshToken',
  'authToken',
  'authorization',
  'otp',
  'otpCode',
  'secret',
  'apiKey',
  'api_key',
  'secretKey',
  'secret_key',
  'privateKey',
  'private_key',
];

/**
 * Sanitize request body to remove sensitive fields
 * @param {Object} body - Request body object
 * @returns {Object} - Sanitized body with sensitive fields masked
 */
const sanitizeBody = (body) => {
  if (!body || typeof body !== 'object') {
    return body;
  }

  const sanitized = { ...body };
  
  for (const field of SENSITIVE_FIELDS) {
    if (sanitized[field] !== undefined) {
      sanitized[field] = '[REDACTED]';
    }
  }

  return sanitized;
};

/**
 * Get client IP address from request
 * @param {Object} req - Express request object
 * @returns {string} - Client IP address
 */
const getClientIP = (req) => {
  return (
    req.ip ||
    req.connection?.remoteAddress ||
    req.socket?.remoteAddress ||
    (req.headers['x-forwarded-for'] || '').split(',')[0].trim() ||
    req.headers['x-real-ip'] ||
    'unknown'
  );
};

/**
 * API Logger Middleware
 * Logs all incoming requests with detailed information
 */
const apiLogger = (req, res, next) => {
  // Optional: Only log in development environment
  // Set ENABLE_API_LOGGER=false in .env to disable in production
  const enableLogger = process.env.ENABLE_API_LOGGER !== 'false';
  const isDevelopment = process.env.NODE_ENV !== 'production';
  
  // Skip logging if disabled (default: enabled in all environments)
  if (!enableLogger && !isDevelopment) {
    return next();
  }

  const startTime = Date.now();
  const method = req.method;
  const path = req.originalUrl || req.url;
  const clientIP = getClientIP(req);

  // Track if response has been logged (to avoid duplicate logs)
  let responseLogged = false;

  /**
   * Log response when it finishes
   * Format matches the requested specification exactly
   */
  const logResponse = () => {
    if (responseLogged) return;
    responseLogged = true;

    const duration = Date.now() - startTime;
    const statusCode = res.statusCode;
    const timestamp = new Date().toISOString();

    // Log in the exact format requested
    console.log(`📥 [${timestamp}] ${method} ${path}`);
    console.log(`   IP: ${clientIP}`);
    console.log(`   Status: ${statusCode}`);
    console.log(`   Time: ${duration}ms`);
  };

  // Override res.send to log response
  const originalSend = res.send;
  res.send = function (data) {
    logResponse();
    return originalSend.call(this, data);
  };

  // Override res.json to log response
  const originalJson = res.json;
  res.json = function (data) {
    logResponse();
    return originalJson.call(this, data);
  };

  // Also log on finish event (for cases where send/json might not be called)
  res.on('finish', logResponse);

  // Continue to next middleware
  next();
};

export default apiLogger;

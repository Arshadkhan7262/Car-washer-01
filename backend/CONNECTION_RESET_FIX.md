# Fix "Connection Reset by Peer" Error

## Problem
Getting "Connection reset by peer" when trying to login with Google Sign-In. The backend receives the request but immediately closes the connection.

## Root Cause
The backend was crashing when MongoDB wasn't connected or when database operations failed, causing the connection to reset.

## Fixes Applied

### 1. MongoDB Connection Check
- Added check at start of `googleLoginWithFirebase()` function
- Returns 503 immediately if MongoDB isn't connected (prevents timeout)
- Prevents database operations from running when DB is unavailable

### 2. Error Handling
- Wrapped all database operations (`User.findOne`, `User.create`, `user.save`, etc.) in try-catch
- All database errors now return proper HTTP error responses instead of crashing
- Added MongoDB connection state checks in all error handlers

### 3. Mongoose Buffer Settings
- Set `mongoose.set('bufferCommands', false)` - prevents Mongoose from buffering operations
- Set `mongoose.set('bufferTimeoutMS', 0)` - fails immediately if not connected
- Prevents operations from hanging when MongoDB isn't available

### 4. Process Error Handlers
- Modified unhandled rejection/exception handlers to log errors instead of exiting
- Prevents server from crashing on unexpected errors
- Errors are logged but server continues running

### 5. Body Parser Limit
- Increased Express body parser limit to 10MB
- Ensures large Firebase ID tokens are accepted

## Files Modified

1. `backend/src/services/googleAuthFirebase.service.js`
   - Added MongoDB connection check
   - Wrapped all database operations in try-catch
   - Added proper error handling

2. `backend/src/config/database.config.js`
   - Added Mongoose buffer settings to fail fast

3. `backend/server.js`
   - Increased body parser limit
   - Modified process error handlers

## Testing

After restarting backend:

1. **Check MongoDB connection** in backend logs:
   - Should see: `✅ MongoDB Connected: ...`
   - If not: `❌ MongoDB connection error: ...`

2. **Test Google Sign-In** from Flutter app:
   - Should now get proper error message if MongoDB isn't connected
   - Should work if MongoDB is connected

3. **Check backend logs** when making request:
   - Should see request logged
   - Should see response or error logged
   - Should NOT see "Connection reset" - should see proper error response

## Next Steps

1. **Restart backend** to apply changes:
   ```powershell
   # Stop current backend (Ctrl+C)
   cd d:\Car-washer-01\backend
   npm run dev
   ```

2. **Check MongoDB connection** in backend logs

3. **Try Google Sign-In again** from Flutter app

4. **If still getting errors**, check backend terminal for specific error messages

# Starting the Backend Server

## Prerequisites

1. **MongoDB must be running**
   - Local MongoDB: Make sure MongoDB service is running
   - Or use MongoDB Atlas (cloud)

2. **Node.js installed** (v14 or higher)

3. **Dependencies installed**
   ```bash
   cd backend
   npm install
   ```

## Setup .env File

Create a `.env` file in the `backend` directory with the following:

```env
# Server Configuration
PORT=3000
NODE_ENV=development

# Database Configuration
MONGODB_URI=mongodb://localhost:27017/carwashpro
# OR for MongoDB Atlas:
# MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/carwashpro

# JWT Configuration
JWT_SECRET=your_super_secret_jwt_key_change_this_in_production
JWT_EXPIRE=7d
JWT_REFRESH_SECRET=your_super_secret_refresh_key_change_this_in_production
JWT_REFRESH_EXPIRE=30d

# SMTP Email Configuration (for OTP emails)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your_email@gmail.com
SMTP_PASSWORD=your_app_password_here

# Admin Configuration
ADMIN_EMAIL=admin@carwashpro.com
ADMIN_PASSWORD=admin123
```

## Start the Server

### Option 1: Production Mode
```bash
cd backend
npm start
```

### Option 2: Development Mode (with auto-reload)
```bash
cd backend
npm run dev
```

## Verify Server is Running

Once started, you should see:
```
✅ MongoDB Connected: localhost
🚀 Server running on port 3000
📍 Environment: development
🌐 API URL: http://localhost:3000/api/v1
```

## Test the Server

Open your browser or use Postman:
```
GET http://localhost:3000/api/v1/health
```

Expected response:
```json
{
  "success": true,
  "message": "Server is running",
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

## Troubleshooting

### Server won't start
1. Check if MongoDB is running:
   ```bash
   # Windows
   Get-Service MongoDB
   
   # Or check if port 27017 is in use
   netstat -an | findstr 27017
   ```

2. Check if port 3000 is already in use:
   ```bash
   netstat -an | findstr 3000
   ```

3. Verify .env file exists and has correct MONGODB_URI

### MongoDB Connection Error
- Make sure MongoDB service is running
- Check MONGODB_URI in .env file
- For MongoDB Atlas, ensure IP whitelist includes your IP

### Email Service Error
- SMTP configuration is optional for development
- Server will still run without email service
- OTP will be logged to console in development mode


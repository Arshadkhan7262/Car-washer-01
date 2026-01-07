# Car Wash Pro - Backend API

Backend API for Car Wash Pro Platform built with Node.js, Express.js, and MongoDB.

## Features

- ✅ Admin Authentication (JWT)
- ✅ Role-based Access Control
- ✅ MongoDB with Mongoose
- ✅ Secure password hashing with bcrypt
- ✅ Error handling middleware
- ✅ Environment-based configuration

## Prerequisites

- Node.js (v18 or higher)
- MongoDB (local or cloud instance)
- npm or yarn

## Installation

1. Install dependencies:
```bash
npm install
```

2. Create `.env` file from `.env.example`:
```bash
cp .env.example .env
```

3. Update `.env` with your configuration:
```env
PORT=3000
NODE_ENV=development
MONGODB_URI=mongodb://localhost:27017/carwash_pro
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_REFRESH_SECRET=your-super-secret-refresh-key-change-this-in-production
JWT_EXPIRE=24h
JWT_REFRESH_EXPIRE=7d
```

4. Seed super admin (optional):
```bash
npm run seed
```

## Running the Server

### Development Mode
```bash
npm run dev
```

### Production Mode
```bash
npm start
```

The server will start on `http://localhost:3000`

## API Endpoints

### Authentication

#### Login
```http
POST /api/v1/admin/auth/login
Content-Type: application/json

{
  "email": "admin@carwashpro.com",
  "password": "Admin@123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "admin": {
      "id": "...",
      "email": "admin@carwashpro.com",
      "role": "super_admin",
      "name": "Super Admin"
    }
  }
}
```

#### Refresh Token
```http
POST /api/v1/admin/auth/refresh
Content-Type: application/json

{
  "refreshToken": "refresh_token_here"
}
```

#### Logout
```http
POST /api/v1/admin/auth/logout
Authorization: Bearer {token}
```

#### Get Current Admin
```http
GET /api/v1/admin/auth/me
Authorization: Bearer {token}
```

## Project Structure

```
backend/
├── src/
│   ├── config/          # Configuration files
│   ├── controllers/     # Route controllers
│   ├── models/          # Mongoose models
│   ├── routes/          # Express routes
│   ├── services/        # Business logic
│   ├── middleware/      # Express middleware
│   ├── errors/          # Error handling
│   └── database/        # Database seeds & migrations
├── server.js            # Entry point
├── package.json
└── .env.example
```

## Environment Variables

- `PORT` - Server port (default: 3000)
- `NODE_ENV` - Environment (development/production)
- `MONGODB_URI` - MongoDB connection string
- `JWT_SECRET` - Secret key for JWT access tokens
- `JWT_REFRESH_SECRET` - Secret key for JWT refresh tokens
- `JWT_EXPIRE` - Access token expiry (default: 24h)
- `JWT_REFRESH_EXPIRE` - Refresh token expiry (default: 7d)

## Default Super Admin

After running `npm run seed`, you can login with:
- **Email:** admin@carwashpro.com (or as configured in .env)
- **Password:** Admin@123 (or as configured in .env)

⚠️ **Important:** Change the default password after first login!

## License

ISC









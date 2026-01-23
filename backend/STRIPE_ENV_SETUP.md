# Stripe Environment Variable Setup

## Quick Setup

1. **Create `.env` file** in the `backend/` directory (if it doesn't exist)

2. **Add your Stripe secret key** to the `.env` file:

```env
STRIPE_SECRET_KEY=sk_test_xxx_your_stripe_secret_key_here
```

3. **Make sure your `.env` file includes other required variables** (MongoDB, JWT, etc.)

## Complete .env File Example

```env
# MongoDB Configuration
MONGODB_URI=your_mongodb_uri_here

# JWT Configuration
JWT_SECRET=your_jwt_secret_here
JWT_REFRESH_SECRET=your_jwt_refresh_secret_here
JWT_EXPIRE=24h
JWT_REFRESH_EXPIRE=7d

# Stripe Configuration
STRIPE_SECRET_KEY=sk_test_xxx_your_stripe_secret_key_here

# Server Configuration
PORT=3000
NODE_ENV=development
```

## Important Notes

- **Never commit `.env` file to Git** - it contains sensitive keys
- The `.env.example` file has been created as a template
- Restart your backend server after adding the Stripe key
- Use test keys (`sk_test_...`) for development
- Use live keys (`sk_live_...`) for production

## Verification

After adding the key, restart your server. You should see:
```
✅ Stripe initialized successfully
```

If you see an error, check:
1. The key is correctly added to `.env`
2. No extra spaces or quotes around the key
3. The server was restarted after adding the key


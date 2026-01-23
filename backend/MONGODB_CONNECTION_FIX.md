# MongoDB Connection Fix Guide

## Current Issue
MongoDB connection is timing out with error: `queryTxt ETIMEOUT`

This happens when DNS cannot resolve MongoDB Atlas SRV records.

## Solutions

### Solution 1: Use Standard Connection String (Recommended for Development)

Instead of `mongodb+srv://`, use a standard connection string:

1. Get your MongoDB Atlas connection details
2. Convert from SRV to standard format:

**Current (SRV - causing timeout):**
```
mongodb+srv://ramzan123:ramzan123@cluster0.rixikvd.mongodb.net/carwash_pro
```

**Convert to Standard Format:**
```
mongodb://ramzan123:ramzan123@cluster0-shard-00-00.rixikvd.mongodb.net:27017,cluster0-shard-00-01.rixikvd.mongodb.net:27017,cluster0-shard-00-02.rixikvd.mongodb.net:27017/carwash_pro?ssl=true&replicaSet=atlas-xxxxx-shard-0&authSource=admin&retryWrites=true&w=majority
```

**Or simpler (if you have single node):**
```
mongodb://ramzan123:ramzan123@cluster0.rixikvd.mongodb.net:27017/carwash_pro?ssl=true&retryWrites=true&w=majority
```

### Solution 2: Use Local MongoDB (Easiest for Development)

1. Install MongoDB locally or use Docker:
   ```bash
   # Using Docker
   docker run -d -p 27017:27017 --name mongodb mongo:latest
   ```

2. Update `.env`:
   ```
   MONGODB_URI=mongodb://localhost:27017/carwash_pro
   ```

### Solution 3: Fix DNS Resolution

1. **Change DNS Server:**
   - Windows: Settings > Network > Change adapter options > Right-click your connection > Properties > IPv4 > Use custom DNS:
     - Primary: `8.8.8.8` (Google DNS)
     - Secondary: `1.1.1.1` (Cloudflare DNS)

2. **Flush DNS Cache:**
   ```powershell
   ipconfig /flushdns
   ```

3. **Check Internet Connection:**
   - Ensure you can access MongoDB Atlas dashboard
   - Check if firewall is blocking DNS queries

### Solution 4: Whitelist IP in MongoDB Atlas

1. Get your public IP:
   ```powershell
   (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing).Content
   ```

2. Go to MongoDB Atlas Dashboard:
   - Network Access > Add IP Address
   - Add your current IP or use `0.0.0.0/0` for development (not recommended for production)

### Solution 5: Use Connection String with Options

Add connection options to handle timeouts better:

```
mongodb+srv://ramzan123:ramzan123@cluster0.rixikvd.mongodb.net/carwash_pro?retryWrites=true&w=majority&serverSelectionTimeoutMS=30000
```

## Quick Fix (Try This First)

Update your `.env` file with increased timeout:

The database config has been updated to use 30s timeout instead of 10s. Try running the server again:

```bash
npm start
```

If it still fails, try Solution 1 (use standard connection string) or Solution 2 (use local MongoDB).

## Testing Connection

After updating, test the connection:

```bash
# Test MongoDB connection
node -e "const mongoose = require('mongoose'); mongoose.connect(process.env.MONGODB_URI).then(() => { console.log('Connected!'); process.exit(0); }).catch(err => { console.error('Error:', err.message); process.exit(1); });"
```

## Recommended for Development

For local development, use **Solution 2** (Local MongoDB) as it's:
- Faster
- No network dependency
- No DNS issues
- Free and easy to set up

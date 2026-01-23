# Quick Fix: Update MongoDB Connection String

## Your Current Public IP
**154.81.244.126** - Make sure this is whitelisted in MongoDB Atlas!

## Option 1: Whitelist Your IP in MongoDB Atlas (Recommended)

1. Go to [MongoDB Atlas Dashboard](https://cloud.mongodb.com/)
2. Navigate to **Network Access** → **IP Access List**
3. Click **Add IP Address**
4. Add your current IP: `154.81.244.126`
5. Or for development: `0.0.0.0/0` (allows all IPs - **NOT for production**)
6. Wait 1-2 minutes for changes to propagate
7. Restart the server

## Option 2: Update Connection String Manually

Edit your `.env` file and change:

**From:**
```
MONGODB_URI=mongodb+srv://ramzan123:ramzan123@cluster0.rixikvd.mongodb.net/carwash_pro
```

**To (Standard Connection String):**
```
MONGODB_URI=mongodb://ramzan123:ramzan123@cluster0.rixikvd.mongodb.net:27017/carwash_pro?ssl=true&retryWrites=true&w=majority
```

**Or get the exact connection string from MongoDB Atlas:**
1. Go to MongoDB Atlas → **Connect** → **Connect your application**
2. Select **Node.js** driver
3. Choose **Standard connection string** (not SRV)
4. Copy and paste into your `.env` file

## Option 3: Use Local MongoDB (Easiest for Development)

If you have Docker installed:
```powershell
docker run -d -p 27017:27017 --name mongodb mongo:latest
```

Then update `.env`:
```
MONGODB_URI=mongodb://localhost:27017/carwash_pro
```

## After Fixing

Restart the server:
```powershell
cd backend
npm start
```

You should see:
```
✅ MongoDB Connected: cluster0.rixikvd.mongodb.net
🚀 Server running on port 3000
🌐 Network API URL: http://192.168.168.196:3000/api/v1
```

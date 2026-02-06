# Check MongoDB Connection Status

## Quick Check

**The error you're seeing means MongoDB is not connected to your backend server.**

## How to Fix

### Step 1: Check Backend Console

Look at your backend server terminal window. You should see one of these:

**✅ If MongoDB is connected:**
```
✅ MongoDB Connected: cluster0.rixikvd.mongodb.net
🚀 Server running on port 3000
```

**❌ If MongoDB is NOT connected:**
```
⚠️ MongoDB connection failed, but server will continue running
❌ MongoDB connection error: [error message]
```

### Step 2: Common MongoDB Connection Issues

#### Issue 1: IP Not Whitelisted in MongoDB Atlas

**Solution:**
1. Go to [MongoDB Atlas Dashboard](https://cloud.mongodb.com/)
2. Navigate to **Network Access** → **IP Access List**
3. Click **Add IP Address**
4. Add: `0.0.0.0/0` (allows all IPs - for development only)
5. Wait 1-2 minutes
6. Restart backend server

#### Issue 2: Wrong Connection String

**Check your `.env` file:**
```env
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/database_name
```

**Make sure:**
- Username and password are correct
- Cluster name is correct
- Database name is correct

#### Issue 3: Network/DNS Issues

**Try using standard connection string instead of SRV:**

In `.env`, change from:
```
MONGODB_URI=mongodb+srv://...
```

To:
```
MONGODB_URI=mongodb://username:password@cluster.mongodb.net:27017/database_name?ssl=true
```

### Step 3: Restart Backend Server

After fixing MongoDB connection:

1. **Stop the backend server** (Ctrl+C in the terminal)
2. **Start it again:**
   ```powershell
   cd "F:\mit\Upwork Client Mit\Car-washer-01\backend"
   npm run dev
   ```

3. **Look for this message:**
   ```
   ✅ MongoDB Connected: cluster0.rixikvd.mongodb.net
   ```

### Step 4: Test Connection

Once you see "✅ MongoDB Connected", try Google sign-in again in the Flutter app.

## Still Not Working?

Check the backend console for the exact MongoDB error message and share it for further troubleshooting.

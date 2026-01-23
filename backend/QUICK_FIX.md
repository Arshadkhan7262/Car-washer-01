# Quick Fix for Connection Timeout Error

## The Problem
Your mobile device cannot connect to `http://192.168.18.31:3000/api/v1` because:
1. **MongoDB Atlas IP is not whitelisted** (server can't start)
2. **Windows Firewall might be blocking** (even if server starts)

## Step-by-Step Fix

### Step 1: Whitelist Your IP in MongoDB Atlas ⚠️ CRITICAL

1. **Get your current public IP:**
   - Visit: https://api.ipify.org
   - Or run in PowerShell: `(Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing).Content`

2. **Add IP to MongoDB Atlas:**
   - Go to: https://cloud.mongodb.com/
   - Click on your cluster
   - Go to **"Network Access"** → **"IP Access List"**
   - Click **"Add IP Address"**
   - Enter your IP (or `0.0.0.0/0` for development - allows all IPs)
   - Click **"Confirm"**
   - **Wait 1-2 minutes** for changes to take effect

### Step 2: Start the Server

**Option A: Use the diagnostic script (Recommended)**
```powershell
cd backend
.\start-server.ps1
```

**Option B: Manual start**
```powershell
cd backend
npm run dev
```

**Expected output when successful:**
```
✅ MongoDB Connected: cluster0.rixikvd.mongodb.net
🚀 Server running on port 3000
🌐 Local API URL: http://localhost:3000/api/v1
🌐 Network API URL: http://192.168.18.31:3000/api/v1
```

### Step 3: Verify Server is Running

**Test locally:**
```powershell
curl http://localhost:3000/api/v1/health
```

**Should return:**
```json
{"success":true,"message":"Server is running","timestamp":"..."}
```

### Step 4: Check Windows Firewall

The script automatically creates a firewall rule, but you can verify:

```powershell
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*3000*"}
```

If needed, manually allow:
```powershell
New-NetFirewallRule -DisplayName "Node.js Backend Port 3000" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
```

### Step 5: Test from Mobile Device

1. **Ensure both devices are on the same WiFi network**
2. **Verify the IP address in mobile app:**
   - Check `wash_away/lib/util/constants.dart`
   - Should be: `http://192.168.18.31:3000/api/v1`
3. **Test connection:**
   - Open mobile app
   - Try to login or make any API call
   - Should work now!

## Troubleshooting

### Server won't start
- ✅ Check MongoDB Atlas IP whitelist
- ✅ Verify `.env` file has correct `MONGODB_URI`
- ✅ Check Node.js is installed: `node --version`

### Server starts but mobile can't connect
- ✅ Verify both devices on same WiFi
- ✅ Check Windows Firewall allows port 3000
- ✅ Verify IP address: `192.168.18.31` (run `ipconfig` to confirm)
- ✅ Test from mobile browser: `http://192.168.18.31:3000/api/v1/health`

### Still having issues?
1. Check server logs for errors
2. Verify MongoDB Atlas connection status
3. Test with `curl` or Postman from your computer first
4. Check Windows Firewall logs

## Quick Test Commands

```powershell
# Get your public IP (for MongoDB Atlas)
(Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing).Content

# Get your local network IP (for mobile app)
Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*"}

# Check if server is running
netstat -an | Select-String ":3000.*LISTENING"

# Test server locally
curl http://localhost:3000/api/v1/health

# Check firewall rules
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*3000*"}
```











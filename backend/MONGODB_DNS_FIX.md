# MongoDB DNS Connection Error Fix

## Error: `querySrv EREFUSED`

This error occurs when your DNS server cannot resolve MongoDB Atlas SRV records (`_mongodb._tcp.cluster0.rixikvd.mongodb.net`).

## Your Current Public IP
**39.36.74.174** - Make sure this is whitelisted in MongoDB Atlas!

## Solutions (Try in order)

### Solution 1: Change DNS Server (Recommended - Fastest Fix)

Your current DNS server (`csp1.zte.com.cn.home`) might not properly resolve SRV records.

**Windows:**
1. Open **Network Settings** → **Change adapter options**
2. Right-click your network adapter → **Properties**
3. Select **Internet Protocol Version 4 (TCP/IPv4)** → **Properties**
4. Select **Use the following DNS server addresses:**
5. Enter:
   - **Preferred DNS server:** `8.8.8.8` (Google DNS)
   - **Alternate DNS server:** `1.1.1.1` (Cloudflare DNS)
6. Click **OK** and restart your computer

**Or via PowerShell (Run as Administrator):**
```powershell
# Set Google DNS
Set-DnsClientServerAddress -InterfaceAlias "Wi-Fi" -ServerAddresses 8.8.8.8,1.1.1.1

# Or for Ethernet
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 8.8.8.8,1.1.1.1
```

**Verify DNS change:**
```powershell
Get-DnsClientServerAddress
```

### Solution 2: Whitelist IP in MongoDB Atlas

1. Go to [MongoDB Atlas Dashboard](https://cloud.mongodb.com/)
2. Navigate to **Network Access** → **IP Access List**
3. Click **Add IP Address**
4. Add your current IP: `39.36.74.174`
5. Or for development: `0.0.0.0/0` (allows all IPs - **NOT for production**)
6. Wait 1-2 minutes for changes to propagate

### Solution 3: Use Standard Connection String (Alternative)

If SRV records still fail, you can use a standard connection string format. However, you'll need to get the actual MongoDB server IPs from MongoDB Atlas.

**Current connection string (SRV):**
```
mongodb+srv://ramzan123:ramzan123@cluster0.rixikvd.mongodb.net/carwash_pro
```

**To get standard connection string:**
1. Go to MongoDB Atlas → **Connect** → **Connect your application**
2. Select **Node.js** driver
3. Choose **Standard connection string** instead of **Connection string (SRV)**
4. Copy the new connection string
5. Update your `.env` file with the new `MONGODB_URI`

### Solution 4: Check Network/Firewall

1. **Check if you can reach MongoDB:**
   ```powershell
   Test-NetConnection -ComputerName cluster0.rixikvd.mongodb.net -Port 27017
   ```

2. **Check if DNS resolution works:**
   ```powershell
   nslookup _mongodb._tcp.cluster0.rixikvd.mongodb.net
   ```

3. **Check Windows Firewall:**
   ```powershell
   Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*MongoDB*"}
   ```

## After Applying Fix

1. **Restart your computer** (if you changed DNS)
2. **Restart the backend server:**
   ```powershell
   cd backend
   npm run dev
   ```

3. **Expected output:**
   ```
   ✅ MongoDB Connected: cluster0.rixikvd.mongodb.net
   🚀 Server running on port 3000
   ```

## Quick Test Commands

```powershell
# Get your public IP
(Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing).Content

# Test DNS resolution
nslookup _mongodb._tcp.cluster0.rixikvd.mongodb.net

# Check current DNS servers
Get-DnsClientServerAddress

# Test MongoDB connectivity
Test-NetConnection -ComputerName cluster0.rixikvd.mongodb.net -Port 27017
```

## Still Having Issues?

1. **Check MongoDB Atlas Status:** https://status.mongodb.com/
2. **Verify connection string format** in `.env` file
3. **Check MongoDB Atlas cluster status** - make sure it's running
4. **Try connecting from a different network** to isolate network issues
5. **Contact your network administrator** if you're on a corporate network with restrictions


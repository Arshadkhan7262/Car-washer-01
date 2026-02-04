# Troubleshooting Backend Connection Issues

## Problem: "Cannot connect to server" or "No route to host"

This error means your Flutter app cannot reach the backend server. Follow these steps to fix it:

## Step 1: Verify Backend Server is Running

1. **Open PowerShell** and navigate to backend folder:
   ```powershell
   cd D:\Car-washer-01\backend
   ```

2. **Start the backend server:**
   ```powershell
   node server.js
   ```

3. **Look for this success message:**
   ```
   🚀 Server running on port 3000
   🌐 Network API URL: http://192.168.18.X:3000/api/v1
   ```
   **Note the IP address shown here!**

4. **Keep the PowerShell window open** - server must stay running!

## Step 2: Find Your Computer's Current IP Address

Your IP address may have changed. Find the correct one:

### Method 1: From Backend Server Output
When you start the backend, it shows your IP:
```
🌐 Network API URL: http://192.168.18.X:3000/api/v1
```
Use this IP address!

### Method 2: Using PowerShell
```powershell
# Get your IP address
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
    $_.InterfaceAlias -like "*Wi-Fi*" -or 
    $_.InterfaceAlias -like "*Ethernet*" 
} | Select-Object IPAddress, InterfaceAlias
```

### Method 3: Using Command Prompt
```cmd
ipconfig
```
Look for "IPv4 Address" under your active network adapter (Wi-Fi or Ethernet).

## Step 3: Update .env File

1. **Open** `wash_away/.env` file

2. **Update** the `API_BASE_URL` with your current IP:
   ```env
   API_BASE_URL=http://YOUR_CURRENT_IP:3000/api/v1
   ```
   
   **Example:**
   ```env
   API_BASE_URL=http://192.168.18.7:3000/api/v1
   ```

3. **Save** the file

4. **Restart** your Flutter app (hot restart won't reload .env)

## Step 4: Test Connection

1. **Open browser** on your phone/emulator
2. **Visit:** `http://YOUR_IP:3000/api/v1/health`
3. **Should show:** `{"success":true,"message":"Server is running"}`

If this works, your app should connect too!

## Common Issues & Solutions

### Issue 1: IP Address Changed
**Symptom:** App worked yesterday, not today
**Solution:** Your router assigned a new IP. Update `.env` with new IP.

### Issue 2: Backend Not Running
**Symptom:** "No route to host" error
**Solution:** Start backend server first, then run app.

### Issue 3: Wrong Network
**Symptom:** Phone and computer on different networks
**Solution:** 
- Connect phone and computer to same Wi-Fi network
- Or use USB debugging with port forwarding

### Issue 4: Firewall Blocking
**Symptom:** Connection works in browser but not in app
**Solution:**
```powershell
# Allow Node.js through Windows Firewall
New-NetFirewallRule -DisplayName "Node.js Backend" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
```

### Issue 5: Using Android Emulator
**Symptom:** Physical device works but emulator doesn't
**Solution:** For Android Emulator, use:
```env
API_BASE_URL=http://10.0.2.2:3000/api/v1
```

## Quick Fix Script

Run this PowerShell script to automatically find and update your IP:

```powershell
# Get current IP
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
    ($_.InterfaceAlias -like "*Wi-Fi*" -or $_.InterfaceAlias -like "*Ethernet*") -and 
    $_.IPAddress -notlike "169.254.*" 
} | Select-Object -First 1).IPAddress

Write-Host "Found IP: $ip"
Write-Host "Updating .env file..."

# Update .env file
$envFile = "wash_away\.env"
$content = Get-Content $envFile
$newContent = $content | ForEach-Object {
    if ($_ -match "^API_BASE_URL=") {
        "API_BASE_URL=http://$ip:3000/api/v1"
    } else {
        $_
    }
}
$newContent | Set-Content $envFile

Write-Host "✅ Updated API_BASE_URL to: http://$ip:3000/api/v1"
Write-Host "Please restart your Flutter app!"
```

## Verification Checklist

- [ ] Backend server is running (`node server.js` in backend folder)
- [ ] Backend shows: `🚀 Server running on port 3000`
- [ ] Backend shows network IP (e.g., `http://192.168.18.X:3000/api/v1`)
- [ ] `.env` file has correct IP address
- [ ] Phone/emulator and computer are on same network
- [ ] Can access `http://YOUR_IP:3000/api/v1/health` in browser
- [ ] Flutter app restarted after changing `.env`

## Still Not Working?

1. **Check backend logs** - Are requests reaching the server?
2. **Check phone network** - Is it connected to Wi-Fi?
3. **Try localhost** - If using emulator, use `10.0.2.2`
4. **Check firewall** - Windows Firewall might be blocking
5. **Restart everything** - Backend server, Flutter app, phone

## Need Help?

Check backend logs for connection attempts:
- Backend will show: `📥 [timestamp] POST /api/v1/auth/google/customer`
- If you don't see this, requests aren't reaching backend

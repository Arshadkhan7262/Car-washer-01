# Fix Backend Connection Timeout - Complete Solution

## Problem
Getting "Connection timeout" when trying to connect to backend at `http://10.0.2.2:3000/api/v1` from Android Emulator.

## Root Causes & Solutions

### 1. ✅ Backend Not Running or Not Responding

**Check:**
```powershell
netstat -ano | findstr :3000
```

**Should show:** `TCP    0.0.0.0:3000           0.0.0.0:0              LISTENING`

**Fix:**
```powershell
cd d:\Car-washer-01\backend
npm run dev
```

Wait for: `🚀 Server running on port 3000`

---

### 2. ✅ Wrong API URL in `.env`

**Check your `wash_away/.env`:**
```env
# For Android Emulator:
API_BASE_URL=http://10.0.2.2:3000/api/v1

# For Physical Device (same Wi-Fi as PC):
API_BASE_URL=http://192.168.18.5:3000/api/v1
```

**Current PC IP:** Check with `ipconfig` - look for IPv4 Address under your active network adapter.

**Fix:** Update `.env` with correct URL, then **fully restart** Flutter app (hot reload won't work).

---

### 3. ✅ MongoDB Connection Blocking Requests

**Symptom:** Backend starts but requests timeout (MongoDB not connected).

**Check backend logs** - should see:
- `✅ MongoDB Connected: ...` OR
- `❌ MongoDB connection error: ...`

**Fix:** 
- Ensure MongoDB Atlas IP whitelist includes your IP
- Check MongoDB connection string in `backend/.env`
- Backend will now return 503 immediately if MongoDB isn't connected (instead of timing out)

---

### 4. ✅ Windows Firewall Blocking Connection

**Symptom:** Backend running but emulator can't connect.

**Fix:**
1. Open Windows Defender Firewall
2. Click "Allow an app through firewall"
3. Find "Node.js" or add `node.exe` manually
4. Check both "Private" and "Public" networks
5. Or temporarily disable firewall to test

**Quick test:**
```powershell
# Allow Node through firewall (run as Administrator)
netsh advfirewall firewall add rule name="Node.js Server" dir=in action=allow protocol=TCP localport=3000
```

---

### 5. ✅ Android Emulator Network Issues

**Symptom:** `10.0.2.2` not working.

**Test connectivity from emulator:**
```bash
# In Android Studio Terminal or ADB shell
adb shell
ping 10.0.0.2  # Should work if emulator network is OK
```

**Alternative:** Use your PC's actual IP instead of `10.0.2.2`:
```env
API_BASE_URL=http://192.168.18.5:3000/api/v1
```

**Note:** For physical IP, ensure:
- Phone and PC are on **same Wi-Fi network**
- PC IP hasn't changed (check with `ipconfig`)

---

### 6. ✅ Backend Process Stuck/Crashed

**Symptom:** Port 3000 shows LISTENING but requests don't respond.

**Fix:**
```powershell
# Kill all Node processes
taskkill /F /IM node.exe

# Restart backend
cd d:\Car-washer-01\backend
npm run dev
```

---

## Quick Diagnostic Steps

### Step 1: Verify Backend is Running
```powershell
netstat -ano | findstr :3000
```
Should show: `LISTENING` on `0.0.0.0:3000`

### Step 2: Test Backend Locally
```powershell
Invoke-WebRequest -Uri "http://localhost:3000/api/v1/health" -UseBasicParsing
```
Should return: `StatusCode: 200`

### Step 3: Check `.env` File
```powershell
cd d:\Car-washer-01\wash_away
Get-Content .env | Select-String "API_BASE_URL"
```
Should show correct URL for your setup.

### Step 4: Test from Emulator
- Open browser in emulator
- Go to: `http://10.0.2.2:3000/api/v1/health`
- Should show JSON response

---

## Complete Fix Checklist

- [ ] Backend is running (`npm run dev` in `backend` folder)
- [ ] Backend shows `Server running on port 3000` in terminal
- [ ] MongoDB is connected (check backend logs)
- [ ] `wash_away/.env` has correct `API_BASE_URL`:
  - Android Emulator: `http://10.0.2.2:3000/api/v1`
  - Physical Device: `http://YOUR_PC_IP:3000/api/v1`
- [ ] Flutter app was **fully restarted** after changing `.env`
- [ ] Windows Firewall allows Node.js on port 3000
- [ ] (Physical device) Phone and PC are on same Wi-Fi

---

## Still Not Working?

1. **Check backend terminal** for any error messages
2. **Check Flutter console** for detailed error logs
3. **Try using physical device IP** instead of `10.0.2.2`:
   ```env
   API_BASE_URL=http://192.168.18.5:3000/api/v1
   ```
4. **Restart everything:**
   - Stop backend (Ctrl+C)
   - Kill all Node processes: `taskkill /F /IM node.exe`
   - Restart backend: `npm run dev`
   - Fully restart Flutter app

---

## Backend Code Fix Applied

Added MongoDB connection check in `googleAuthFirebase.service.js`:
- Now returns 503 immediately if MongoDB isn't connected
- Prevents 60-second timeout
- Provides clear error message

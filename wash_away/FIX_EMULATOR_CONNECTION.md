# Fix Android Emulator Connection to Backend

## Problem
Android Emulator can't connect to backend at `http://10.0.2.2:3000/api/v1` - connection timeout.

## Solution 1: Allow Node.js Through Windows Firewall (Recommended)

**Run PowerShell as Administrator** and execute:

```powershell
netsh advfirewall firewall add rule name="Node.js Server Port 3000" dir=in action=allow protocol=TCP localport=3000
```

**Or manually:**
1. Open Windows Defender Firewall
2. Click "Advanced settings"
3. Click "Inbound Rules" → "New Rule"
4. Select "Port" → Next
5. Select "TCP" and enter port `3000` → Next
6. Select "Allow the connection" → Next
7. Check all profiles (Domain, Private, Public) → Next
8. Name it "Node.js Server Port 3000" → Finish

**Then restart your Flutter app.**

---

## Solution 2: Use Your PC's IP Address Instead

If `10.0.2.2` doesn't work, try using your PC's actual IP:

**Step 1:** Find your PC IP:
```powershell
ipconfig | findstr /i "IPv4"
```

**Step 2:** Update `wash_away/.env`:
```env
API_BASE_URL=http://192.168.18.5:3000/api/v1
```
(Replace `192.168.18.5` with your actual IP)

**Step 3:** Fully restart Flutter app (stop and run again)

**Note:** This works if your emulator can reach your local network. Some emulators are isolated and can only use `10.0.2.2`.

---

## Solution 3: Check Emulator Network Settings

**In Android Studio:**
1. Open AVD Manager
2. Click the pencil icon (Edit) on your emulator
3. Click "Show Advanced Settings"
4. Under "Network", ensure:
   - "Network: NAT" is selected
   - Or try "Network: Bridged" if NAT doesn't work

---

## Solution 4: Test Connection from Emulator

**Open browser in Android emulator:**
1. Launch your emulator
2. Open Chrome browser
3. Go to: `http://10.0.2.2:3000/api/v1/health`
4. If you see JSON → Connection works!
5. If timeout → Try Solution 1 (Firewall) or Solution 2 (PC IP)

---

## Solution 5: Restart Everything

Sometimes a clean restart fixes network issues:

```powershell
# 1. Stop backend (Ctrl+C in backend terminal)

# 2. Kill all Node processes
taskkill /F /IM node.exe

# 3. Restart backend
cd d:\Car-washer-01\backend
npm run dev

# 4. Wait for "Server running on port 3000"

# 5. Fully restart Flutter app
```

---

## Quick Diagnostic

**Test 1: Backend accessible locally?**
```powershell
Invoke-WebRequest -Uri "http://localhost:3000/api/v1/health" -UseBasicParsing
```
Should return: `StatusCode: 200`

**Test 2: Port 3000 listening?**
```powershell
netstat -ano | findstr :3000
```
Should show: `TCP    0.0.0.0:3000           0.0.0.0:0              LISTENING`

**Test 3: Firewall blocking?**
- Try Solution 1 (add firewall rule)
- Or temporarily disable firewall to test

---

## Most Likely Fix

**90% of the time, it's Windows Firewall.** 

Run this **as Administrator**:
```powershell
netsh advfirewall firewall add rule name="Node.js Server Port 3000" dir=in action=allow protocol=TCP localport=3000
```

Then restart your Flutter app.

# Quick Fix: Allow Backend Through Windows Firewall

## The Problem
Backend is running but Android Emulator can't connect to `http://10.0.2.2:3000/api/v1` - Windows Firewall is blocking it.

## Solution: Add Firewall Rule

### Method 1: PowerShell (Fastest)

**Right-click PowerShell → Run as Administrator**, then run:

```powershell
netsh advfirewall firewall add rule name="Node.js Server Port 3000" dir=in action=allow protocol=TCP localport=3000
```

**Then restart your Flutter app.**

---

### Method 2: Windows Firewall GUI

1. Press `Win + R`, type `wf.msc`, press Enter
2. Click **"Inbound Rules"** in the left panel
3. Click **"New Rule..."** in the right panel
4. Select **"Port"** → Next
5. Select **"TCP"** and enter port **`3000`** → Next
6. Select **"Allow the connection"** → Next
7. Check all three: **Domain**, **Private**, **Public** → Next
8. Name it: **"Node.js Server Port 3000"** → Finish

**Then restart your Flutter app.**

---

## Alternative: Use Your PC's IP Instead

If firewall fix doesn't work, use your PC's actual IP:

**Step 1:** Find your IP:
```powershell
ipconfig | findstr /i "IPv4"
```

**Step 2:** Update `wash_away/.env`:
```env
API_BASE_URL=http://192.168.18.5:3000/api/v1
```
(Replace with your actual IP)

**Step 3:** Fully restart Flutter app

---

## Verify It Works

After adding firewall rule:

1. **Restart Flutter app completely** (stop and run again)
2. Try Google Sign-In
3. Should connect successfully!

---

## Why This Happens

- Android Emulator uses `10.0.2.2` to reach your PC's localhost
- Windows Firewall blocks incoming connections by default
- Adding a rule allows the emulator to connect to port 3000

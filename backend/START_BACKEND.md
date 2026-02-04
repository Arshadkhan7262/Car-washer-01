# How to Start the Backend Server

## Quick Start

1. **Open PowerShell** (as Administrator recommended)

2. **Navigate to backend folder:**
   ```powershell
   cd D:\Car-washer-01\backend
   ```

3. **Start the server:**
   ```powershell
   node server.js
   ```

4. **Look for this success message:**
   ```
   🚀 Server running on port 3000
   🌐 Network API URL: http://192.168.18.5:3000/api/v1
   ```

5. **Keep this terminal window open** - the server must stay running!

## Troubleshooting

### If server doesn't start:

**Check for errors in the console:**
- MongoDB connection errors are OK - server will still start
- Look for any red error messages
- Common issues:
  - Port 3000 already in use → Kill existing Node processes: `taskkill /F /IM node.exe`
  - Missing dependencies → Run: `npm install`
  - .env file missing → Copy from .env.example

### Verify server is running:

**Test in browser:**
Open: `http://192.168.18.5:3000/api/v1/health`

Should show: `{"success":true,"message":"Server is running"}`

**Check port:**
```powershell
netstat -ano | findstr :3000
```
Should show: `TCP    0.0.0.0:3000    0.0.0.0:0    LISTENING`

## Important Notes

- ✅ Server must be running BEFORE you try Google Sign-In in the app
- ✅ Keep the PowerShell window open while testing
- ✅ If you see "Connection timeout" in the app, the server is not running
- ✅ The server binds to `0.0.0.0` so it's accessible on your network IP (192.168.18.5)

## Google Sign-In Flow

1. User clicks "Continue with Google" in Flutter app
2. Firebase authenticates with Google ✅ (This works)
3. App gets Firebase ID token ✅ (This works)
4. App sends token to: `http://192.168.18.5:3000/api/v1/auth/google/customer` ❌ (Fails if server not running)
5. Backend validates token and creates/updates user
6. Backend returns JWT token to app
7. App saves token and navigates to dashboard

**The error happens at step 4** - the backend server must be running!

# Backend connection – fix "Connection lost" / login errors

If you see **"Backend authentication failed"** or **"Connection lost. The backend server may have stopped or restarted"** when logging in:

## 1. Start the backend

From the project root:

```powershell
cd backend
npm run dev
```

Wait until you see: `🚀 Server running on port 3000` and (if possible) `MongoDB connected`.

## 2. Set the correct API URL in the app

Edit **`wash_away/.env`** and set `API_BASE_URL` for how you run the app:

| How you run the app | API_BASE_URL in wash_away/.env |
|---------------------|--------------------------------|
| **Android Emulator** | `http://10.0.2.2:3000/api/v1` |
| **Physical phone** (same Wi‑Fi as PC) | `http://YOUR_PC_IP:3000/api/v1` (e.g. `http://192.168.18.7:3000/api/v1`) |
| **iOS Simulator** | `http://localhost:3000/api/v1` |

- **Android Emulator** must use `10.0.2.2` (that’s the host machine from the emulator).
- **Physical device**: PC and phone must be on the **same Wi‑Fi**. Find your PC IP (e.g. run `ipconfig` on Windows) and use that in `API_BASE_URL`.

Example **`wash_away/.env`** for Android Emulator:

```env
API_BASE_URL=http://10.0.2.2:3000/api/v1
```

## 3. Restart the app

After changing `.env`, do a **full restart** of the Flutter app (stop and run again). Hot reload may not pick up `.env` changes.

## 4. Check firewall

If the backend is running and the URL is correct but you still get "Connection lost":

- Allow **Node** or **node.exe** through Windows Firewall for private networks.
- Or temporarily disable the firewall to confirm it’s the cause.

## Quick checklist

- [ ] Backend is running (`npm run dev` in `backend` folder).
- [ ] `wash_away/.env` has `API_BASE_URL` set correctly for Emulator vs physical device.
- [ ] App was fully restarted after editing `.env`.
- [ ] (Physical device) Phone and PC are on the same Wi‑Fi.

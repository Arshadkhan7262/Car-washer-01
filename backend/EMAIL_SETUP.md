# Email Service Setup Guide

## Overview
The backend uses **Nodemailer** to send OTP emails for washer authentication. SMTP configuration is required in the `.env` file.

## Required Environment Variables

Add these to your `backend/.env` file:

```env
# SMTP Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
```

## Gmail Setup (Recommended)

### Step 1: Enable 2-Factor Authentication
1. Go to your Google Account settings
2. Enable 2-Step Verification

### Step 2: Generate App Password
1. Go to: https://myaccount.google.com/apppasswords
2. Select "Mail" and "Other (Custom name)"
3. Enter "Car Wash Pro Backend"
4. Copy the generated 16-character password

### Step 3: Update .env File
```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=xxxx xxxx xxxx xxxx  # Use the app password (remove spaces)
```

## Other Email Providers

### Outlook/Hotmail
```env
SMTP_HOST=smtp-mail.outlook.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-email@outlook.com
SMTP_PASSWORD=your-password
```

### Yahoo Mail
```env
SMTP_HOST=smtp.mail.yahoo.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-email@yahoo.com
SMTP_PASSWORD=your-app-password
```

### Custom SMTP Server
```env
SMTP_HOST=your-smtp-server.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-email@domain.com
SMTP_PASSWORD=your-password
```

## Testing Email Configuration

After adding SMTP configuration, restart the backend server. You should see:

```
✅ SMTP server is ready to send emails
```

If you see an error, check:
1. SMTP credentials are correct
2. App password is used (for Gmail)
3. Port 587 is not blocked by firewall
4. 2FA is enabled (for Gmail)

## Development Mode

In development mode (`NODE_ENV=development`), if email sending fails, the OTP will still be:
- Saved to the database
- Logged to console
- Returned in API response (for testing)

## Production Mode

In production mode, if email sending fails:
- OTP is still saved
- Error is logged
- User can request OTP again
- OTP is NOT returned in API response (for security)

## Troubleshooting

### Email Not Sending
1. Check server logs for SMTP errors
2. Verify SMTP credentials in `.env`
3. Test SMTP connection manually
4. Check firewall/network settings
5. For Gmail: Ensure app password is used (not regular password)

### Common Errors

**Error: Invalid login**
- Wrong SMTP_USER or SMTP_PASSWORD
- For Gmail: Must use App Password, not regular password

**Error: Connection timeout**
- SMTP_PORT might be blocked
- Try port 465 with SMTP_SECURE=true

**Error: Authentication failed**
- 2FA not enabled (for Gmail)
- App password not generated correctly




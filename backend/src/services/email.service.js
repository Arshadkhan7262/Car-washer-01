import nodemailer from 'nodemailer';
import dotenv from 'dotenv';

dotenv.config();

/**
 * Email Service
 * Handles sending emails via SMTP
 */
class EmailService {
  constructor() {
    this.transporter = null;
    this.initializeTransporter();
  }

  /**
   * Initialize SMTP transporter
   */
  initializeTransporter() {
    try {
      // Check if SMTP credentials are configured
      if (!process.env.SMTP_USER || !process.env.SMTP_PASSWORD) {
        console.warn('⚠️ SMTP credentials not configured. Email service will be disabled.');
        console.warn('   Set SMTP_USER and SMTP_PASSWORD in .env to enable email sending.');
        this.transporter = null;
        return;
      }

      // SMTP Configuration from environment variables
      this.transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST || 'smtp.gmail.com',
        port: parseInt(process.env.SMTP_PORT || '587'),
        secure: process.env.SMTP_SECURE === 'true', // true for 465, false for other ports
        auth: {
          user: process.env.SMTP_USER,
          pass: process.env.SMTP_PASSWORD,
        },
        // Add connection timeout
        connectionTimeout: 5000, // 5 seconds
        greetingTimeout: 5000, // 5 seconds
        socketTimeout: 10000, // 10 seconds
      });

      // Verify connection asynchronously (don't block)
      this.transporter.verify((error, success) => {
        if (error) {
          console.error('❌ SMTP connection error:', error.message);
          console.warn('⚠️ Email service will continue but emails may fail to send.');
        } else {
          console.log('✅ SMTP server is ready to send emails');
        }
      });
    } catch (error) {
      console.error('❌ Failed to initialize email service:', error.message);
      this.transporter = null;
    }
  }

  /**
   * Generate HTML email template for OTP (Customer App - Wash Away)
   */
  generateOTPEmailTemplate(otp, userName = 'User', role = 'customer') {
    if (role === 'washer') {
      return this.generateWasherOTPEmailTemplate(otp, userName);
    }
    // Default to customer template
    return this.generateCustomerOTPEmailTemplate(otp, userName);
  }

  /**
   * Generate HTML email template for OTP (Customer App - Wash Away)
   */
  generateCustomerOTPEmailTemplate(otp, userName = 'User') {
    return `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Email Verification - Wash Away</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            line-height: 1.6;
            color: #1A1A1A;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
        }
        .email-wrapper {
            max-width: 600px;
            margin: 0 auto;
            background-color: #ffffff;
            border-radius: 16px;
            overflow: hidden;
            box-shadow: 0 10px 40px rgba(0,0,0,0.1);
        }
        .header {
            background: linear-gradient(135deg, #8DA2FF 0%, #6B7FD7 100%);
            padding: 40px 30px;
            text-align: center;
            color: #ffffff;
        }
        .logo {
            font-size: 32px;
            font-weight: 700;
            margin-bottom: 10px;
            letter-spacing: -0.5px;
        }
        .header-subtitle {
            font-size: 16px;
            opacity: 0.95;
            font-weight: 400;
        }
        .content {
            padding: 40px 30px;
        }
        .greeting {
            font-size: 18px;
            color: #1A1A1A;
            margin-bottom: 20px;
            font-weight: 600;
        }
        .message {
            font-size: 15px;
            color: #666666;
            margin-bottom: 30px;
            line-height: 1.8;
        }
        .otp-container {
            background: linear-gradient(135deg, #F8F9FB 0%, #E8EBF0 100%);
            border: 2px solid #8DA2FF;
            border-radius: 12px;
            padding: 30px;
            text-align: center;
            margin: 30px 0;
            box-shadow: 0 4px 12px rgba(141, 162, 255, 0.15);
        }
        .otp-label {
            font-size: 14px;
            color: #666666;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 15px;
            font-weight: 600;
        }
        .otp-code {
            font-size: 42px;
            font-weight: 700;
            color: #8DA2FF;
            letter-spacing: 12px;
            font-family: 'Courier New', 'Monaco', monospace;
            text-align: center;
            padding: 10px;
            background: #ffffff;
            border-radius: 8px;
            display: inline-block;
            min-width: 200px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.05);
        }
        .info-box {
            background-color: #FFF9E6;
            border-left: 4px solid #FBC02D;
            padding: 20px;
            margin: 30px 0;
            border-radius: 8px;
        }
        .info-title {
            font-size: 15px;
            font-weight: 600;
            color: #856404;
            margin-bottom: 12px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .info-list {
            list-style: none;
            padding: 0;
            margin: 0;
        }
        .info-list li {
            font-size: 14px;
            color: #856404;
            margin-bottom: 8px;
            padding-left: 24px;
            position: relative;
            line-height: 1.6;
        }
        .info-list li:before {
            content: "•";
            position: absolute;
            left: 8px;
            font-weight: bold;
            color: #FBC02D;
        }
        .info-list li:last-child {
            margin-bottom: 0;
        }
        .cta-button {
            display: inline-block;
            background: linear-gradient(135deg, #8DA2FF 0%, #6B7FD7 100%);
            color: #ffffff;
            padding: 14px 32px;
            border-radius: 8px;
            text-decoration: none;
            font-weight: 600;
            font-size: 15px;
            margin: 20px 0;
            box-shadow: 0 4px 12px rgba(141, 162, 255, 0.3);
            transition: transform 0.2s;
        }
        .footer {
            background-color: #F8F9FB;
            padding: 30px;
            text-align: center;
            border-top: 1px solid #E8EBF0;
        }
        .footer-text {
            font-size: 13px;
            color: #999999;
            margin-bottom: 8px;
        }
        .footer-link {
            color: #8DA2FF;
            text-decoration: none;
        }
        .divider {
            height: 1px;
            background: linear-gradient(to right, transparent, #E8EBF0, transparent);
            margin: 30px 0;
        }
        @media only screen and (max-width: 600px) {
            .content {
                padding: 30px 20px;
            }
            .header {
                padding: 30px 20px;
            }
            .otp-code {
                font-size: 36px;
                letter-spacing: 8px;
            }
        }
    </style>
</head>
<body>
    <div class="email-wrapper">
        <div class="header">
            <div class="logo">🚿 Wash Away</div>
            <div class="header-subtitle">Email Verification Code</div>
        </div>
        
        <div class="content">
            <div class="greeting">Hello ${userName}!</div>
            
            <p class="message">
                Thank you for signing up with Wash Away! To complete your registration and secure your account, please verify your email address using the verification code below.
            </p>
            
            <div class="otp-container">
                <div class="otp-label">Your Verification Code</div>
                <div class="otp-code">${otp}</div>
            </div>
            
            <div class="info-box">
                <div class="info-title">
                    ⚠️ Important Security Information
                </div>
                <ul class="info-list">
                    <li>This code is valid for <strong>5 minutes</strong> only</li>
                    <li>Never share this code with anyone</li>
                    <li>Wash Away staff will never ask for your verification code</li>
                    <li>If you didn't request this code, please ignore this email</li>
                </ul>
            </div>
            
            <div class="divider"></div>
            
            <p class="message" style="font-size: 14px; color: #999999; text-align: center;">
                Enter this code in the Wash Away app to verify your email and start using our services.
            </p>
        </div>
        
        <div class="footer">
            <p class="footer-text">
                © ${new Date().getFullYear()} Wash Away. All rights reserved.
            </p>
            <p class="footer-text">
                This is an automated email. Please do not reply to this message.
            </p>
            <p class="footer-text" style="margin-top: 12px;">
                Need help? <a href="mailto:support@washaway.com" class="footer-link">Contact Support</a>
            </p>
        </div>
    </div>
</body>
</html>
    `;
  }

  /**
   * Generate HTML email template for OTP (Washer App - Car Washer Pro)
   */
  generateWasherOTPEmailTemplate(otp, userName = 'User') {
    return `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Email Verification - Car Washer Pro</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            line-height: 1.6;
            color: #1A1A1A;
            background: linear-gradient(135deg, #0A2540 0%, #1a3a5a 100%);
            padding: 20px;
        }
        .email-wrapper {
            max-width: 600px;
            margin: 0 auto;
            background-color: #ffffff;
            border-radius: 16px;
            overflow: hidden;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
        }
        .header {
            background: linear-gradient(135deg, #0A2540 0%, #1a3a5a 100%);
            padding: 40px 30px;
            text-align: center;
            color: #ffffff;
        }
        .logo {
            font-size: 32px;
            font-weight: 700;
            margin-bottom: 10px;
            letter-spacing: 1px;
        }
        .header-subtitle {
            font-size: 16px;
            opacity: 0.9;
            font-weight: 400;
        }
        .content {
            padding: 40px 30px;
            background-color: #ffffff;
        }
        .greeting {
            font-size: 24px;
            font-weight: 600;
            color: #0A2540;
            margin-bottom: 20px;
        }
        .message {
            font-size: 16px;
            color: #4A5568;
            margin-bottom: 30px;
            line-height: 1.8;
        }
        .otp-container {
            text-align: center;
            margin: 40px 0;
            padding: 30px;
            background: linear-gradient(135deg, #F7FAFC 0%, #EDF2F7 100%);
            border-radius: 12px;
            border: 2px dashed #0A2540;
        }
        .otp-label {
            font-size: 14px;
            color: #718096;
            text-transform: uppercase;
            letter-spacing: 2px;
            margin-bottom: 15px;
            font-weight: 600;
        }
        .otp-code {
            font-size: 48px;
            font-weight: 700;
            color: #0A2540;
            letter-spacing: 12px;
            font-family: 'Courier New', 'Monaco', monospace;
            text-align: center;
        }
        .info-box {
            background-color: #FFF9E6;
            border-left: 4px solid #FBC02D;
            padding: 20px;
            margin: 30px 0;
            border-radius: 8px;
        }
        .info-title {
            font-size: 16px;
            font-weight: 600;
            color: #856404;
            margin-bottom: 12px;
        }
        .info-list {
            list-style: none;
            padding: 0;
            margin: 0;
        }
        .info-list li {
            font-size: 14px;
            color: #856404;
            margin-bottom: 8px;
            padding-left: 24px;
            position: relative;
            line-height: 1.6;
        }
        .info-list li:before {
            content: '•';
            color: #FBC02D;
            position: absolute;
            left: 0;
            font-size: 18px;
            line-height: 1;
        }
        .footer {
            background-color: #0A2540;
            padding: 30px;
            text-align: center;
            color: #ffffff;
        }
        .footer-text {
            font-size: 13px;
            color: rgba(255, 255, 255, 0.8);
            margin-bottom: 8px;
        }
        .footer-link {
            color: #6CB6FF;
            text-decoration: none;
        }
        .divider {
            height: 1px;
            background: linear-gradient(to right, transparent, #E8EBF0, transparent);
            margin: 30px 0;
        }
        @media only screen and (max-width: 600px) {
            .content {
                padding: 30px 20px;
            }
            .header {
                padding: 30px 20px;
            }
            .otp-code {
                font-size: 36px;
                letter-spacing: 8px;
            }
        }
    </style>
</head>
<body>
    <div class="email-wrapper">
        <div class="header">
            <div class="logo">🚗 Car Washer Pro</div>
            <div class="header-subtitle">Email Verification Code</div>
        </div>
        
        <div class="content">
            <div class="greeting">Hello ${userName}!</div>
            
            <p class="message">
                Thank you for registering as a Car Washer! To complete your registration and activate your account, please verify your email address using the verification code below.
            </p>
            
            <div class="otp-container">
                <div class="otp-label">Your Verification Code</div>
                <div class="otp-code">${otp}</div>
            </div>
            
            <div class="info-box">
                <div class="info-title">
                    ⚠️ Important Security Information
                </div>
                <ul class="info-list">
                    <li>This code is valid for <strong>5 minutes</strong> only</li>
                    <li>Never share this code with anyone</li>
                    <li>Car Washer Pro staff will never ask for your verification code</li>
                    <li>If you didn't request this code, please ignore this email</li>
                </ul>
            </div>
            
            <div class="divider"></div>
            
            <p class="message" style="font-size: 14px; color: #999999; text-align: center;">
                Enter this code in the Car Washer Pro app to verify your email. After verification, your account will be pending admin approval.
            </p>
        </div>
        
        <div class="footer">
            <p class="footer-text">
                © ${new Date().getFullYear()} Car Washer Pro. All rights reserved.
            </p>
            <p class="footer-text">
                This is an automated email. Please do not reply to this message.
            </p>
            <p class="footer-text" style="margin-top: 12px;">
                Need help? <a href="mailto:support@carwasherpro.com" class="footer-link">Contact Support</a>
            </p>
        </div>
    </div>
</body>
</html>
    `;
  }

  /**
   * Generate HTML email template for password reset
   */
  generatePasswordResetEmailTemplate(resetCode, userName = 'User', role = 'customer') {
    if (role === 'washer') {
      return this.generateWasherPasswordResetEmailTemplate(resetCode, userName);
    }
    // Default to customer template
    return this.generateCustomerPasswordResetEmailTemplate(resetCode, userName);
  }

  /**
   * Generate HTML email template for password reset (Customer App - Wash Away)
   */
  generateCustomerPasswordResetEmailTemplate(resetCode, userName = 'User') {
    return `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Password Reset - Wash Away</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            line-height: 1.6;
            color: #1A1A1A;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
        }
        .email-wrapper {
            max-width: 600px;
            margin: 0 auto;
            background-color: #ffffff;
            border-radius: 16px;
            overflow: hidden;
            box-shadow: 0 10px 40px rgba(0,0,0,0.1);
        }
        .header {
            background: linear-gradient(135deg, #8DA2FF 0%, #6B7FD7 100%);
            padding: 40px 30px;
            text-align: center;
            color: #ffffff;
        }
        .logo {
            font-size: 32px;
            font-weight: 700;
            margin-bottom: 10px;
            letter-spacing: -0.5px;
        }
        .header-subtitle {
            font-size: 16px;
            opacity: 0.95;
            font-weight: 400;
        }
        .content {
            padding: 40px 30px;
        }
        .greeting {
            font-size: 18px;
            color: #1A1A1A;
            margin-bottom: 20px;
            font-weight: 600;
        }
        .message {
            font-size: 15px;
            color: #666666;
            margin-bottom: 30px;
            line-height: 1.8;
        }
        .reset-code-container {
            background: linear-gradient(135deg, #F8F9FB 0%, #E8EBF0 100%);
            border: 2px solid #8DA2FF;
            border-radius: 12px;
            padding: 30px;
            text-align: center;
            margin: 30px 0;
            box-shadow: 0 4px 12px rgba(141, 162, 255, 0.15);
        }
        .reset-code-label {
            font-size: 14px;
            color: #666666;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 15px;
            font-weight: 600;
        }
        .reset-code {
            font-size: 42px;
            font-weight: 700;
            color: #8DA2FF;
            letter-spacing: 12px;
            font-family: 'Courier New', 'Monaco', monospace;
            text-align: center;
            padding: 10px;
            background: #ffffff;
            border-radius: 8px;
            display: inline-block;
            min-width: 200px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.05);
        }
        .info-box {
            background-color: #FFF9E6;
            border-left: 4px solid #FBC02D;
            padding: 20px;
            margin: 30px 0;
            border-radius: 8px;
        }
        .info-title {
            font-size: 15px;
            font-weight: 600;
            color: #856404;
            margin-bottom: 12px;
        }
        .info-list {
            list-style: none;
            padding: 0;
            margin: 0;
        }
        .info-list li {
            font-size: 14px;
            color: #856404;
            margin-bottom: 8px;
            padding-left: 24px;
            position: relative;
            line-height: 1.6;
        }
        .info-list li:before {
            content: "•";
            position: absolute;
            left: 8px;
            font-weight: bold;
            color: #FBC02D;
        }
        .footer {
            background-color: #F8F9FB;
            padding: 30px;
            text-align: center;
            border-top: 1px solid #E8EBF0;
        }
        .footer-text {
            font-size: 13px;
            color: #999999;
            margin-bottom: 8px;
        }
        .footer-link {
            color: #8DA2FF;
            text-decoration: none;
        }
        @media only screen and (max-width: 600px) {
            .content {
                padding: 30px 20px;
            }
            .header {
                padding: 30px 20px;
            }
            .reset-code {
                font-size: 36px;
                letter-spacing: 8px;
            }
        }
    </style>
</head>
<body>
    <div class="email-wrapper">
        <div class="header">
            <div class="logo">🚿 Wash Away</div>
            <div class="header-subtitle">Password Reset Code</div>
        </div>
        
        <div class="content">
            <div class="greeting">Hello ${userName}!</div>
            
            <p class="message">
                You have requested to reset your password for your Wash Away account. Please use the following code to reset your password:
            </p>
            
            <div class="reset-code-container">
                <div class="reset-code-label">Your Reset Code</div>
                <div class="reset-code">${resetCode}</div>
            </div>
            
            <div class="info-box">
                <div class="info-title">
                    ⚠️ Important Security Information
                </div>
                <ul class="info-list">
                    <li>This reset code is valid for <strong>5 minutes</strong> only</li>
                    <li>Never share this code with anyone</li>
                    <li>Wash Away staff will never ask for your reset code</li>
                    <li>If you didn't request a password reset, please ignore this email</li>
                </ul>
            </div>
            
            <p class="message" style="font-size: 14px; color: #999999; text-align: center;">
                Enter this code in the Wash Away app to reset your password.
            </p>
        </div>
        
        <div class="footer">
            <p class="footer-text">
                © ${new Date().getFullYear()} Wash Away. All rights reserved.
            </p>
            <p class="footer-text">
                This is an automated email. Please do not reply to this message.
            </p>
            <p class="footer-text" style="margin-top: 12px;">
                Need help? <a href="mailto:support@washaway.com" class="footer-link">Contact Support</a>
            </p>
        </div>
    </div>
</body>
</html>
    `;
  }

  /**
   * Generate HTML email template for password reset (Washer App - Car Washer Pro)
   */
  generateWasherPasswordResetEmailTemplate(resetCode, userName = 'User') {
    return `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Password Reset - Car Washer Pro</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            line-height: 1.6;
            color: #1A1A1A;
            background: linear-gradient(135deg, #0A2540 0%, #1a3a5a 100%);
            padding: 20px;
        }
        .email-wrapper {
            max-width: 600px;
            margin: 0 auto;
            background-color: #ffffff;
            border-radius: 16px;
            overflow: hidden;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
        }
        .header {
            background: linear-gradient(135deg, #0A2540 0%, #1a3a5a 100%);
            padding: 40px 30px;
            text-align: center;
            color: #ffffff;
        }
        .logo {
            font-size: 32px;
            font-weight: 700;
            margin-bottom: 10px;
            letter-spacing: 1px;
        }
        .header-subtitle {
            font-size: 16px;
            opacity: 0.9;
            font-weight: 400;
        }
        .content {
            padding: 40px 30px;
            background-color: #ffffff;
        }
        .greeting {
            font-size: 24px;
            font-weight: 600;
            color: #0A2540;
            margin-bottom: 20px;
        }
        .message {
            font-size: 16px;
            color: #4A5568;
            margin-bottom: 30px;
            line-height: 1.8;
        }
        .reset-code-container {
            text-align: center;
            margin: 40px 0;
            padding: 30px;
            background: linear-gradient(135deg, #F7FAFC 0%, #EDF2F7 100%);
            border-radius: 12px;
            border: 2px dashed #0A2540;
        }
        .reset-code-label {
            font-size: 14px;
            color: #718096;
            text-transform: uppercase;
            letter-spacing: 2px;
            margin-bottom: 15px;
            font-weight: 600;
        }
        .reset-code {
            font-size: 48px;
            font-weight: 700;
            color: #0A2540;
            letter-spacing: 12px;
            font-family: 'Courier New', 'Monaco', monospace;
            text-align: center;
        }
        .info-box {
            background-color: #FFF9E6;
            border-left: 4px solid #FBC02D;
            padding: 20px;
            margin: 30px 0;
            border-radius: 8px;
        }
        .info-title {
            font-size: 16px;
            font-weight: 600;
            color: #856404;
            margin-bottom: 12px;
        }
        .info-list {
            list-style: none;
            padding: 0;
            margin: 0;
        }
        .info-list li {
            font-size: 14px;
            color: #856404;
            margin-bottom: 8px;
            padding-left: 24px;
            position: relative;
            line-height: 1.6;
        }
        .info-list li:before {
            content: '•';
            color: #FBC02D;
            position: absolute;
            left: 0;
            font-size: 18px;
            line-height: 1;
        }
        .footer {
            background-color: #0A2540;
            padding: 30px;
            text-align: center;
            color: #ffffff;
        }
        .footer-text {
            font-size: 13px;
            color: rgba(255, 255, 255, 0.8);
            margin-bottom: 8px;
        }
        .footer-link {
            color: #6CB6FF;
            text-decoration: none;
        }
        @media only screen and (max-width: 600px) {
            .content {
                padding: 30px 20px;
            }
            .header {
                padding: 30px 20px;
            }
            .reset-code {
                font-size: 36px;
                letter-spacing: 8px;
            }
        }
    </style>
</head>
<body>
    <div class="email-wrapper">
        <div class="header">
            <div class="logo">🚗 Car Washer Pro</div>
            <div class="header-subtitle">Password Reset Code</div>
        </div>
        
        <div class="content">
            <div class="greeting">Hello ${userName}!</div>
            
            <p class="message">
                You have requested to reset your password for your Car Washer Pro account. Please use the following code to reset your password:
            </p>
            
            <div class="reset-code-container">
                <div class="reset-code-label">Your Reset Code</div>
                <div class="reset-code">${resetCode}</div>
            </div>
            
            <div class="info-box">
                <div class="info-title">
                    ⚠️ Important Security Information
                </div>
                <ul class="info-list">
                    <li>This reset code is valid for <strong>5 minutes</strong> only</li>
                    <li>Never share this code with anyone</li>
                    <li>Car Washer Pro staff will never ask for your reset code</li>
                    <li>If you didn't request a password reset, please ignore this email</li>
                </ul>
            </div>
            
            <p class="message" style="font-size: 14px; color: #999999; text-align: center;">
                Enter this code in the Car Washer Pro app to reset your password.
            </p>
        </div>
        
        <div class="footer">
            <p class="footer-text">
                © ${new Date().getFullYear()} Car Washer Pro. All rights reserved.
            </p>
            <p class="footer-text">
                This is an automated email. Please do not reply to this message.
            </p>
            <p class="footer-text" style="margin-top: 12px;">
                Need help? <a href="mailto:support@carwasherpro.com" class="footer-link">Contact Support</a>
            </p>
        </div>
    </div>
</body>
</html>
    `;
  }

  /**
   * Send OTP email
   * @param {string} to - Recipient email address
   * @param {string} otp - OTP code
   * @param {string} userName - User's name (optional)
   * @param {string} role - User role ('customer' or 'washer') - determines email template
   * @returns {Promise<Object>} Send result
   */
  async sendOTPEmail(to, otp, userName = 'User', role = 'customer') {
    try {
      if (!this.transporter) {
        console.warn(`⚠️ Email service not initialized. Skipping email to ${to}. OTP: ${otp}`);
        // Don't throw error - just log and return
        return {
          success: false,
          message: 'Email service not initialized',
        };
      }

      // Check if SMTP credentials are configured
      if (!process.env.SMTP_USER || !process.env.SMTP_PASSWORD) {
        console.warn(`⚠️ SMTP credentials not configured. Skipping email to ${to}. OTP: ${otp}`);
        if (process.env.NODE_ENV === 'development') {
          console.log(`📧 Development mode - OTP for ${to}: ${otp}`);
        }
        return {
          success: false,
          message: 'SMTP not configured',
        };
      }

      // Determine branding based on role
      const appName = role === 'washer' ? 'Car Washer Pro' : 'Wash Away';
      const fromName = role === 'washer' ? 'Car Washer Pro' : 'Wash Away';
      const subject = role === 'washer' 
        ? 'Your Email Verification Code - Car Washer Pro'
        : 'Your Email Verification Code - Wash Away';
      const textMessage = role === 'washer'
        ? `Hello ${userName},\n\nYour email verification code is: ${otp}\n\nThis code is valid for 5 minutes. Please enter it in the Car Washer Pro app to verify your email.\n\nIf you didn't request this code, please ignore this email.\n\n© ${new Date().getFullYear()} Car Washer Pro. All rights reserved.`
        : `Hello ${userName},\n\nYour email verification code is: ${otp}\n\nThis code is valid for 5 minutes. Please enter it in the Wash Away app to verify your email.\n\nIf you didn't request this code, please ignore this email.\n\n© ${new Date().getFullYear()} Wash Away. All rights reserved.`;

      const mailOptions = {
        from: `"${fromName}" <${process.env.SMTP_USER}>`,
        to: to,
        subject: subject,
        html: this.generateOTPEmailTemplate(otp, userName, role),
        text: textMessage,
      };

      // Add timeout to prevent hanging
      const timeoutPromise = new Promise((_, reject) => {
        setTimeout(() => reject(new Error('Email sending timeout after 10 seconds')), 10000);
      });

      const sendPromise = this.transporter.sendMail(mailOptions);
      const info = await Promise.race([sendPromise, timeoutPromise]);
      
      console.log(`✅ OTP email sent to ${to}:`, info.messageId);
      
      return {
        success: true,
        messageId: info.messageId,
      };
    } catch (error) {
      console.error(`❌ Failed to send OTP email to ${to}:`, error.message);
      // Don't throw error - just log it
      // In development, log the OTP
      if (process.env.NODE_ENV === 'development') {
        console.log(`📧 Development mode - OTP for ${to}: ${otp}`);
      }
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Send password reset email
   * @param {string} to - Recipient email address
   * @param {string} resetCode - Reset code
   * @param {string} userName - User's name (optional)
   * @param {string} role - User role ('customer' or 'washer') - determines email template
   * @returns {Promise<Object>} Send result
   */
  async sendPasswordResetEmail(to, resetCode, userName = 'User', role = 'customer') {
    try {
      if (!this.transporter) {
        console.warn(`⚠️ Email service not initialized. Skipping email to ${to}. Reset Code: ${resetCode}`);
        return {
          success: false,
          message: 'Email service not initialized',
        };
      }

      // Check if SMTP credentials are configured
      if (!process.env.SMTP_USER || !process.env.SMTP_PASSWORD) {
        console.warn(`⚠️ SMTP credentials not configured. Skipping email to ${to}. Reset Code: ${resetCode}`);
        if (process.env.NODE_ENV === 'development') {
          console.log(`📧 Development mode - Reset Code for ${to}: ${resetCode}`);
        }
        return {
          success: false,
          message: 'SMTP not configured',
        };
      }

      // Determine branding based on role
      const appName = role === 'washer' ? 'Car Washer Pro' : 'Wash Away';
      const fromName = role === 'washer' ? 'Car Washer Pro' : 'Wash Away';
      const subject = role === 'washer' 
        ? 'Password Reset Code - Car Washer Pro'
        : 'Password Reset Code - Wash Away';
      const textMessage = role === 'washer'
        ? `Hello ${userName},\n\nYour password reset code is: ${resetCode}\n\nThis code is valid for 5 minutes. Please enter it in the Car Washer Pro app to reset your password.\n\nIf you didn't request a password reset, please ignore this email.\n\n© ${new Date().getFullYear()} Car Washer Pro. All rights reserved.`
        : `Hello ${userName},\n\nYour password reset code is: ${resetCode}\n\nThis code is valid for 5 minutes. Please enter it in the Wash Away app to reset your password.\n\nIf you didn't request a password reset, please ignore this email.\n\n© ${new Date().getFullYear()} Wash Away. All rights reserved.`;

      const mailOptions = {
        from: `"${fromName}" <${process.env.SMTP_USER}>`,
        to: to,
        subject: subject,
        html: this.generatePasswordResetEmailTemplate(resetCode, userName, role),
        text: textMessage,
      };

      // Add timeout to prevent hanging
      const timeoutPromise = new Promise((_, reject) => {
        setTimeout(() => reject(new Error('Email sending timeout after 10 seconds')), 10000);
      });

      const sendPromise = this.transporter.sendMail(mailOptions);
      const info = await Promise.race([sendPromise, timeoutPromise]);
      
      console.log(`✅ Password reset email sent to ${to} (${role}):`, info.messageId);
      
      return {
        success: true,
        messageId: info.messageId,
      };
    } catch (error) {
      console.error(`❌ Failed to send password reset email to ${to}:`, error.message);
      // In development, log the reset code
      if (process.env.NODE_ENV === 'development') {
        console.log(`📧 Development mode - Reset Code for ${to}: ${resetCode}`);
      }
      return {
        success: false,
        error: error.message,
      };
    }
  }
}

// Export singleton instance
export default new EmailService();


import nodemailer, { Transporter } from 'nodemailer';
import config from '../config/env';
import logger from '../utils/logger';

class EmailService {
  private transporter: Transporter | null = null;

  constructor() {
    this.initTransporter();
  }

  private initTransporter(): void {
    try {
      this.transporter = nodemailer.createTransport({
        host: config.smtpHost,
        port: config.smtpPort,
        secure: config.smtpSecure,
        auth: {
          user: config.smtpUser,
          pass: config.smtpPass,
        },
      });

      this.transporter.verify((error: Error | null) => {
        if (error) {
          logger.warn(`⚠️ SMTP Connection warning: ${error.message}`);
        } else {
          logger.info(`📧 SMTP Mailer successfully connected to ${config.smtpHost}:${config.smtpPort}`);
        }
      });
    } catch (err: any) {
      logger.error(`❌ Failed to initialize email transporter: ${err.message || err}`);
      this.transporter = null;
    }
  }

  /**
   * Sends a styled password reset email containing a secure temporary password.
   */
  async sendPasswordResetEmail(
    toEmail: string,
    userName: string,
    tempPassword: string
  ): Promise<boolean> {
    if (!this.transporter) {
      this.initTransporter();
    }

    if (!this.transporter) {
      logger.error('❌ Cannot send email: SMTP transporter is not available');
      return false;
    }

    const htmlContent = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f8fafc; margin: 0; padding: 24px; color: #1e293b; }
          .container { max-width: 540px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 25px rgba(0,0,0,0.06); border: 1px solid #e2e8f0; }
          .header { background: linear-gradient(135deg, #2563eb, #1d4ed8); padding: 32px 24px; text-align: center; color: white; }
          .header h1 { margin: 0; font-size: 26px; font-weight: 800; letter-spacing: -0.5px; }
          .header p { margin: 6px 0 0 0; font-size: 14px; opacity: 0.9; }
          .content { padding: 32px 28px; }
          .greeting { font-size: 18px; font-weight: 700; margin-bottom: 12px; color: #0f172a; }
          .info-text { font-size: 14.5px; line-height: 1.6; color: #475569; margin-bottom: 24px; }
          .password-box { background: #f1f5f9; border: 2px dashed #3b82f6; border-radius: 12px; padding: 18px; text-align: center; margin-bottom: 24px; }
          .password-label { font-size: 12px; font-weight: 700; text-transform: uppercase; color: #64748b; letter-spacing: 0.5px; margin-bottom: 6px; }
          .password-value { font-size: 24px; font-weight: 800; color: #1d4ed8; letter-spacing: 2px; font-family: monospace; }
          .steps-box { background: #f8fafc; border-radius: 10px; padding: 16px; margin-bottom: 24px; font-size: 13.5px; color: #334155; }
          .steps-box ol { margin: 0; padding-left: 20px; line-height: 1.7; }
          .footer { background: #f8fafc; padding: 20px; text-align: center; font-size: 12px; color: #94a3b8; border-top: 1px solid #f1f5f9; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Voxora AI Coach</h1>
            <p>Spoken English Mastery Platform</p>
          </div>
          <div class="content">
            <div class="greeting">Hello, ${userName}!</div>
            <div class="info-text">
              We received a request to reset the password for your Voxora account. Use the temporary password below to log in:
            </div>
            <div class="password-box">
              <div class="password-label">Your Temporary Password</div>
              <div class="password-value">${tempPassword}</div>
            </div>
            <div class="steps-box">
              <strong>Next Steps:</strong>
              <ol>
                <li>Open the <strong>Voxora</strong> app on your device.</li>
                <li>Enter your email: <strong>${toEmail}</strong></li>
                <li>Enter the temporary password above and tap <strong>Login</strong>.</li>
              </ol>
            </div>
            <div class="info-text" style="font-size: 13px; color: #64748b; margin-bottom: 0;">
              If you did not request this password reset, please contact our support team immediately.
            </div>
          </div>
          <div class="footer">
            &copy; ${new Date().getFullYear()} Voxora & Kaizen Infinities. All rights reserved.
          </div>
        </div>
      </body>
      </html>
    `;

    try {
      const info = await this.transporter.sendMail({
        from: config.smtpFrom,
        to: toEmail,
        bcc: config.smtpTo !== toEmail ? config.smtpTo : undefined,
        subject: '🔒 Your Voxora Password Reset Instructions',
        text: `Hello ${userName},\n\nYour temporary password for Voxora is: ${tempPassword}\n\nUse this to log into your account via the app.\n\nBest regards,\nVoxora Team`,
        html: htmlContent,
      });

      logger.info(`✅ Password reset email successfully dispatched to ${toEmail} (Message ID: ${info.messageId})`);
      return true;
    } catch (err: any) {
      logger.error(`❌ Failed to send password reset email to ${toEmail}: ${err.message || err}`);
      return false;
    }
  }

  /**
   * Sends a styled verification email containing a 6-digit OTP code for password reset.
   */
  async sendPasswordResetOtpEmail(
    toEmail: string,
    userName: string,
    otp: string
  ): Promise<boolean> {
    if (!this.transporter) {
      this.initTransporter();
    }

    if (!this.transporter) {
      logger.error('❌ Cannot send email: SMTP transporter is not available');
      return false;
    }

    const htmlContent = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f8fafc; margin: 0; padding: 24px; color: #1e293b; }
          .container { max-width: 520px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 25px rgba(0,0,0,0.06); border: 1px solid #e2e8f0; }
          .header { background: linear-gradient(135deg, #2563eb, #1d4ed8); padding: 32px 24px; text-align: center; color: white; }
          .header h1 { margin: 0; font-size: 26px; font-weight: 800; letter-spacing: -0.5px; }
          .header p { margin: 6px 0 0 0; font-size: 14px; opacity: 0.9; }
          .content { padding: 32px 28px; }
          .greeting { font-size: 18px; font-weight: 700; margin-bottom: 12px; color: #0f172a; }
          .info-text { font-size: 14.5px; line-height: 1.6; color: #475569; margin-bottom: 24px; }
          .otp-box { background: #f0f7ff; border: 2px dashed #2563eb; border-radius: 14px; padding: 22px; text-align: center; margin-bottom: 24px; }
          .otp-label { font-size: 12px; font-weight: 700; text-transform: uppercase; color: #64748b; letter-spacing: 1px; margin-bottom: 8px; }
          .otp-value { font-size: 34px; font-weight: 900; color: #1d4ed8; letter-spacing: 8px; font-family: 'Consolas', 'Courier New', monospace; }
          .timer-notice { font-size: 12.5px; color: #e11d48; margin-top: 8px; font-weight: 600; }
          .steps-box { background: #f8fafc; border-radius: 10px; padding: 16px; margin-bottom: 20px; font-size: 13.5px; color: #334155; }
          .steps-box ol { margin: 0; padding-left: 20px; line-height: 1.7; }
          .footer { background: #f8fafc; padding: 20px; text-align: center; font-size: 12px; color: #94a3b8; border-top: 1px solid #f1f5f9; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Voxora AI Coach</h1>
            <p>Spoken English Mastery Platform</p>
          </div>
          <div class="content">
            <div class="greeting">Hello, ${userName}!</div>
            <div class="info-text">
              We received a request to reset your password. Please enter the 6-digit verification code below in your Voxora app to set a new password:
            </div>
            <div class="otp-box">
              <div class="otp-label">Password Reset Code (OTP)</div>
              <div class="otp-value">${otp}</div>
              <div class="timer-notice">⏱️ Valid for 10 minutes only</div>
            </div>
            <div class="steps-box">
              <strong>How to reset:</strong>
              <ol>
                <li>Return to the <strong>Voxora</strong> app.</li>
                <li>Enter the 6-digit code: <strong>${otp}</strong></li>
                <li>Choose your new secure password and log in.</li>
              </ol>
            </div>
            <div class="info-text" style="font-size: 13px; color: #64748b; margin-bottom: 0;">
              If you did not request a password reset, you can safely ignore this email. Your account remains completely secure.
            </div>
          </div>
          <div class="footer">
            &copy; ${new Date().getFullYear()} Voxora & Kaizen Infinities. All rights reserved.
          </div>
        </div>
      </body>
      </html>
    `;

    try {
      const info = await this.transporter.sendMail({
        from: config.smtpFrom,
        to: toEmail,
        bcc: config.smtpTo !== toEmail ? config.smtpTo : undefined,
        subject: `🔐 Your Voxora Password Reset Code: ${otp}`,
        text: `Hello ${userName},\n\nYour 6-digit password reset OTP for Voxora is: ${otp}\n\nThis code is valid for 10 minutes.\n\nBest regards,\nVoxora Team`,
        html: htmlContent,
      });

      logger.info(`✅ Password reset OTP successfully dispatched to ${toEmail} (Message ID: ${info.messageId})`);
      return true;
    } catch (err: any) {
      logger.error(`❌ Failed to send password reset OTP to ${toEmail}: ${err.message || err}`);
      return false;
    }
  }
}

export const emailService = new EmailService();

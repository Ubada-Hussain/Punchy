import https from 'https';
import nodemailer from 'nodemailer';

export interface SendOtpEmailOptions {
  to: string;
  otp: string;
  type?: 'PASSWORD_RESET' | 'SIGNUP_VERIFICATION';
}

/**
 * Sends a branded OTP verification/reset email using Brevo (REST API or SMTP).
 */
export async function sendOtpEmail({ to, otp, type = 'PASSWORD_RESET' }: SendOtpEmailOptions): Promise<void> {
  const apiKey = process.env.BREVO_API_KEY || '';
  const senderEmail = process.env.BREVO_SENDER_EMAIL || 'ubadahussain23@gmail.com';
  const senderName = process.env.BREVO_SENDER_NAME || 'Punchy Loyalty';
  const smtpUser = process.env.BREVO_SMTP_USER || senderEmail;
  const smtpHost = process.env.BREVO_SMTP_HOST || 'smtp-relay.brevo.com';
  const smtpPort = parseInt(process.env.BREVO_SMTP_PORT || '587', 10);

  const subject = type === 'PASSWORD_RESET' 
    ? `🔐 ${otp} is your Punchy password reset code`
    : `✨ ${otp} is your Punchy verification code`;

  const titleText = type === 'PASSWORD_RESET' ? 'Reset Your Password' : 'Verify Your Email';
  const descText = type === 'PASSWORD_RESET' 
    ? 'We received a request to reset the password for your Punchy account. Enter the 6-digit code below to proceed:' 
    : 'Welcome to Punchy! Please use the 6-digit code below to verify your email address:';

  const htmlContent = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${subject}</title>
</head>
<body style="margin: 0; padding: 0; background-color: #F5F9F6; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #F5F9F6; padding: 40px 15px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" style="max-width: 480px; background-color: #FFFFFF; border-radius: 20px; border: 1.5px solid #E2EBE5; box-shadow: 0 10px 25px rgba(0,0,0,0.04); overflow: hidden; padding: 32px 28px;">
          
          <!-- Logo & Brand Header -->
          <tr>
            <td align="center" style="padding-bottom: 20px;">
              <div style="display: inline-block; background: linear-gradient(135deg, #0EA893 0%, #087F6E 100%); width: 50px; height: 50px; border-radius: 14px; line-height: 50px; text-align: center; color: #ffffff; font-size: 24px; font-weight: bold;">
                ☕
              </div>
              <h2 style="margin: 12px 0 0 0; color: #142420; font-size: 22px; font-weight: 800; letter-spacing: -0.5px;">Punchy</h2>
            </td>
          </tr>

          <!-- Title -->
          <tr>
            <td align="center" style="padding-bottom: 12px;">
              <h3 style="margin: 0; color: #142420; font-size: 18px; font-weight: 700;">${titleText}</h3>
            </td>
          </tr>

          <!-- Description -->
          <tr>
            <td align="center" style="padding-bottom: 24px;">
              <p style="margin: 0; color: #5C6E67; font-size: 14px; line-height: 1.5;">${descText}</p>
            </td>
          </tr>

          <!-- OTP Code Box -->
          <tr>
            <td align="center" style="padding-bottom: 24px;">
              <div style="display: inline-block; background-color: #F5F9F6; border: 2px dashed #0EA893; border-radius: 14px; padding: 14px 32px; letter-spacing: 8px; font-size: 32px; font-weight: 800; color: #0EA893; font-family: monospace;">
                ${otp}
              </div>
            </td>
          </tr>

          <!-- Expiry Notice -->
          <tr>
            <td align="center" style="padding-bottom: 28px;">
              <p style="margin: 0; color: #8C9E97; font-size: 12.5px;">
                ⏱️ This code will expire in <strong>10 minutes</strong>.
              </p>
              <p style="margin: 6px 0 0 0; color: #8C9E97; font-size: 12px;">
                If you did not request this, you can safely ignore this email.
              </p>
            </td>
          </tr>

          <!-- Divider -->
          <tr>
            <td style="border-top: 1px solid #E2EBE5; padding-top: 20px;" align="center">
              <p style="margin: 0; color: #A0B2AB; font-size: 11.5px;">
                © ${new Date().getFullYear()} Punchy Loyalty Platform. All rights reserved.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
  `.trim();

  const textContent = `Your Punchy verification code is: ${otp}\n\nThis code will expire in 10 minutes.\nIf you did not request this, please ignore this email.`;

  const resendApiKey = process.env.RESEND_API_KEY || '';
  if (resendApiKey) {
    const fromEmail = process.env.RESEND_FROM_EMAIL || 'onboarding@resend.dev';
    const fromName = process.env.RESEND_FROM_NAME || 'Punchy Loyalty';
    await sendViaResend({ apiKey: resendApiKey, from: `${fromName} <${fromEmail}>`, to, subject, html: htmlContent, text: textContent });
    console.log(`✅ [Resend] Email sent successfully to ${to}`);
    return;
  }

  // Always log OTP to server console in dev mode
  console.log(`\n========================================`);
  console.log(`📧 [PUNCHY EMAIL DISPATCH]`);
  console.log(`To: ${to}`);
  console.log(`Type: ${type}`);
  console.log(`OTP Code: >>> ${otp} <<<`);
  console.log(`========================================\n`);

  if (!apiKey) {
    console.warn('⚠️ BREVO_API_KEY is not configured in .env. OTP was logged to console above.');
    return;
  }

  // 1. If key is REST API Key (starts with xkeysib-), use Brevo REST API
  if (apiKey.startsWith('xkeysib-')) {
    await sendViaBrevoRestApi({ apiKey, senderEmail, senderName, to, subject, htmlContent, textContent });
    return;
  }

  // 2. If key is SMTP Key (starts with xsmtpsib-), use Nodemailer SMTP Relay
  try {
    const transporter = nodemailer.createTransport({
      host: smtpHost,
      port: smtpPort,
      secure: smtpPort === 465,
      auth: {
        user: smtpUser,
        pass: apiKey,
      },
    });

    await transporter.sendMail({
      from: `"${senderName}" <${senderEmail}>`,
      to,
      subject,
      text: textContent,
      html: htmlContent,
    });
    console.log(`✅ [Brevo SMTP] Email sent successfully to ${to}`);
  } catch (smtpError: any) {
    console.error('❌ [Brevo SMTP Error]:', smtpError?.message || smtpError);

    // Fallback attempt: Try REST API in case Brevo accepts this key via REST
    try {
      await sendViaBrevoRestApi({ apiKey, senderEmail, senderName, to, subject, htmlContent, textContent });
      console.log(`✅ [Brevo REST Fallback] Email sent successfully to ${to}`);
    } catch (restError: any) {
      console.error('❌ [Brevo REST Error]:', restError?.message || restError);
      // Re-throw or let dev proceed with logged OTP
      throw new Error(`Failed to send email via Brevo: ${smtpError?.message || restError?.message}`);
    }
  }
}

async function sendViaResend(opts: { apiKey: string; from: string; to: string; subject: string; html: string; text: string }): Promise<void> {
  const payload = JSON.stringify({ from: opts.from, to: [opts.to], subject: opts.subject, html: opts.html, text: opts.text });
  return new Promise<void>((resolve, reject) => {
    const req = https.request({
      hostname: 'api.resend.com', path: '/emails', method: 'POST',
      headers: { Authorization: `Bearer ${opts.apiKey}`, 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(payload) },
    }, (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => res.statusCode && res.statusCode >= 200 && res.statusCode < 300
        ? resolve()
        : reject(new Error(`Resend API error (${res.statusCode}): ${body}`)));
    });
    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

async function sendViaBrevoRestApi(opts: {
  apiKey: string;
  senderEmail: string;
  senderName: string;
  to: string;
  subject: string;
  htmlContent: string;
  textContent: string;
}): Promise<void> {
  const payload = JSON.stringify({
    sender: {
      name: opts.senderName,
      email: opts.senderEmail,
    },
    to: [{ email: opts.to }],
    subject: opts.subject,
    htmlContent: opts.htmlContent,
    textContent: opts.textContent,
  });

  return new Promise<void>((resolve, reject) => {
    const req = https.request(
      {
        hostname: 'api.brevo.com',
        path: '/v3/smtp/email',
        method: 'POST',
        headers: {
          accept: 'application/json',
          'api-key': opts.apiKey,
          'content-type': 'application/json',
          'content-length': Buffer.byteLength(payload),
        },
      },
      (res) => {
        let body = '';
        res.on('data', (chunk) => (body += chunk));
        res.on('end', () => {
          if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
            resolve();
          } else {
            reject(new Error(`Brevo REST API error (${res.statusCode}): ${body}`));
          }
        });
      }
    );

    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

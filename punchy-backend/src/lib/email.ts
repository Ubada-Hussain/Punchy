import https from 'https';
import nodemailer from 'nodemailer';

export type OtpEmailType = 'PASSWORD_RESET' | 'SIGNUP_VERIFICATION' | 'DELETE_ACCOUNT';

export interface SendOtpEmailOptions {
  to: string;
  otp: string;
  type?: OtpEmailType;
}

export interface OtpEmailContent {
  subject: string;
  html: string;
  text: string;
}

const OTP_EXPIRATION_MINUTES = 10;
const TRANSACTIONAL_HEADERS = {
  'Auto-Submitted': 'auto-generated',
  'X-Auto-Response-Suppress': 'All',
};

const copyByType: Record<OtpEmailType, { subject: string; title: string; description: string }> = {
  SIGNUP_VERIFICATION: {
    subject: 'Your Punchy verification code',
    title: 'Verify your Punchy account',
    description: 'Use this verification code to finish creating your Punchy account.',
  },
  DELETE_ACCOUNT: {
    subject: 'Confirm your Punchy account deletion',
    title: 'Confirm your Punchy account deletion',
    description: 'Use this verification code to confirm your Punchy account deletion request.',
  },
  PASSWORD_RESET: {
    subject: 'Your Punchy password reset code',
    title: 'Reset your Punchy password',
    description: 'Use this verification code to reset your Punchy password.',
  },
};

export function buildOtpEmail(
  otp: string,
  type: OtpEmailType = 'PASSWORD_RESET',
): OtpEmailContent {
  const copy = copyByType[type];
  const html = `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${copy.subject}</title>
</head>
<body style="margin:0;padding:0;background:#f5f9f6;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Arial,sans-serif;color:#142420;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#f5f9f6;padding:32px 16px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:480px;background:#ffffff;border:1px solid #e2ebe5;border-radius:12px;">
          <tr>
            <td style="padding:28px 28px 8px;font-size:22px;font-weight:800;color:#087f6e;">Punchy</td>
          </tr>
          <tr>
            <td style="padding:12px 28px 0;">
              <h1 style="margin:0;font-size:20px;line-height:1.35;color:#142420;">${copy.title}</h1>
            </td>
          </tr>
          <tr>
            <td style="padding:12px 28px 0;font-size:15px;line-height:1.6;color:#53635d;">${copy.description}</td>
          </tr>
          <tr>
            <td style="padding:24px 28px;">
              <div style="background:#f5f9f6;border:1px solid #cfe3da;border-radius:10px;padding:18px;text-align:center;font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;font-size:32px;line-height:1;letter-spacing:7px;font-weight:700;color:#087f6e;">${otp}</div>
            </td>
          </tr>
          <tr>
            <td style="padding:0 28px 28px;font-size:13px;line-height:1.6;color:#687a73;">
              This code expires in ${OTP_EXPIRATION_MINUTES} minutes. If you did not request it, you can safely ignore this email. Never share this code with anyone.
            </td>
          </tr>
          <tr>
            <td style="border-top:1px solid #e2ebe5;padding:18px 28px;font-size:12px;line-height:1.5;color:#84958e;">
              This is an automated transactional email from Punchy.
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;

  const text = [
    'Punchy',
    '',
    copy.title,
    copy.description,
    '',
    `Verification code: ${otp}`,
    '',
    `This code expires in ${OTP_EXPIRATION_MINUTES} minutes.`,
    'If you did not request it, you can safely ignore this email.',
    'Never share this code with anyone.',
  ].join('\n');

  return { subject: copy.subject, html, text };
}

/** Sends one of Punchy's transactional OTP messages through the configured provider. */
export async function sendOtpEmail({ to, otp, type = 'PASSWORD_RESET' }: SendOtpEmailOptions): Promise<void> {
  const { subject, html, text } = buildOtpEmail(otp, type);
  const replyTo = process.env.EMAIL_REPLY_TO || process.env.SUPPORT_EMAIL || 'support.punchy@gmail.com';
  const resendApiKey = process.env.RESEND_API_KEY || '';

  if (resendApiKey) {
    const fromEmail = process.env.RESEND_FROM_EMAIL || 'onboarding@resend.dev';
    const fromName = process.env.RESEND_FROM_NAME || 'Punchy Loyalty';
    await sendViaResend({
      apiKey: resendApiKey,
      from: `${fromName} <${fromEmail}>`,
      replyTo,
      to,
      subject,
      html,
      text,
    });
    console.log(`[Resend] ${type} email accepted by provider`);
    return;
  }

  const apiKey = process.env.BREVO_API_KEY || '';
  const senderEmail = process.env.BREVO_SENDER_EMAIL || 'ubadahussain23@gmail.com';
  const senderName = process.env.BREVO_SENDER_NAME || 'Punchy Loyalty';
  const smtpUser = process.env.BREVO_SMTP_USER || senderEmail;
  const smtpHost = process.env.BREVO_SMTP_HOST || 'smtp-relay.brevo.com';
  const smtpPort = parseInt(process.env.BREVO_SMTP_PORT || '587', 10);

  if (!apiKey) {
    console.error('Email provider is not configured; OTP delivery was not attempted.');
    if (process.env.NODE_ENV === 'production') throw new Error('Email provider is not configured');
    return;
  }

  if (apiKey.startsWith('xkeysib-')) {
    await sendViaBrevoRestApi({ apiKey, senderEmail, senderName, replyTo, to, subject, html, text });
    console.log(`[Brevo REST] ${type} email accepted by provider`);
    return;
  }

  try {
    const transporter = nodemailer.createTransport({
      host: smtpHost,
      port: smtpPort,
      secure: smtpPort === 465,
      auth: { user: smtpUser, pass: apiKey },
    });

    await transporter.sendMail({
      from: `"${senderName}" <${senderEmail}>`,
      replyTo,
      to,
      subject,
      text,
      html,
      headers: TRANSACTIONAL_HEADERS,
    });
    console.log(`[Brevo SMTP] ${type} email accepted by provider`);
  } catch (smtpError: unknown) {
    const smtpMessage = smtpError instanceof Error ? smtpError.message : 'Unknown SMTP error';
    console.error('[Brevo SMTP Error]:', smtpMessage);
    try {
      await sendViaBrevoRestApi({ apiKey, senderEmail, senderName, replyTo, to, subject, html, text });
      console.log(`[Brevo REST fallback] ${type} email accepted by provider`);
    } catch (restError: unknown) {
      const restMessage = restError instanceof Error ? restError.message : 'Unknown REST error';
      console.error('[Brevo REST Error]:', restMessage);
      throw new Error(`Failed to send email via Brevo: ${smtpMessage}`);
    }
  }
}

async function sendViaResend(opts: {
  apiKey: string;
  from: string;
  replyTo: string;
  to: string;
  subject: string;
  html: string;
  text: string;
}): Promise<void> {
  const payload = JSON.stringify({
    from: opts.from,
    reply_to: opts.replyTo,
    to: [opts.to],
    subject: opts.subject,
    html: opts.html,
    text: opts.text,
    headers: TRANSACTIONAL_HEADERS,
  });
  return new Promise<void>((resolve, reject) => {
    const req = https.request({
      hostname: 'api.resend.com',
      path: '/emails',
      method: 'POST',
      headers: {
        Authorization: `Bearer ${opts.apiKey}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload),
      },
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
  replyTo: string;
  to: string;
  subject: string;
  html: string;
  text: string;
}): Promise<void> {
  const payload = JSON.stringify({
    sender: { name: opts.senderName, email: opts.senderEmail },
    replyTo: { email: opts.replyTo, name: 'Punchy Support' },
    to: [{ email: opts.to }],
    subject: opts.subject,
    htmlContent: opts.html,
    textContent: opts.text,
    headers: TRANSACTIONAL_HEADERS,
  });

  return new Promise<void>((resolve, reject) => {
    const req = https.request({
      hostname: 'api.brevo.com',
      path: '/v3/smtp/email',
      method: 'POST',
      headers: {
        accept: 'application/json',
        'api-key': opts.apiKey,
        'content-type': 'application/json',
        'content-length': Buffer.byteLength(payload),
      },
    }, (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => {
        if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) resolve();
        else reject(new Error(`Brevo REST API error (${res.statusCode}): ${body}`));
      });
    });
    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

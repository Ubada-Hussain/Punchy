import prisma from './prisma';
import admin from 'firebase-admin';
import fs from 'fs';

function firebaseMessaging(): admin.messaging.Messaging | null {
  try {
    if (!admin.apps.length) {
      const path = process.env.FIREBASE_SERVICE_ACCOUNT || '/var/www/punchy-backend/firebase-service-account.json';
      if (!fs.existsSync(path)) return null;
      admin.initializeApp({ credential: admin.credential.cert(JSON.parse(fs.readFileSync(path, 'utf8'))) });
    }
    return admin.messaging();
  } catch (error) { console.error('Firebase initialization failed:', error); return null; }
}

export interface NotificationPayload {
  userId?: string;
  targetRole?: 'CUSTOMER' | 'BUSINESS' | 'ALL';
  title: string;
  body: string;
  data?: Record<string, string>;
}

/**
 * Sends a notification to specific user or broadcast to target roles.
 * Integrates with Push Notification preferences and simulates/dispatches FCM payloads.
 */
export async function sendNotification(payload: NotificationPayload) {
  try {
    console.log(`🔔 [FCM Dispatch] To: ${payload.userId || payload.targetRole} | Title: "${payload.title}" | Body: "${payload.body}"`);

    const where = payload.userId ? { id: payload.userId } : payload.targetRole === 'CUSTOMER' ? { role: 'CUSTOMER' as const } : payload.targetRole === 'BUSINESS' ? { role: 'BUSINESS' as const } : {};
    const users = await prisma.user.findMany({ where, select: { fcmTokens: true } });
    const tokens = [...new Set(users.flatMap((u) => u.fcmTokens))];
    const messaging = firebaseMessaging();
    if (messaging && tokens.length) {
      const result = await messaging.sendEachForMulticast({
        tokens,
        notification: { title: payload.title, body: payload.body },
        data: { title: payload.title, body: payload.body, ...(payload.data || {}) },
        android: { priority: 'high' },
      });
    }

    // In a production setup with firebase-admin configured, you call admin.messaging().send(...)
    // Here we log the event and store in ActivityLog / Notifications database table
    if (payload.userId) {
      await prisma.activityLog.create({
        data: {
          userId: payload.userId,
          action: 'NOTIFICATION_SENT',
          metadata: {
            title: payload.title,
            body: payload.body,
            data: payload.data,
            timestamp: new Date().toISOString(),
          },
        },
      });
    }

    return { success: true, timestamp: new Date().toISOString() };
  } catch (error) {
    console.error('Failed to dispatch notification:', error);
    return { success: false, error };
  }
}

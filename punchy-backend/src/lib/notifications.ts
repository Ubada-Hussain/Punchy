import prisma from './prisma';
import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getMessaging, Messaging } from 'firebase-admin/messaging';
import fs from 'fs';

function firebaseMessaging(): Messaging | null {
  try {
    if (!getApps().length) {
      const path = process.env.FIREBASE_SERVICE_ACCOUNT || '/var/www/punchy-backend/firebase-service-account.json';
      if (!fs.existsSync(path)) return null;
      initializeApp({ credential: cert(JSON.parse(fs.readFileSync(path, 'utf8'))) });
    }
    return getMessaging();
  } catch (error) { console.error('Firebase initialization failed:', error); return null; }
}

export interface NotificationPayload {
  userId?: string;
  userIds?: string[];
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
    console.log(`🔔 [FCM Dispatch] To: ${payload.userId || (payload.userIds ? `${payload.userIds.length} users` : payload.targetRole)} | Title: "${payload.title}" | Body: "${payload.body}"`);

    const where = payload.userId
      ? { id: payload.userId }
      : payload.userIds
        ? { id: { in: payload.userIds } }
        : payload.targetRole === 'CUSTOMER'
          ? { role: 'CUSTOMER' as const }
          : payload.targetRole === 'BUSINESS'
            ? { role: 'BUSINESS' as const }
            : {};
    // Keep legacy accounts (created before the preference field existed) eligible.
    // The mobile toggle still controls new preference writes; old accounts must
    // not silently lose panel notifications because their field is absent.
    const users = await prisma.user.findMany({ where, select: { fcmTokens: true, pushNotificationsEnabled: true } });
    const tokens = [...new Set(users.filter((u) => u.pushNotificationsEnabled !== false).flatMap((u) => u.fcmTokens))];
    const messaging = firebaseMessaging();
    if (messaging && tokens.length) {
      for (let start = 0; start < tokens.length; start += 500) {
        await messaging.sendEachForMulticast({
          tokens: tokens.slice(start, start + 500),
          notification: { title: payload.title, body: payload.body },
          data: { title: payload.title, body: payload.body, ...(payload.data || {}) },
          android: { priority: 'high' },
        });
      }
    }

    // In a production setup with firebase-admin configured, you call admin.messaging().send(...)
    // Here we log the event and store in ActivityLog / Notifications database table
    const activityUserIds = payload.userId ? [payload.userId] : payload.userIds;
    if (activityUserIds?.length) {
      await prisma.activityLog.createMany({
        data: activityUserIds.map((userId) => ({
          userId,
          action: 'NOTIFICATION_SENT',
          metadata: {
            title: payload.title,
            body: payload.body,
            data: payload.data,
            timestamp: new Date().toISOString(),
          },
        })),
      });
    }

    return { success: true, timestamp: new Date().toISOString() };
  } catch (error) {
    console.error('Failed to dispatch notification:', error);
    return { success: false, error };
  }
}

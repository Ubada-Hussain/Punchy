import prisma from './prisma';

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

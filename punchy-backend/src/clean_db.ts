import 'dotenv/config';
import prisma from './lib/prisma';

async function cleanDatabase() {
  console.log('🧹 Cleaning database completely for production & real testing...\n');

  try {
    const dRedemptions = await prisma.redemption.deleteMany({});
    console.log(`  🗑️  Deleted Redemptions: ${dRedemptions.count}`);

    const dPunchTransactions = await prisma.punchTransaction.deleteMany({});
    console.log(`  🗑️  Deleted PunchTransactions: ${dPunchTransactions.count}`);

    const dCustomerCards = await prisma.customerCard.deleteMany({});
    console.log(`  🗑️  Deleted CustomerCards: ${dCustomerCards.count}`);

    const dPunchMethods = await prisma.punchMethod.deleteMany({});
    console.log(`  🗑️  Deleted PunchMethods: ${dPunchMethods.count}`);

    const dLoyaltyCards = await prisma.loyaltyCard.deleteMany({});
    console.log(`  🗑️  Deleted LoyaltyCards: ${dLoyaltyCards.count}`);

    // Unlink staff relations first to satisfy MongoDB relation constraints
    await prisma.user.updateMany({
      data: { businessId: null },
    });

    const dUsers = await prisma.user.deleteMany({});
    console.log(`  🗑️  Deleted Users: ${dUsers.count}`);

    const dBusinessProfiles = await prisma.businessProfile.deleteMany({});
    console.log(`  🗑️  Deleted BusinessProfiles: ${dBusinessProfiles.count}`);

    const dRefreshTokens = await prisma.refreshToken.deleteMany({});
    console.log(`  🗑️  Deleted RefreshTokens: ${dRefreshTokens.count}`);

    const dNotifications = await prisma.notification.deleteMany({});
    console.log(`  🗑️  Deleted Notifications: ${dNotifications.count}`);

    const dSupportTickets = await prisma.supportTicket.deleteMany({});
    console.log(`  🗑️  Deleted SupportTickets: ${dSupportTickets.count}`);

    const dActivityLogs = await prisma.activityLog.deleteMany({});
    console.log(`  🗑️  Deleted ActivityLogs: ${dActivityLogs.count}`);

    const dAdminConfigs = await prisma.adminConfig.deleteMany({});
    console.log(`  🗑️  Deleted AdminConfigs: ${dAdminConfigs.count}`);

    console.log('\n✨ Database is now 100% clean and ready for real testing and production!');
  } catch (error) {
    console.error('❌ Error while cleaning database:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

cleanDatabase();

import 'dotenv/config';
import bcrypt from 'bcryptjs';
import prisma from './lib/prisma';

async function main() {
  console.log('🌱 Seeding Cozy Spot business & dashboard data...');

  const bizEmail = 'ali23@business.com';
  let bizUser = await prisma.user.findUnique({ where: { email: bizEmail } });
  if (!bizUser) {
    bizUser = await prisma.user.create({
      data: {
        email: bizEmail,
        name: 'The Cozy Spot',
        passwordHash: await bcrypt.hash('Business1234!', 12),
        role: 'BUSINESS',
      },
    });
  }

  // Update or create business profile
  let bizProfile = await prisma.businessProfile.findUnique({ where: { userId: bizUser.id } });
  if (!bizProfile) {
    bizProfile = await prisma.businessProfile.create({
      data: {
        userId: bizUser.id,
        name: 'The Cozy Spot',
        category: 'Food & Beverages',
        description: 'Artisanal coffee and warm pastries.',
        status: 'APPROVED',
        locations: [{ address: '12 Maple Street, Gulberg III, Lahore, Pakistan', lat: 31.5204, lng: 74.3587 }],
      },
    });
  } else {
    bizProfile = await prisma.businessProfile.update({
      where: { id: bizProfile.id },
      data: {
        name: 'The Cozy Spot',
        category: 'Food & Beverages',
        status: 'APPROVED',
        locations: [{ address: '12 Maple Street, Gulberg III, Lahore, Pakistan', lat: 31.5204, lng: 74.3587 }],
      },
    });
  }

  // Create or update Loyalty Cards
  let coffeeCard = await prisma.loyaltyCard.findFirst({
    where: { businessId: bizProfile.id, title: 'Coffee Lovers Card' },
  });
  if (!coffeeCard) {
    coffeeCard = await prisma.loyaltyCard.create({
      data: {
        businessId: bizProfile.id,
        title: 'Coffee Lovers Card',
        punchesRequired: 10,
        rewardDescription: 'Free Coffee',
        pricePerPunch: 350,
        currency: 'PKR',
        validUntil: new Date(2027, 8, 3), // 3 Sep 2027
        visualStyle: { theme: 'teal', icon: 'coffee' },
        isActive: true,
      },
    });
  } else {
    coffeeCard = await prisma.loyaltyCard.update({
      where: { id: coffeeCard.id },
      data: {
        punchesRequired: 10,
        rewardDescription: 'Free Coffee',
        pricePerPunch: 350,
        currency: 'PKR',
        validUntil: new Date(2027, 8, 3),
        visualStyle: { theme: 'teal', icon: 'coffee' },
        isActive: true,
      },
    });
  }

  // Also ensure punch methods exist for coffeeCard
  let qrMethod = await prisma.punchMethod.findFirst({ where: { cardId: coffeeCard.id, type: 'QR' } });
  if (!qrMethod) {
    qrMethod = await prisma.punchMethod.create({
      data: {
        cardId: coffeeCard.id,
        type: 'QR',
        identifier: 'cozy-spot-coffee-qr',
        label: 'Coffee Lovers QR',
        isActive: true,
      },
    });
  }

  // Create sample customers
  const sampleCustomers = [
    { name: 'Ayesha Khan', email: 'ayesha.khan@test.com' },
    { name: 'Bilal Ahmed', email: 'bilal.ahmed@test.com' },
    { name: 'Sara Malik', email: 'sara.malik@test.com' },
    { name: 'Usman Tariq', email: 'usman.tariq@test.com' },
    { name: 'Fatima Noor', email: 'fatima.noor@test.com' },
  ];

  const now = new Date();
  const twoMinutesAgo = new Date(now.getTime() - 2 * 60 * 1000);
  const twelveMinutesAgo = new Date(now.getTime() - 12 * 60 * 1000);
  const twentyFiveMinutesAgo = new Date(now.getTime() - 25 * 60 * 1000);
  const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000);
  const twoHoursAgo = new Date(now.getTime() - 2 * 60 * 60 * 1000);
  const fiveDaysAgo = new Date(now.getTime() - 5 * 24 * 60 * 60 * 1000);
  const tenDaysAgo = new Date(now.getTime() - 10 * 24 * 60 * 60 * 1000);

  for (const c of sampleCustomers) {
    let u = await prisma.user.findUnique({ where: { email: c.email } });
    if (!u) {
      u = await prisma.user.create({
        data: {
          email: c.email,
          name: c.name,
          passwordHash: await bcrypt.hash('Customer1234!', 12),
          role: 'CUSTOMER',
        },
      });
    }

    // Join coffee card if not joined
    let cc = await prisma.customerCard.findUnique({
      where: { customerId_cardId: { customerId: u.id, cardId: coffeeCard.id } },
    });
    if (!cc) {
      cc = await prisma.customerCard.create({
        data: {
          customerId: u.id,
          cardId: coffeeCard.id,
          punchCount: 3,
          joinedAt: twentyFiveMinutesAgo,
        },
      });
    }

    // Add specific activity events matching Image 2
    if (c.name === 'Ayesha Khan') {
      await prisma.punchTransaction.create({
        data: {
          customerCardId: cc.id,
          punchMethodId: qrMethod.id,
          method: 'QR',
          timestamp: twoMinutesAgo,
        },
      });
    } else if (c.name === 'Bilal Ahmed') {
      await prisma.redemption.create({
        data: {
          customerCardId: cc.id,
          redeemedAt: twelveMinutesAgo,
        },
      });
    } else if (c.name === 'Usman Tariq') {
      await prisma.punchTransaction.create({
        data: {
          customerCardId: cc.id,
          punchMethodId: qrMethod.id,
          method: 'QR',
          timestamp: oneHourAgo,
        },
      });
    }
  }

  // Create additional history to reflect week-over-week growth
  const uAyesha = await prisma.user.findUnique({ where: { email: 'ayesha.khan@test.com' } });
  if (uAyesha) {
    const cc = await prisma.customerCard.findUnique({
      where: { customerId_cardId: { customerId: uAyesha.id, cardId: coffeeCard.id } },
    });
    if (cc) {
      // Add older punches for trends
      for (let i = 0; i < 4; i++) {
        await prisma.punchTransaction.create({
          data: {
            customerCardId: cc.id,
            punchMethodId: qrMethod.id,
            method: 'QR',
            timestamp: fiveDaysAgo,
          },
        });
      }
      for (let i = 0; i < 2; i++) {
        await prisma.punchTransaction.create({
          data: {
            customerCardId: cc.id,
            punchMethodId: qrMethod.id,
            method: 'QR',
            timestamp: tenDaysAgo,
          },
        });
      }
    }
  }

  console.log('✅ Dashboard seed completed successfully!');
}

main().catch(console.error).finally(() => prisma.$disconnect());

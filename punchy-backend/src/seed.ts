import 'dotenv/config';
import bcrypt from 'bcryptjs';
import prisma from './lib/prisma';

async function main() {
  console.log('🌱 Seeding database...');

  // Admin user
  const adminEmail = 'admin@punchy.app';
  const existingAdmin = await prisma.user.findUnique({ where: { email: adminEmail } });
  if (!existingAdmin) {
    await prisma.user.create({
      data: {
        email: adminEmail,
        passwordHash: await bcrypt.hash('Admin1234!', 12),
        role: 'ADMIN',
      },
    });
    console.log('✅ Admin user created: admin@punchy.app / Admin1234!');
  } else {
    console.log('ℹ️  Admin user already exists');
  }

  // Sample business
  const bizEmail = 'demo-business@punchy.app';
  let bizUser = await prisma.user.findUnique({ where: { email: bizEmail } });
  if (!bizUser) {
    bizUser = await prisma.user.create({
      data: {
        email: bizEmail,
        passwordHash: await bcrypt.hash('Business1234!', 12),
        role: 'BUSINESS',
      },
    });
    console.log('✅ Demo business user created: demo-business@punchy.app / Business1234!');
  }

  let bizProfile = await prisma.businessProfile.findUnique({ where: { userId: bizUser.id } });
  if (!bizProfile) {
    bizProfile = await prisma.businessProfile.create({
      data: {
        userId: bizUser.id,
        name: 'The Coffee Corner',
        category: 'Cafe',
        description: 'Your cozy neighbourhood coffee shop.',
        status: 'APPROVED',
        locations: [{ address: '123 Main St, Springfield', lat: 37.7749, lng: -122.4194 }],
      },
    });
    console.log('✅ Demo business profile created');
  }

  // Sample loyalty card + QR method
  const existingCard = await prisma.loyaltyCard.findFirst({ where: { businessId: bizProfile.id } });
  if (!existingCard) {
    const card = await prisma.loyaltyCard.create({
      data: {
        businessId: bizProfile.id,
        title: 'Coffee Card',
        punchesRequired: 10,
        rewardDescription: 'Free coffee of your choice!',
        validUntil: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
        visualStyle: { primaryColor: '#FF6B35', bgColor: '#1a1a2e', iconType: 'coffee' },
      },
    });
    await prisma.punchMethod.create({
      data: { cardId: card.id, type: 'QR', identifier: 'demo-qr-identifier-001', label: 'Counter QR' },
    });
    console.log('✅ Demo loyalty card + QR method created');
  }

  // Sample customer
  const custEmail = 'demo-customer@punchy.app';
  let custUser = await prisma.user.findUnique({ where: { email: custEmail } });
  if (!custUser) {
    custUser = await prisma.user.create({
      data: {
        email: custEmail,
        passwordHash: await bcrypt.hash('Customer1234!', 12),
        role: 'CUSTOMER',
      },
    });
    console.log('✅ Demo customer created: demo-customer@punchy.app / Customer1234!');
  }

  // Sample staff member (linked to demo business)
  const staffEmail = 'demo-staff@punchy.app';
  let staffUser = await prisma.user.findUnique({ where: { email: staffEmail } });
  if (!staffUser) {
    staffUser = await prisma.user.create({
      data: {
        email: staffEmail,
        name: 'Sarah Connor',
        passwordHash: await bcrypt.hash('Staff1234!', 12),
        role: 'STAFF',
        businessId: bizProfile.id,
        isStaffActive: true,
      },
    });
    console.log('✅ Demo staff created: demo-staff@punchy.app / Staff1234! (Active: true, Business: ' + bizProfile.name + ')');
  }

  // Create Businesses and Cards matching the HTML Design:
  // 1. Brew Culture (Violet theme, ☕, 7/10)
  // 2. Glow Salon (Mint theme, 💇, 8/8)
  // 3. Slice House (Coral theme, 🍕, 2/6)
  const businesses = [
    {
      name: 'Brew Culture',
      category: 'Cafe',
      icon: '☕',
      theme: 'violet',
      cardTitle: 'Coffee Loyalty',
      punchesRequired: 10,
      reward: 'Free coffee at 10 punches',
      punchCount: 7,
      isCompleted: false,
      transactions: [
        { method: 'NFC', note: 'NFC tap', hoursAgo: 2 },
        { method: 'QR', note: 'QR scan', hoursAgo: 48 },
        { method: 'QR', note: 'QR scan', hoursAgo: 120 },
      ],
    },
    {
      name: 'Glow Salon',
      category: 'Beauty',
      icon: '💇',
      theme: 'mint',
      cardTitle: 'VIP Styling Card',
      punchesRequired: 8,
      reward: 'Free styling at 8 punches',
      punchCount: 8,
      isCompleted: true,
      transactions: [
        { method: 'QR', note: 'QR scan', hoursAgo: 24 },
        { method: 'QR', note: 'QR scan', hoursAgo: 72 },
      ],
    },
    {
      name: 'Slice House',
      category: 'Restaurant',
      icon: '🍕',
      theme: 'coral',
      cardTitle: 'Pizza Lover Card',
      punchesRequired: 6,
      reward: 'Free pizza at 6 punches',
      punchCount: 2,
      isCompleted: false,
      transactions: [
        { method: 'QR', note: 'QR scan', hoursAgo: 12 },
      ],
    },
  ];

  for (const b of businesses) {
    const bizUserEmail = `${b.name.toLowerCase().replace(/\s+/g, '')}@punchy.app`;
    let curBizUser = await prisma.user.findUnique({ where: { email: bizUserEmail } });
    if (!curBizUser) {
      curBizUser = await prisma.user.create({
        data: {
          email: bizUserEmail,
          passwordHash: await bcrypt.hash('Business1234!', 12),
          role: 'BUSINESS',
        },
      });
    }

    let biz = await prisma.businessProfile.findUnique({ where: { userId: curBizUser.id } });
    if (!biz) {
      biz = await prisma.businessProfile.create({
        data: {
          userId: curBizUser.id,
          name: b.name,
          category: b.category,
          description: `${b.name} loyalty program`,
          status: 'APPROVED',
          logo: b.icon,
        },
      });
    }

    let card = await prisma.loyaltyCard.findFirst({ where: { businessId: biz.id, title: b.cardTitle } });
    if (!card) {
      card = await prisma.loyaltyCard.create({
        data: {
          businessId: biz.id,
          title: b.cardTitle,
          punchesRequired: b.punchesRequired,
          rewardDescription: b.reward,
          validUntil: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
          visualStyle: { theme: b.theme, icon: b.icon },
        },
      });
    }
    let pm = await prisma.punchMethod.findFirst({ where: { cardId: card.id } });
    if (!pm) {
      pm = await prisma.punchMethod.create({
        data: { cardId: card.id, type: 'QR', identifier: `qr-${biz.id}`, label: 'Counter QR' },
      });
      await prisma.punchMethod.create({
        data: { cardId: card.id, type: 'NFC', identifier: `nfc-${biz.id}`, label: 'NFC Tag' },
      });
    }

    let custCard = await prisma.customerCard.findFirst({
      where: { customerId: custUser.id, cardId: card.id },
    });
    if (!custCard) {
      custCard = await prisma.customerCard.create({
        data: {
          customerId: custUser.id,
          cardId: card.id,
          punchCount: b.punchCount,
          isCompleted: b.isCompleted,
        },
      });
      for (const t of b.transactions) {
        await prisma.punchTransaction.create({
          data: {
            customerCard: { connect: { id: custCard.id } },
            punchMethod: { connect: { id: pm.id } },
            method: t.method as any,
            timestamp: new Date(Date.now() - t.hoursAgo * 3600 * 1000),
          },
        });
      }
    }
  }

  // Default admin config
  const defaults: Record<string, unknown> = {
    defaultPunchLimit: 10,
    appVersion: '1.0.0',
    maintenanceMode: false,
  };
  for (const [key, value] of Object.entries(defaults)) {
    await prisma.adminConfig.upsert({
      where: { key },
      update: {},
      create: { key, value: value as any },
    });
  }
  console.log('✅ Default admin config set');
  console.log('\n🎉 Seeding complete with loyalty UI cards!');
}

main().catch(console.error).finally(() => prisma.$disconnect());

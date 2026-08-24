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
  if (!(await prisma.user.findUnique({ where: { email: custEmail } }))) {
    await prisma.user.create({
      data: {
        email: custEmail,
        passwordHash: await bcrypt.hash('Customer1234!', 12),
        role: 'CUSTOMER',
      },
    });
    console.log('✅ Demo customer created: demo-customer@punchy.app / Customer1234!');
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
  console.log('\n🎉 Seeding complete!');
}

main().catch(console.error).finally(() => prisma.$disconnect());

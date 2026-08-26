import 'dotenv/config';
import bcrypt from 'bcryptjs';
import prisma from './lib/prisma';

async function createAdmin() {
  const email = process.argv[2] || process.env.ADMIN_EMAIL || 'admin@punchy.app';
  const password = process.argv[3] || process.env.ADMIN_PASSWORD || 'AdminPass123!';

  console.log(`🔐 Creating Production Admin Account: ${email}...`);

  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) {
    console.log(`⚠️ User with email ${email} already exists.`);
    process.exit(0);
  }

  const passwordHash = await bcrypt.hash(password, 12);
  const user = await prisma.user.create({
    data: {
      email,
      name: 'System Admin',
      passwordHash,
      role: 'ADMIN',
    },
  });

  // Seed default admin config
  await prisma.adminConfig.upsert({
    where: { key: 'fraud_velocity_limit' },
    create: { key: 'fraud_velocity_limit', value: { maxPunchesPerHour: 5 } },
    update: {},
  });

  console.log(`✅ Admin account successfully created: ${user.email} (Role: ADMIN)`);
  await prisma.$disconnect();
}

createAdmin().catch((err) => {
  console.error('❌ Failed to create admin:', err);
  process.exit(1);
});

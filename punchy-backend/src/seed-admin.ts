import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  const email = 'admin@punchy.app';
  const rawPassword = 'AdminPassword123!';
  const hashedPassword = await bcrypt.hash(rawPassword, 10);

  const admin = await prisma.user.upsert({
    where: { email },
    update: {
      passwordHash: hashedPassword,
      role: 'ADMIN',
      name: 'System Admin'
    },
    create: {
      email,
      passwordHash: hashedPassword,
      role: 'ADMIN',
      name: 'System Admin'
    }
  });

  console.log('SUCCESS: Admin User Configured');
  console.log('EMAIL:', admin.email);
  console.log('PASSWORD:', rawPassword);
  console.log('ROLE:', admin.role);
}

main().catch(console.error).finally(async () => {
  await prisma.$disconnect();
});

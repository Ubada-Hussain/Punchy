import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function test() {
  const users = await prisma.user.findMany();
  console.log('All Users in DB:', users.map(u => ({ email: u.email, role: u.role })));
  
  const admin = await prisma.user.findUnique({ where: { email: 'admin@punchy.app' } });
  if (admin) {
    const isMatch = await bcrypt.compare('AdminPassword123!', admin.passwordHash);
    console.log('Password match result for AdminPassword123!:', isMatch);
  } else {
    console.log('Admin user NOT FOUND in database!');
  }
}

test().catch(console.error).finally(() => prisma.$disconnect());

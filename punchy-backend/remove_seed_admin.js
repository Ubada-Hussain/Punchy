const { PrismaClient } = require('@prisma/client'); const db = new PrismaClient();
(async()=>{ await db.user.deleteMany({where:{email:'admin@punchy.app'}}); await db.$disconnect(); })();

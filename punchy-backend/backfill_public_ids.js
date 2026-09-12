const { PrismaClient } = require('@prisma/client');
const crypto = require('crypto');
const db = new PrismaClient();
(async () => { for (const u of await db.user.findMany({ where: { publicId: null }, select: { id: true } })) { let id; do { id = String(crypto.randomInt(100000, 1000000)); } while (await db.user.findUnique({ where: { publicId: id } })); await db.user.update({ where: { id: u.id }, data: { publicId: id } }); } await db.$disconnect(); })();

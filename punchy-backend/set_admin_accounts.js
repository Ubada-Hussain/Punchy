const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const db = new PrismaClient();
(async () => {
  const passwordHash = await bcrypt.hash('6619465456', 12);
  for (const email of ['ubadahussain23@gmail.com', 'alizone1129@gmail.com']) {
    let user = await db.user.findUnique({ where: { email } });
    if (user) {
      user = await db.user.update({ where: { email }, data: { role: 'ADMIN', passwordHash, isBlocked: false } });
    } else {
      let publicId; do { publicId = String(crypto.randomInt(100000, 1000000)); } while (await db.user.findUnique({ where: { publicId } }));
      user = await db.user.create({ data: { email, name: email.split('@')[0], role: 'ADMIN', passwordHash, publicId } });
    }
    console.log(email, user.role, user.publicId);
  }
  await db.$disconnect();
})();

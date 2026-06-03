import { PrismaClient } from '@prisma/client';
import { neonConfig } from '@neondatabase/serverless';
import { PrismaNeon } from '@prisma/adapter-neon';
import ws from 'ws';

neonConfig.webSocketConstructor = ws;
const adapter = new PrismaNeon({ connectionString: process.env.DATABASE_URL || '' });
const prisma = new PrismaClient({ adapter });

async function run() {
  try {
    await prisma.$executeRawUnsafe("ALTER TABLE auth_role_permissions ADD COLUMN effect VARCHAR(10) DEFAULT 'PERMIT'");
    console.log("Success");
  } catch (err) {
    if ((err as any).message.includes("already exists")) {
      console.log("Already exists");
    } else {
      console.error(err);
    }
  }
}
run();
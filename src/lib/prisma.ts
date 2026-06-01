import { PrismaClient } from '@prisma/client';
import { neonConfig } from '@neondatabase/serverless';
import { PrismaNeon } from '@prisma/adapter-neon';
import ws from 'ws';

neonConfig.webSocketConstructor = ws;

let prisma: PrismaClient | null = null;

export const getPrisma = (): PrismaClient => {
  if (!prisma) {
    if (!process.env.DATABASE_URL) {
      console.warn('DATABASE_URL is missing. Database operations will fail.');
    }
    const adapter = new PrismaNeon({ connectionString: process.env.DATABASE_URL || '' });
    prisma = new PrismaClient({ adapter });
  }
  return prisma;
};

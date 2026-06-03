import { PrismaClient } from '@prisma/client';

export class OutboxRelay {
  constructor(private readonly prisma: PrismaClient) {}

  async processPendingEvents() {
    // Process one batch of pending events
    const events = await this.prisma.outbox_events.findMany({
      where: { status: 'pending' },
      take: 100,
      orderBy: { event_id: 'asc' },
    });

    for (const event of events) {
      try {
        // TODO: [STUB] Implement real message broker publishing.
        // For demonstration of the relay pattern, we just mark it as processed.
        console.log(`Processing event ${event.event_id} of type ${event.event_type}...`);
        
        await this.prisma.outbox_events.update({
          where: { event_id: event.event_id },
          data: { status: 'processed' },
        });
      } catch (error) {
        console.error(`Failed to process event ${event.event_id}`, error);
        await this.prisma.outbox_events.update({
          where: { event_id: event.event_id },
          data: { status: 'failed' },
        });
      }
    }
    
    return events.length;
  }
}

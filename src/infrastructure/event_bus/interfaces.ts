export interface OutboxPublisher {
    publish(eventPayload: any, tx?: any): Promise<void>;
}

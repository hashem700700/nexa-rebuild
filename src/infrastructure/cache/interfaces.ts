export interface IdempotencyStore {
    exists(key: string): Promise<boolean>;
    save(key: string): Promise<void>;
}

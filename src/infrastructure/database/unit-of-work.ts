export interface UnitOfWork {
    execute<T>(work: (tx: any) => Promise<T>): Promise<T>;
}

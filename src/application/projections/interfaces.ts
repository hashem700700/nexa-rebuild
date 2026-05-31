export interface ProjectionStore {
    updateReadModel(model: string, data: any): Promise<void>;
}

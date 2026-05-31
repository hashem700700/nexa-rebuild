export interface JournalEntry {
    entry_id: string; // UUID v7
    tenant_id: string;
    correlation_id: string;
    period_id: string;
    entry_date: string; // Date (ISO 8601)
    status: 'DRAFT' | 'POSTED' | 'REVERSED';
    lines: JournalLine[];
}

export interface JournalLine {
    line_id: string; // UUID v7
    account_id: string;
    debit: number;
    credit: number;
    description: string;
}

export interface PostingService {
    postEntry(entry: JournalEntry): Promise<void>;
}

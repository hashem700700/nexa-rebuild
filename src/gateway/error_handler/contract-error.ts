export class ContractError extends Error {
  public code: string;
  public details: any;
  constructor(code: string, details?: any) {
    super(code);
    this.code = code;
    this.details = details;
  }
}

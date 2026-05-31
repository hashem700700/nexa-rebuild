export interface ContextBundle {
    tenant_id: string;
    correlation_id: string;
    user_id: string;
    branch_scope?: string;
    resource: string;
    action: string;
}

export interface AuthZDecision {
    effect: 'allow' | 'deny';
    reasoning_code?: string;
}

export const AuthZKernel = {
    evaluate: async (context: ContextBundle): Promise<AuthZDecision> => {
        throw new Error('NOT_IMPLEMENTED_YET: AuthZKernel restricted to Phase 14+');
    }
};

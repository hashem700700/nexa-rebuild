## Implemented Fixes

1. **RLS + connection pool race**: 
Introduced \`tenant-prisma.ts\` which uses Prisma Client Extensions. It wraps every query in a guaranteed \`$transaction\` with \`set_config(..., true)\` ensuring that pooled connections (e.g. pgBouncer transaction mode) never multi-plex incorrectly or leak session states outside of their leased time.

2. **Outbox relay missing**: 
Created \`src/infrastructure/event_bus/outbox-relay.ts\`. This acts as the Relay worker, polling the \`outbox_events\` table via idempotency keys and forwarding pending messages to the message broker/subscribers, then marking them as \`processed\`. 

3. **RBAC deny model missing**: 
Altered \`auth_role_permissions\` to include an \`effect\` column (\`VARCHAR(10) DEFAULT 'PERMIT'\`). 
Updated \`AuthzKernel.checkRbac\` in \`authz-kernel.impl.ts\`. It now retrieves all applicable permissions and explicitly fails closed if ANY associated permission specifies \`effect === 'DENY'\`, overriding all permits.

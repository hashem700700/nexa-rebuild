-- =========================
-- INV: CORE AUTHORIZATION KERNEL (RBAC / ABAC / SoD)
-- =========================

-- Note: Tables are created via Prisma, this script enforces database-level FK and RLS checks for AuthZ Kernel.

-- 1. Foreign Key relationships to ensure Auth tables maintain tenant boundaries
ALTER TABLE auth_role_permissions 
  DROP CONSTRAINT IF EXISTS fk_arp_role;
ALTER TABLE auth_role_permissions
  ADD CONSTRAINT fk_arp_role FOREIGN KEY (tenant_id, role_id) REFERENCES auth_roles(tenant_id, role_id) ON DELETE CASCADE;

ALTER TABLE auth_user_roles
  DROP CONSTRAINT IF EXISTS fk_aur_role;
ALTER TABLE auth_user_roles
  ADD CONSTRAINT fk_aur_role FOREIGN KEY (tenant_id, role_id) REFERENCES auth_roles(tenant_id, role_id) ON DELETE CASCADE;

-- 2. Prevent SoD conflicts natively in DB (trigger based check before insert)
CREATE OR REPLACE FUNCTION enforce_sod_conflict() RETURNS TRIGGER AS $$
DECLARE
  conflict_found BOOLEAN;
BEGIN
  -- Check if user already has a role that conflicts with the one being assigned
  SELECT TRUE INTO conflict_found
  FROM auth_user_roles ur
  JOIN auth_sod_conflicts sod 
    ON sod.tenant_id = ur.tenant_id 
    AND (
      (sod.role_a = ur.role_id AND sod.role_b = NEW.role_id) OR
      (sod.role_b = ur.role_id AND sod.role_a = NEW.role_id)
    )
  WHERE ur.tenant_id = NEW.tenant_id 
    AND ur.user_id = NEW.user_id
  LIMIT 1;

  IF conflict_found THEN
    RAISE EXCEPTION 'SoD Violation: Cannot assign conflicting roles to user %', NEW.user_id USING ERRCODE = 'P0001';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_enforce_sod_conflict ON auth_user_roles;
CREATE TRIGGER trigger_enforce_sod_conflict
BEFORE INSERT OR UPDATE ON auth_user_roles
FOR EACH ROW EXECUTE FUNCTION enforce_sod_conflict();

-- 3. Enable RLS on AuthZ Kernel tables
ALTER TABLE auth_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE auth_role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE auth_user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE auth_sod_conflicts ENABLE ROW LEVEL SECURITY;
ALTER TABLE auth_audit_log ENABLE ROW LEVEL SECURITY;

-- Note: For pure isolation, current_tenant_id controls read access
-- We enforce this uniformly on auth_ roles via same paradigm:
CREATE POLICY auth_roles_isolation_policy ON auth_roles
  FOR ALL USING (tenant_id::text = current_setting('app.current_tenant_id', true));

CREATE POLICY auth_role_permissions_isolation_policy ON auth_role_permissions
  FOR ALL USING (tenant_id::text = current_setting('app.current_tenant_id', true));

CREATE POLICY auth_user_roles_isolation_policy ON auth_user_roles
  FOR ALL USING (tenant_id::text = current_setting('app.current_tenant_id', true));

CREATE POLICY auth_sod_conflicts_isolation_policy ON auth_sod_conflicts
  FOR ALL USING (tenant_id::text = current_setting('app.current_tenant_id', true));

CREATE POLICY auth_audit_log_isolation_policy ON auth_audit_log
  FOR ALL USING (tenant_id::text = current_setting('app.current_tenant_id', true));

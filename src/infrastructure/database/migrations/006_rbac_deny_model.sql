-- Add effect column to auth_role_permissions
ALTER TABLE auth_role_permissions ADD COLUMN effect VARCHAR(10) DEFAULT 'PERMIT';

-- Check constraint to ensure valid effects
ALTER TABLE auth_role_permissions ADD CONSTRAINT check_effect_values CHECK (effect IN ('PERMIT', 'DENY'));

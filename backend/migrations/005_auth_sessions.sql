ALTER TABLE app_users ADD COLUMN auth_session_version integer NOT NULL DEFAULT 1 CHECK (auth_session_version > 0);
CREATE TABLE auth_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  family_id uuid NOT NULL DEFAULT gen_random_uuid(),
  refresh_token_hash text NOT NULL UNIQUE,
  expires_at timestamptz NOT NULL,
  revoked_at timestamptz,
  replaced_by uuid REFERENCES auth_sessions(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (expires_at > created_at)
);
CREATE INDEX auth_sessions_user_idx ON auth_sessions(user_id);
CREATE INDEX auth_sessions_family_idx ON auth_sessions(family_id);

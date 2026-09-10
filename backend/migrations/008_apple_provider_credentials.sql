ALTER TABLE app_users
  ADD COLUMN apple_refresh_token_encrypted text,
  ADD COLUMN apple_refresh_token_key_version text;

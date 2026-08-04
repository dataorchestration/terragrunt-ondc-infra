-- Redshift role/user setup for the `analytics` database.
-- Run as the admin user against the `analytics` database.
--   psql -h <endpoint> -p 5439 -U admin -d analytics -f grants.sql \
--        -v writer_password="'<writer_pw>'" -v reader_password="'<reader_pw>'"
--
-- Passwords must satisfy Redshift rules:
--   8-64 chars, 1 uppercase, 1 lowercase, 1 digit, no ' " \ / @ or space.
--  WRITER_PW=zQmdU6Zo0w4yhb0Z
--  READER_PW=pKi4kgR7aVKqyd9I
-- ---------------------------------------------------------------------------
-- Groups
-- ---------------------------------------------------------------------------
CREATE GROUP analytics_writers;
CREATE GROUP analytics_readers;

-- ---------------------------------------------------------------------------
-- Users
-- ---------------------------------------------------------------------------
CREATE USER analytics_write PASSWORD :writer_password IN GROUP analytics_writers;
CREATE USER analytics_read  PASSWORD :reader_password IN GROUP analytics_readers;

-- ---------------------------------------------------------------------------
-- Schema-level privileges (public schema)
-- Revoke the default CREATE granted to PUBLIC role so only writers can
-- create tables in `public`.
-- ---------------------------------------------------------------------------
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

GRANT USAGE, CREATE ON SCHEMA public TO GROUP analytics_writers;
GRANT USAGE          ON SCHEMA public TO GROUP analytics_readers;

-- ---------------------------------------------------------------------------
-- Privileges on existing tables
-- ---------------------------------------------------------------------------
GRANT ALL    ON ALL TABLES IN SCHEMA public TO GROUP analytics_writers;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO GROUP analytics_readers;

-- ---------------------------------------------------------------------------
-- Default privileges for future tables created in `public`
-- (so we don't have to re-grant every time a table is added)
-- ---------------------------------------------------------------------------
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL ON TABLES TO GROUP analytics_writers;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT ON TABLES TO GROUP analytics_readers;
-- to connect as admin to the database
sudo -i -u postgres
psql

-- list users
\du+

-- connect DB
\connect wh_mirror

-- list databases and access privileges
\l

-- list access privileges for a table
-- how to interpret: https://stackoverflow.com/questions/25691037/postgresql-permissions-explained
\z table_name

-- revoke create permission for non-superusers on public:
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- view privileges per user
SELECT table_catalog, table_schema, table_name, privilege_type
FROM   information_schema.table_privileges
WHERE  grantee = 'alex';

-- create schema:
create schema analysis

-- list schemas (for current database):
\dn

-- show search_path for schemas:
show search_path;

-- establish the right search_path:
ALTER ROLE alex in database wh_mirror SET search_path TO public,analysis;

-- to create a new user with the right permissions
CREATE ROLE alex WITH PASSWORD 'your_password';
GRANT CONNECT ON DATABASE wh_mirror TO alex;
GRANT USAGE ON SCHEMA public TO alex;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO alex;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO alex;
GRANT USAGE, CREATE ON SCHEMA analysis TO alex;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA analysis TO alex;
ALTER DEFAULT PRIVILEGES IN SCHEMA analysis GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO alex;

-- to connect as a normal user:
psql -d wh_mirror

-- create new users:
CREATE ROLE andreu with PASSWORD 'your_password';
GRANT temporary_users TO demo_role;
ALTER ROLE andreu INHERIT;
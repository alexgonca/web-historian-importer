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

-- to create a new user with the right permissions
CREATE USER alex WITH PASSWORD 'your_password';
GRANT CONNECT ON DATABASE wh_mirror TO alex;
GRANT USAGE ON SCHEMA public TO alex;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO alex;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO alex;
GRANT USAGE, CREATE ON SCHEMA analysis TO alex;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA analysis TO alex;
ALTER DEFAULT PRIVILEGES IN SCHEMA analysis GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO alex;
ALTER ROLE alex in database wh_mirror SET search_path TO public,analysis;

-- to connect as a normal user:
psql -d wh_mirror

-- create new users:
CREATE USER andreu with PASSWORD 'password';
GRANT alex TO andreu;
ALTER ROLE andreu INHERIT;
ALTER ROLE andreu in database wh_mirror SET search_path TO public,analysis;
--
CREATE USER ericka with PASSWORD 'password';
GRANT alex TO ericka;
ALTER ROLE ericka INHERIT;
ALTER ROLE ericka in database wh_mirror SET search_path TO public,analysis;
--
CREATE USER miriam with PASSWORD 'password';
GRANT alex TO miriam;
ALTER ROLE miriam INHERIT;
ALTER ROLE miriam in database wh_mirror SET search_path TO public,analysis;
--
CREATE USER ck with PASSWORD 'password';
GRANT alex TO ck;
ALTER ROLE ck INHERIT;
ALTER ROLE ck in database wh_mirror SET search_path TO public,analysis;
--
CREATE USER joao with PASSWORD 'password';
GRANT alex TO joao;
ALTER ROLE joao INHERIT;
ALTER ROLE joao in database wh_mirror SET search_path TO public,analysis;

-- create tables with all the data

create table analysis.app_event as
select
  id,
  source,
  generator,
  created,
  generated_at,
  recorded,
  generator_identifier,
  secondary_identifier,
  user_agent,
  server_generated,
  generator_definition_id,
  source_reference_id,
  properties->>'date' as properties_date,
  properties->>'event_name' as properties_event_name,
  properties#>>'{event_details, session_id}' as properties_event_details_session_id,
  properties#>>'{event_details, step}' as properties_event_details_step,
  properties#>>'{event_details, count}' as properties_event_details_count,
  properties#>>'{event_details, domain_count}' as properties_event_details_domain_count,
  properties#>>'{event_details, search_term_count}' as properties_event_details_search_term_count,
  properties#>>'{event_details, study}' as properties_event_details_study,
  properties#>>'{passive-data-metadata, source}' as properties_passive_data_metadata_source,
  properties#>>'{passive-data-metadata, generator}' as properties_passive_data_metadata_generator,
  properties#>>'{passive-data-metadata, timestamp}' as properties_passive_data_metadata_timestamp,
  properties#>>'{passive-data-metadata, generator-id}' as properties_passive_data_metadata_generator_id,
  properties#>>'{passive-data-metadata, encrypted_transmission}' as properties_passive_data_metadata_encrypted_transmission
from
  passive_data_kit_datapoint
where
  generator_identifier = 'pdk-app-event' and
  source <> '13-clean-chickens-ran-quietly';

create table analysis.web_historian as
select
  id,
  source,
  generator,
  created,
  generated_at,
  recorded,
  properties,
  generator_identifier,
  secondary_identifier,
  user_agent,
  server_generated,
  generator_definition_id,
  source_reference_id,
  properties->>'id' as properties_id,
  properties->>'url' as properties_url,
  properties->>'date' as properties_date,
  properties->>'title' as properties_title,
  properties->>'domain' as properties_domain,
  properties->>'protocol' as properties_protocol,
  properties->>'transType' as properties_transType,
  properties->>'refVisitId' as properties_refVisitId,
  properties->>'searchTerms' as properties_searchTerms,
  properties#>>'{passive-data-metadata, source}' as properties_passive_data_metadata_source,
  properties#>>'{passive-data-metadata, generator}' as properties_passive_data_metadata_generator,
  properties#>>'{passive-data-metadata, timestamp}' as properties_passive_data_metadata_timestamp,
  properties#>>'{passive-data-metadata, generator-id}' as properties_passive_data_metadata_generator_id,
  properties#>>'{passive-data-metadata, encrypted_transmission}' as properties_passive_data_metadata_encrypted_transmission
from
  passive_data_kit_datapoint
where
  generator_identifier = 'web-historian' and
  source <> '13-clean-chickens-ran-quietly';

-- create tables with

create table analysis.ambiguous_app_event as
select *
from analysis.app_event
where
  source like '%Email%' or
  source like '%ExternalDataReference%';

create table analysis.ambiguous_web_historian as
select *
from analysis.web_historian
where
  source like '%Email%' or
  source like '%ExternalDataReference%';

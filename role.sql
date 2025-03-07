--Role for users with edit rights.
DROP ROLE IF EXISTS editor;

CREATE ROLE editor
  WITH NOLOGIN NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;

GRANT pg_signal_backend TO editor;

--Role for users with select rights only and rights to create new objects in the database.
DROP ROLE IF EXISTS basic_user;

CREATE ROLE basic_user
  WITH NOLOGIN NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
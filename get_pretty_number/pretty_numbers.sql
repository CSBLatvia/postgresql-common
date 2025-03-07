DROP TABLE IF EXISTS pretty_numbers;

CREATE TABLE pretty_numbers (
  id SERIAL PRIMARY KEY
  , lng CHARACTER VARYING
  , from_value BIGINT
  , to_value BIGINT
  , prefix TEXT
  , suffix TEXT
  , show_decimals SMALLINT
  , multiplier INTEGER);

ALTER TABLE pretty_numbers OWNER TO editor;

GRANT SELECT
  ON TABLE pretty_numbers
  TO basic_user;

INSERT INTO pretty_numbers (
  lng
  , from_value
  , to_value
  , prefix
  , suffix
  , show_decimals
  , multiplier)
VALUES (
  'en'
  , 0
  , 100
  , NULL
  , NULL
  , 0
  , 1)
, (
  'lv'
  , 0
  , 100
  , NULL
  , NULL
  , 0
  , 1)
, (
  'en'
  , 100
  , 100000
  , NULL
  , ' k'
  , 2
  , 1000)
, (
  'lv'
  , 100
  , 100000
  , NULL
  , ' tūkst.'
  , 2
  , 1000)
, (
  'en'
  , 100000
  , 100000000
  , NULL
  , ' m'
  , 2
  , 1000000)
, (
  'lv'
  , 100000
  , 100000000
  , NULL
  , ' milj.'
  , 2
  , 1000000)
, (
  'en'
  , 100000000
  , 999999999999
  , NULL
  , ' bn'
  , 2
  , 1000000000)
, (
  'lv'
  , 100000000
  , 999999999999
  , NULL
  , ' mljrd.'
  , 2
  , 1000000000);
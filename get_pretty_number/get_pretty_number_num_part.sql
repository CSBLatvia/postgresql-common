CREATE OR REPLACE FUNCTION get_pretty_number_num_part(
    lang TEXT,
    input_number NUMERIC)
    RETURNS TEXT
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
    
AS $BODY$
DECLARE
  number_format RECORD;
BEGIN
  SELECT CASE 
      WHEN get_pretty_number(lang, input_number) LIKE '% %'
        THEN LEFT(get_pretty_number(lang, input_number), STRPOS(get_pretty_number(lang, input_number), ' ') - 1)
      ELSE get_pretty_number(lang, input_number)
      END val
  INTO number_format;
  RETURN number_format.val;
END;
$BODY$;
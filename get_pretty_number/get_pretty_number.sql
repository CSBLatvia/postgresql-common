CREATE OR REPLACE FUNCTION get_pretty_number(
    lang TEXT,
    ugly_number NUMERIC)
    RETURNS TEXT
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
    
AS $BODY$
DECLARE
  number_format record;
BEGIN
  --Tabulā pretty_numbers vērtības apakšējā robeža ietilpst intervālā, augšējā neietilpst.
  SELECT
    prefix
    , suffix
    , show_decimals
    , multiplier
  FROM
    pretty_numbers INTO number_format
  WHERE
    from_value <= ugly_number
    AND to_value > ugly_number
    AND lng = lang;
  RETURN CASE 
      WHEN lang LIKE 'lv'
        THEN CONCAT (
            number_format.prefix,
            REPLACE(ROUND(ugly_number / number_format.multiplier, number_format.show_decimals)::TEXT, '.', ','),
            number_format.suffix
            )
      ELSE CONCAT (
          number_format.prefix,
          ROUND(ugly_number / number_format.multiplier, number_format.show_decimals),
          number_format.suffix
          )
      END;
  END;
$BODY$;
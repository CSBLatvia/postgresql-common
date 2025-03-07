--Pārveido R funkcijas atgrieztās klašu robežas atkarībā no klasifikācijas veida.
CREATE OR REPLACE FUNCTION getbreaks_classes_vals(
    vals NUMERIC[],
    classes_arr NUMERIC[],
    class_style TEXT, --classIntervals style values of https://cran.r-project.org/web/packages/classInt/classInt.pdf.
    continuous_breaks BOOLEAN DEFAULT false) --Vai Fisher-Jenks, maksimālu pārtraukumu un kvantiļu klasifikācijās klašu robežām jāsaskaras.
    RETURNS TABLE (val_min NUMERIC, val_max NUMERIC)
    LANGUAGE 'plpgsql'

    COST 100
    IMMUTABLE STRICT 
    
AS $BODY$
DECLARE
  decimal_places INT;
  min_step NUMERIC;

BEGIN

  IF class_style IN (
      'fisher'
      ,'maximum'
      ,'quantile'
      )
    AND continuous_breaks = false THEN --Atgriež tuvākās vērtības datos R funkcijas atgrieztajām vērtībām.

    RETURN query

    WITH classes_arr_all --Apvieno R funkcijas atgrieztās klašu robežas, kas var neatbilst vērtībām datos, ar visām unikālajām datu vertībām.
    AS (
      SELECT UNNEST(classes_arr) val
        ,1 c
      
      UNION
      
      SELECT UNNEST(vals) val
        ,NULL::INT c
      ORDER BY val
      )
      ,t_val_1 --Pievieno kolonnu ar tuvākajām vērtībām. R funkcijas atgrieztajām vērtībām tā atbildīs tuvākajai vērtībai datos.
    AS (
      SELECT val
        ,LAG(val) OVER (
          ORDER BY val
            ,c DESC
          ) AS val_prev
        ,LEAD(val) OVER (
          ORDER BY val
            ,c
          ) AS val_next
        ,c
      FROM classes_arr_all
      )
      ,t_val
    AS (
      SELECT CASE 
          WHEN a.val = a.val_next
            AND b.val_prev IS NOT NULL
            THEN b.val_next --Labo kvantiļu klasifikāciju, lai nākamā klase nesāktos ar to pašu vērtību, ar ko beidzas iepriekšējā.
          ELSE a.val_next
          END val_min_c
        ,LEAD(a.val_prev) OVER (
          ORDER BY a.val
          ) AS val_max_c
      FROM t_val_1 a
      LEFT OUTER JOIN t_val_1 b ON a.val = b.val
        AND b.c IS NULL
      WHERE a.c = 1
      )
    SELECT *
    FROM t_val
    WHERE val_max_c IS NOT NULL;

  ELSE --Atgriež noapaļotas R funkcijas atgrieztās vērtības, kas nepārklājas.

    --Maksimālais decimālzīmju skaits datos noapaļošanai. Aiz komata neņem vērā nulles beigās.
    SELECT MAX(SCALE(TRIM(TRAILING '0' FROM val::TEXT)::NUMERIC))
    INTO decimal_places
    FROM UNNEST(vals) val;

    --Vērtība, ko pieskaitīt augšējai klases robežai, lai noteiktu nākamās klases zemāko robežu.
    SELECT SUM(1 / POWER(10, decimal_places))
    INTO min_step;

    RETURN query

    WITH classes_arr_all --Noapaļo R funkcijas atgrieztās klašu robežas atbilstoši datos esošajam maksimālajam decimālzīmju skaitam.
    AS (
      SELECT ROUND(val, decimal_places) val
      FROM UNNEST(classes_arr) val
      )
      ,t_val
    AS (
      SELECT CASE 
          WHEN LAG(val) OVER (
              ORDER BY val
              ) IS NULL
            THEN val
          ELSE val + min_step
          END val_min_c
        ,LEAD(val) OVER (
          ORDER BY val
          ) AS val_max_c
      FROM classes_arr_all
      )
    SELECT *
    FROM t_val
    WHERE val_max_c IS NOT NULL
      AND val_max_c >= val_min_c; --Exclude empty classes.
  END IF;

END;
$BODY$;
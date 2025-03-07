CREATE OR REPLACE FUNCTION getbreaks_classes(
    vals NUMERIC[],
    classes INTEGER DEFAULT 5, --Max classes to return.
    threshold TEXT DEFAULT 'none', --Bipolar if 'avg' or numeric value.
    class_style TEXT DEFAULT 'fisher', --classIntervals style values of https://cran.r-project.org/web/packages/classInt/classInt.pdf. 'fisher', 'maximum', 'equal', 'quantile' currently supported.
    gvf_limit NUMERIC DEFAULT 0.95, --Max goodness of variance fit.
    max_vals INTEGER DEFAULT 2147483647, --Number of values at which the specified maximum number of classes is accepted as the number of classes to be returned.
    continuous_breaks BOOLEAN DEFAULT false) --If class breaks should be continuous in Fisher-Jenks, maximum and quantile classifications.
    RETURNS json
    LANGUAGE 'plpgsql'

    COST 100
    IMMUTABLE STRICT 
    
AS $BODY$
DECLARE
  dstvals NUMERIC;
  threshold_num NUMERIC;
  vals_lower NUMERIC[];
  vals_upper NUMERIC[];
  classes_arr NUMERIC [];
  arr_upper json;
  arr_lower json;
  classes_json json;

BEGIN

  SELECT COUNT(DISTINCT a)
  INTO dstvals
  FROM UNNEST(vals) AS a;

  IF dstvals = 0
    OR classes > 5
    OR class_style NOT IN (
      'fisher'
      ,'maximum'
      ,'equal'
      ,'quantile'
      ) THEN
    RETURN NULL;
  END IF;

  IF threshold LIKE 'none' THEN --Sliekšņa vērtība nav norādīta.
    IF dstvals <= 2 THEN --Unikālo vērtību skaits, līdz kuram katra vērtība veido atsevišķu klasi. Minimālā norādāmā vērtība 1.
      WITH vals_distinct
      AS (
        SELECT DISTINCT UNNEST(vals) val
        ORDER BY val
        )
      SELECT json_build_object('lower', NULL, 'threshold', NULL, 'upper', json_agg(json_build_array(val, val)))
      INTO classes_json
      FROM vals_distinct;
    ELSE
      classes_arr:= getbreaks(vals, classes, class_style, gvf_limit, max_vals);
      SELECT json_build_object('lower', NULL, 'threshold', NULL, 'upper', json_agg(arr))
      INTO classes_json
      FROM (
        SELECT json_build_array(val_min, val_max) AS arr
        FROM getbreaks_classes_vals(vals, classes_arr, class_style, continuous_breaks)
        ORDER BY val_min
        ) a;
    END IF;

  ELSIF threshold LIKE 'avg' THEN --Sliekšņa vērtība kā vidējā vērtība no datu kopas.
    SELECT ROUND(AVG(a), MAX(SCALE(a))) INTO threshold_num FROM UNNEST(vals) a;
    IF threshold_num IN (
    SELECT a
    FROM UNNEST(vals) AS a
    ) THEN
      --Ja sliekšņa vērtība ir datu kopā, sadala vals vals_lower un vals_upper, slieksni izdala atsevišķi.
      vals_lower:= array_agg(a)
      FROM UNNEST(vals) a
      WHERE a < threshold_num;
      vals_upper:= array_agg(a)
      FROM UNNEST(vals) a
      WHERE a > threshold_num;

      SELECT COUNT(DISTINCT a)
      INTO dstvals
      FROM UNNEST(vals_lower) AS a;
      IF dstvals <= 2 THEN --Unikālo vērtību skaits, līdz kuram katra vērtība veido atsevišķu klasi. Minimālā norādāmā vērtība 1.
        WITH vals_distinct
        AS (
          SELECT DISTINCT UNNEST(vals_lower) val
          ORDER BY val
          )
        SELECT json_agg(json_build_array(val, val))
        INTO arr_lower
        FROM vals_distinct;
      ELSE
        classes_arr:= getbreaks(vals_lower, classes, class_style, gvf_limit, max_vals);
        SELECT json_agg(arr)
        INTO arr_lower
        FROM (
          SELECT json_build_array(val_min, val_max) AS arr
          FROM getbreaks_classes_vals(vals_lower, classes_arr, class_style, continuous_breaks)
          ORDER BY val_min
          ) a;
      END IF;

      SELECT COUNT(DISTINCT a)
      INTO dstvals
      FROM UNNEST(vals_upper) AS a;
      IF dstvals <= 2 THEN --Unikālo vērtību skaits, līdz kuram katra vērtība veido atsevišķu klasi. Minimālā norādāmā vērtība 1.
        WITH vals_distinct
        AS (
          SELECT DISTINCT UNNEST(vals_upper) val
          ORDER BY val
          )
        SELECT json_agg(json_build_array(val, val))
        INTO arr_upper
        FROM vals_distinct;
      ELSE
        classes_arr:= getbreaks(vals_upper, classes, class_style, gvf_limit, max_vals);
        SELECT json_agg(arr)
        INTO arr_upper
        FROM (
          SELECT json_build_array(val_min, val_max) AS arr
          FROM getbreaks_classes_vals(vals_upper, classes_arr, class_style, continuous_breaks)
          ORDER BY val_min
          ) a;
      END IF;

      SELECT json_build_object('lower', arr_lower, 'threshold', threshold_num, 'upper', arr_upper)
      INTO classes_json;

    ELSE
      --Ja sliekšņa vērtības nav datu kopā, sadala vals vals_lower un vals_upper.
      vals_lower:= array_agg(a)-- || array_agg(threshold_num) --Ietver slieksni.
      FROM UNNEST(vals) a
      WHERE a < threshold_num;
      vals_upper:= array_agg(a)
      FROM UNNEST(vals) a
      WHERE a > threshold_num;

      SELECT COUNT(DISTINCT a)
      INTO dstvals
      FROM UNNEST(vals_lower) AS a;
      IF dstvals <= 2 THEN --Unikālo vērtību skaits, līdz kuram katra vērtība veido atsevišķu klasi. Minimālā norādāmā vērtība 1.
        WITH vals_distinct
        AS (
          SELECT DISTINCT UNNEST(vals_lower) val
          ORDER BY val
          )
        SELECT json_agg(json_build_array(val, val))
        INTO arr_lower
        FROM vals_distinct;
      ELSE
        classes_arr:= getbreaks(vals_lower, classes, class_style, gvf_limit, max_vals);
        SELECT json_agg(arr)
        INTO arr_lower
        FROM (
          SELECT json_build_array(val_min, val_max) AS arr
          FROM getbreaks_classes_vals(vals_lower, classes_arr, class_style, continuous_breaks)
          ORDER BY val_min
          ) a;
      END IF;

      SELECT COUNT(DISTINCT a)
      INTO dstvals
      FROM UNNEST(vals_upper) AS a;
      IF dstvals <= 2 THEN --Unikālo vērtību skaits, līdz kuram katra vērtība veido atsevišķu klasi. Minimālā norādāmā vērtība 1.
        WITH vals_distinct
        AS (
          SELECT DISTINCT UNNEST(vals_upper) val
          ORDER BY val
          )
        SELECT json_agg(json_build_array(val, val))
        INTO arr_upper
        FROM vals_distinct;
      ELSE
        classes_arr:= getbreaks(vals_upper, classes, class_style, gvf_limit, max_vals);
        SELECT json_agg(arr)
        INTO arr_upper
        FROM (
          SELECT json_build_array(val_min, val_max) AS arr
          FROM getbreaks_classes_vals(vals_upper, classes_arr, class_style, continuous_breaks)
          ORDER BY val_min
          ) a;
      END IF;

      SELECT json_build_object('lower', arr_lower, 'threshold', NULL, 'upper', arr_upper)
      INTO classes_json;

    END IF;
  ELSE
    threshold_num:= threshold::NUMERIC;
    --Norādītā sliekšņa vērtība ir datu kopas ietvaros, bet nesakrīt ar minimālo un maksimālo vērtību.
    IF threshold_num > (SELECT MIN(a)
    FROM UNNEST(vals) AS a) AND threshold_num < (SELECT MAX(a)
    FROM UNNEST(vals) AS a) THEN
    IF threshold_num IN (
    SELECT a
    FROM UNNEST(vals) AS a
    ) THEN
      --Ja sliekšņa vērtība ir datu kopā, sadala vals vals_lower un vals_upper, slieksni izdala atsevišķi.
      vals_lower:= array_agg(a)
      FROM UNNEST(vals) a
      WHERE a < threshold_num;
      vals_upper:= array_agg(a)
      FROM UNNEST(vals) a
      WHERE a > threshold_num;

      SELECT COUNT(DISTINCT a)
      INTO dstvals
      FROM UNNEST(vals_lower) AS a;
      IF dstvals <= 2 THEN --Unikālo vērtību skaits, līdz kuram katra vērtība veido atsevišķu klasi. Minimālā norādāmā vērtība 1.
        WITH vals_distinct
        AS (
          SELECT DISTINCT UNNEST(vals_lower) val
          ORDER BY val
          )
        SELECT json_agg(json_build_array(val, val))
        INTO arr_lower
        FROM vals_distinct;
      ELSE
        classes_arr:= getbreaks(vals_lower, classes, class_style, gvf_limit, max_vals);
        SELECT json_agg(arr)
        INTO arr_lower
        FROM (
          SELECT json_build_array(val_min, val_max) AS arr
          FROM getbreaks_classes_vals(vals_lower, classes_arr, class_style, continuous_breaks)
          ORDER BY val_min
          ) a;
      END IF;

      SELECT COUNT(DISTINCT a)
      INTO dstvals
      FROM UNNEST(vals_upper) AS a;
      IF dstvals <= 2 THEN --Unikālo vērtību skaits, līdz kuram katra vērtība veido atsevišķu klasi. Minimālā norādāmā vērtība 1.
        WITH vals_distinct
        AS (
          SELECT DISTINCT UNNEST(vals_upper) val
          ORDER BY val
          )
        SELECT json_agg(json_build_array(val, val))
        INTO arr_upper
        FROM vals_distinct;
      ELSE
        classes_arr:= getbreaks(vals_upper, classes, class_style, gvf_limit, max_vals);
        SELECT json_agg(arr)
        INTO arr_upper
        FROM (
          SELECT json_build_array(val_min, val_max) AS arr
          FROM getbreaks_classes_vals(vals_upper, classes_arr, class_style, continuous_breaks)
          ORDER BY val_min
          ) a;
      END IF;

      SELECT json_build_object('lower', arr_lower, 'threshold', threshold_num, 'upper', arr_upper)
      INTO classes_json;

    ELSE
      --Ja sliekšņa vērtības nav datu kopā, sadala vals vals_lower un vals_upper.
      vals_lower:= array_agg(a)-- || array_agg(threshold_num) --Ietver slieksni.
      FROM UNNEST(vals) a
      WHERE a < threshold_num;
      vals_upper:= array_agg(a)
      FROM UNNEST(vals) a
      WHERE a > threshold_num;

      SELECT COUNT(DISTINCT a)
      INTO dstvals
      FROM UNNEST(vals_lower) AS a;
      IF dstvals <= 2 THEN --Unikālo vērtību skaits, līdz kuram katra vērtība veido atsevišķu klasi. Minimālā norādāmā vērtība 1.
        WITH vals_distinct
        AS (
          SELECT DISTINCT UNNEST(vals_lower) val
          ORDER BY val
          )
        SELECT json_agg(json_build_array(val, val))
        INTO arr_lower
        FROM vals_distinct;
      ELSE
        classes_arr:= getbreaks(vals_lower, classes, class_style, gvf_limit, max_vals);
        SELECT json_agg(arr)
        INTO arr_lower
        FROM (
          SELECT json_build_array(val_min, val_max) AS arr
          FROM getbreaks_classes_vals(vals_lower, classes_arr, class_style, continuous_breaks)
          ORDER BY val_min
          ) a;
      END IF;

      SELECT COUNT(DISTINCT a)
      INTO dstvals
      FROM UNNEST(vals_upper) AS a;
      IF dstvals <= 2 THEN --Unikālo vērtību skaits, līdz kuram katra vērtība veido atsevišķu klasi. Minimālā norādāmā vērtība 1.
        WITH vals_distinct
        AS (
          SELECT DISTINCT UNNEST(vals_upper) val
          ORDER BY val
          )
        SELECT json_agg(json_build_array(val, val))
        INTO arr_upper
        FROM vals_distinct;
      ELSE
        classes_arr:= getbreaks(vals_upper, classes, class_style, gvf_limit, max_vals);
        SELECT json_agg(arr)
        INTO arr_upper
        FROM (
          SELECT json_build_array(val_min, val_max) AS arr
          FROM getbreaks_classes_vals(vals_upper, classes_arr, class_style, continuous_breaks)
          ORDER BY val_min
          ) a;
      END IF;

      SELECT json_build_object('lower', arr_lower, 'threshold', NULL, 'upper', arr_upper)
      INTO classes_json;
      
    END IF;
    --Norādītā sliekšņa vērtība sakrīt ar datu kopas minimālo vērtību.
    ELSIF threshold_num = (SELECT MIN(a)
    FROM UNNEST(vals) AS a) THEN
      vals:= array_remove(vals, threshold_num);
      SELECT COUNT(DISTINCT a)
      INTO dstvals
      FROM UNNEST(vals) AS a;
      IF dstvals <= 2 THEN --Unikālo vērtību skaits, līdz kuram katra vērtība veido atsevišķu klasi. Minimālā norādāmā vērtība 1.
        WITH vals_distinct
        AS (
          SELECT DISTINCT UNNEST(vals) val
          ORDER BY val
          )
        SELECT json_build_object('lower', NULL, 'threshold', threshold_num, 'upper', json_agg(json_build_array(val, val)))
        INTO classes_json
        FROM vals_distinct;
      ELSE
        classes_arr:= getbreaks(vals, classes, class_style, gvf_limit, max_vals);
        SELECT json_build_object('lower', NULL, 'threshold', threshold_num, 'upper', json_agg(arr))
        INTO classes_json
        FROM (
          SELECT json_build_array(val_min, val_max) AS arr
          FROM getbreaks_classes_vals(vals, classes_arr, class_style, continuous_breaks)
          ORDER BY val_min
          ) a;
      END IF;

    --Norādītā sliekšņa vērtība sakrīt ar datu kopas maksimālo vērtību.
    ELSIF threshold_num = (SELECT MAX(a)
    FROM UNNEST(vals) AS a) THEN
      vals:= array_remove(vals, threshold_num);
      SELECT COUNT(DISTINCT a)
      INTO dstvals
      FROM UNNEST(vals) AS a;
      IF dstvals <= 2 THEN --Unikālo vērtību skaits, līdz kuram katra vērtība veido atsevišķu klasi. Minimālā norādāmā vērtība 1.
        WITH vals_distinct
        AS (
          SELECT DISTINCT UNNEST(vals) val
          ORDER BY val
          )
        SELECT json_build_object('lower', json_agg(json_build_array(val, val)), 'threshold', threshold_num, 'upper', NULL)
        INTO classes_json
        FROM vals_distinct;
      ELSE
        classes_arr:= getbreaks(vals, classes, class_style, gvf_limit, max_vals);
        SELECT json_build_object('lower', json_agg(arr), 'threshold', threshold_num, 'upper', NULL)
        INTO classes_json
        FROM (
          SELECT json_build_array(val_min, val_max) AS arr
          FROM getbreaks_classes_vals(vals, classes_arr, class_style, continuous_breaks)
          ORDER BY val_min
          ) a;
      END IF;

    ELSE --Ja norādītā sliekšņa vērtība nav datu kopas ietvaros, atgriež kā bez sliekšņa.
      IF dstvals <= 2 THEN --Unikālo vērtību skaits, līdz kuram katra vērtība veido atsevišķu klasi. Minimālā norādāmā vērtība 1.
        IF threshold_num > (SELECT MAX(a)
        FROM UNNEST(vals) AS a) THEN
          WITH vals_distinct
          AS (
            SELECT DISTINCT UNNEST(vals) val
            ORDER BY val
            )
          SELECT json_build_object('lower', json_agg(json_build_array(val, val)), 'threshold', NULL, 'upper', NULL)
          INTO classes_json
          FROM vals_distinct;
        ELSE
          WITH vals_distinct
          AS (
            SELECT DISTINCT UNNEST(vals) val
            ORDER BY val
            )
          SELECT json_build_object('lower', NULL, 'threshold', NULL, 'upper', json_agg(json_build_array(val, val)))
          INTO classes_json
          FROM vals_distinct;
        END IF;
      ELSE
        classes_arr:= getbreaks(vals, classes, class_style, gvf_limit, max_vals);
        IF threshold_num > (SELECT MAX(a)
        FROM UNNEST(vals) AS a) THEN
          SELECT json_build_object('lower', json_agg(arr), 'threshold', NULL, 'upper', NULL)
          INTO classes_json
          FROM (
            SELECT json_build_array(val_min, val_max) AS arr
            FROM getbreaks_classes_vals(vals, classes_arr, class_style, continuous_breaks)
            ORDER BY val_min
            ) a;
        ELSE
          SELECT json_build_object('lower', NULL, 'threshold', NULL, 'upper', json_agg(arr))
          INTO classes_json
          FROM (
            SELECT json_build_array(val_min, val_max) AS arr
            FROM getbreaks_classes_vals(vals, classes_arr, class_style, continuous_breaks)
            ORDER BY val_min
            ) a;
        END IF;
      END IF;
    END IF;
  END IF;

  RETURN classes_json;
END;
$BODY$;
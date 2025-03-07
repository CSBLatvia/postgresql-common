CREATE OR REPLACE FUNCTION getbreaks(
    vals NUMERIC [],
    classes INTEGER,
    class_style TEXT DEFAULT 'fisher',
    gvf_limit NUMERIC DEFAULT 0.95,
    max_vals INTEGER DEFAULT 2147483647)
    RETURNS NUMERIC []
    LANGUAGE 'plr'

    COST 100
    IMMUTABLE STRICT

AS $BODY$
library(classInt)

set.seed(1)
ci_brks <- classIntervals(vals,n=classes,style=class_style,intervalClosure='right',warnLargeN=F)$brks
num_vals <- length(vals)

if (num_vals >= max_vals) {
  return(ci_brks)
} else {
  ci_cuts <- .bincode(vals, ci_brks, right = T, include.lowest = F)
  gvf <- classInt:::gvf(vals, ci_cuts)

  while (classes > 2 & gvf >= gvf_limit) {
    cat("classes:", classes,"; gvf:", gvf, "\n")

    classes <- classes - 1
    set.seed(1)
    ci_brks_new <- classIntervals(vals,n=classes,style=class_style,intervalClosure='right',warnLargeN=F)$brks
    ci_cuts <- .bincode(vals, ci_brks_new, right = T, include.lowest = F)
    gvf <- classInt:::gvf(vals, ci_cuts)
    
    if (gvf >= gvf_limit) ci_brks <- ci_brks_new
    
  }

  return(ci_brks)
}
$BODY$;
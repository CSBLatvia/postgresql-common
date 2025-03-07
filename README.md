# PostgreSQL objects shared across the repositories of Central Statistical Bureau of Latvia

[role.sql](role.sql) - create roles.

## Functions

### get_pretty_number

Returns more readable numbers.

[pretty_numbers.sql](get_pretty_number/pretty_numbers.sql) - table with values required to execute the function.

[get_pretty_number](get_pretty_number/get_pretty_number.sql) - function.

[get_pretty_number_num_part](get_pretty_number/get_pretty_number_num_part.sql) - function that returns the numeric part of the result produced by the function [get_pretty_number](get_pretty_number.sql). Can be used to determine grammatical cases in Latvian.

### getbreaks_classes

Returns class breaks as intervals for choropleth maps, using the optimal number of classes (goodness of variance fit (GVF) value is at least the defined one (by default 0.95) or the specified maximum number of classes), computed using the R package [classInt](https://cran.r-project.org/web/packages/classInt/index.html) (fisher, maximum, equal, and quantile styles supported). By defining the threshold, it is possible to obtain class intervals for bipolar choropleth maps (below threshold, threshold, and above threshold returned).

[getbreaks_classes.sql](getbreaks_classes/getbreaks_classes.sql) - function that returns class breaks as intervals. It uses helper function [getbreaks_classes_vals.sql](getbreaks_classes/getbreaks_classes_vals.sql) that transforms the class boundaries returned by the PL/R function depending on the classification style.

[getbreaks.sql](getbreaks_classes/getbreaks.sql) - PL/R function that returns class breaks. It is used by [getbreaks_classes.sql](getbreaks_classes/getbreaks_classes.sql).
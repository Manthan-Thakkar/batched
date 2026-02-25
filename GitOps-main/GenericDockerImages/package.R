
# Project Setup: Package Installation

package_list <- c(
"tidyverse",
"config",
"DBI",
"odbc",
"bizdays",
"readxl",
"dplyr",
"purrr",
"stringr",
"tidyr",
"lubridate",
"rlang",
"magrittr",
"stringi",
"plumber",
"httr",
"uuid",
"R6",
"tibble",
"stringi",
"data.table",
"jsonlite"
)


install.packages(unique(package_list), dependencies = TRUE, repos = "http://cran.us.r-project.org", Ncpus = 4)

rm(package_list)
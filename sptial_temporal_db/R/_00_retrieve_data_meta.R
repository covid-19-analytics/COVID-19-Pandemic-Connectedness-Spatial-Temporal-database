
# NOTE: -------------------------------------------------------------------------------
# *************************************************************************************
# [_00_retrieve_data_meta.R]: Retrieve airport meta information by valid ICAO format 
# *************************************************************************************

# *** Reminder: Please create a folder named "raw_data" under the project root ***

# =====================================================================
# Load library --------------------------------------------------------

library(dplyr)

library(stringr)
library(readr)

library(httr)

library(jsonlite)

library(here)

# =====================================================================
# Basic setup ---------------------------------------------------------

'%ni%' <- Negate('%in%')

proj_name <- ""

# =====================================================================
# Actual download of the CAPSCA airport metadata ---------------------

target_link <- "https://quips.anbdata.com/project/dev/5c1c21b205c09f70bfe60eeeeb46316af89506e9/render?callback=jQuery214046692707472108486_1601784801747"

r <- httr::GET(target_link)
tmp_html <- httr::content(r, "text", encoding= "UTF-8")
rm(r)

# Convert the AJAX rendered HTML into data.frame ----------
tmp_html %>%
  gsub("^.*(airportData=)", "", .) %>%
  gsub("(}]).*$", "}]", .) %>%
  gsub("(\\\\)", "", .) %>%
  jsonlite::fromJSON(., flatten= TRUE) -> df_meta
rm(tmp_html)

# =====================================================================
# Data cleansing ------------------------------------------------------

# Filter columns "geometry.type", "geometry.coordinates" ----------
#   duplicated/ not required info 
df_meta <- df_meta %>%
  dplyr::select(-c("geometry.type", "geometry.coordinates"))

# Rearrange the columns order for better readability ----------
df_meta <- df_meta %>% 
  dplyr::select(
    "countryName", "countryCode", "airportName", "airportCode", "cityName", "latitude", "longitude") %>% 
  dplyr::arrange(countryCode, airportCode) %>%
  tibble::as_tibble()

# Filter by ICAO code format ----------
df_ICAO_meta <- df_meta %>% 
  dplyr::filter(str_length(airportCode)==4) %>%
  dplyr::filter(!grepl("[0-9]", str_sub(airportCode, 1, 1)))

# Manually added back the city name of one airport ----------
df_ICAO_meta <- df_ICAO_meta %>%
  dplyr::mutate(cityName= ifelse(is.na(cityName), "Nan", cityName))

# =====================================================================
# Store data.frame into .csv format -----------------------------------
write_csv(df_ICAO_meta, here::here(proj_name, "raw_data", "ICAO_airport_meta.csv"))

# =====================================================================






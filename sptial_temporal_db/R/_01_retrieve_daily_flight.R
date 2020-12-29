
# NOTE: -------------------------------------------------------------------------------
# *************************************************************************************
# [_01_retrieve_daily_flight.R]: Retrieve daily flights data (airport-airport) 
# *************************************************************************************

# *** Reminder: Make sure ran the program [_00_retrieve_data_meta.R] ***
# *** Reminder: Please create a folder named "flights" inside the folder "raw_data" for temporary storage ***

# =====================================================================
# Load library --------------------------------------------------------

library(dplyr)
library(stringr)
library(readr)

library(lubridate)

library(urltools)
library(jsonlite)

library(here)

# =====================================================================
# Basic Setup ---------------------------------------------------------

proj_name <- ""

# Do you need to download the latest flight data? ----------
flag_download <- TRUE
# flag_download <- FALSE

"%ni%" = Negate("%in%")

# Data range ----------
fromDate <- "2019-01-01" # our program default date (min: "2017-07-01)
toDate <- as.character(today())

# =====================================================================
# Note(s) -------------------------------------------------------------

# Ref: CAPSCA (Interactive dashboard query) ----------
# https://api.anbdata.com/anb/app/who/getdeparture_stat?fromDate=2020-03-01&toDate=2020-03-31&airports[]=KLAX

# Input(s) ---------- 
# fromDate=YYYY-MM-DD
# toDate=YYYY-MM-DD
# airports[]=ICAO_Airport_Code

# =====================================================================
# Custom function(s) --------------------------------------------------

# cust_func: download_flight_data() ----------
download_flight_data <- function(
  fromDate, toDate, airportCode, proj_name, retrieved_on) {
  
  # cat(rep("-", 10), airportCode, rep("-", 10), "\n")
  
  l_params <- list(
    "fromDate"= fromDate, "toDate"= toDate)
  url_params <- paste(names(l_params), l_params, sep="=", collapse= "&")
  
  target_airports <- airportCode
  
  key_query <- paste0("airports[]=", target_airports, collapse= "&")
  target_url <- sprintf("https://api.anbdata.com/anb/app/who/getdeparture_stat?&%s&%s",
                        url_params, key_query)
  print(target_url)
  
  tmp_file <- here::here(proj_name, "raw_data", "flights", 
                         sprintf("%s_%s_%s.json", airportCode, fromDate, ymd(toDate)-1))
  
  df_log <- data.frame(
    fromDate= fromDate, toDate= toDate, 
    airportCode= target_airports, proj_name= proj_name, retrieved_on= as.character(today()), 
    stringsAsFactors= FALSE)
  
  tryCatch({
    cat(rep("-", 10), airportCode, rep("-", 10), "\n")
    
    # Download specified airport flights data (JSON format) ---------
    download.file(
      target_url, destfile= tmp_file, quiet= TRUE)
    
    # Give a little pause between downloads ----------
    Sys.sleep(0.5)
    
    df_log$flag_success <- TRUE
    
  },
  error= function(e) {
    message(sprintf("Error: %s", e))
    
    df_log$flag_success <- FALSE
    
  },
  warning= function(w) {
    message(sprintf("Warning: %s", w))
    
    df_log$flag_success <- FALSE
  }, finally= {})
  
  return(df_log)
  
}

# =====================================================================
# Read list of airports (ICAO) -----------------------------------------------

ICAO_airport_meta <- read_csv(here::here(proj_name, "raw_data", "ICAO_airport_meta.csv"))

# =====================================================================
# Download the daily flight data by list of airport codes -------------

if (flag_download==TRUE) {
  
  selected_airports <- ICAO_airport_meta$airportCode
  tmp_n <- length(selected_airports)
  v_i <- seq(tmp_n)
  
  for (i in v_i) {
    acode <- selected_airports[i]
    
    cat("\n", rep("-", 10), i, " / ", tmp_n, 
        sprintf("[%s]", acode), rep("-", 10), "\n")
    
    tmp <- download_flight_data(
      fromDate= fromDate, toDate= toDate, 
      airportCode= acode, proj_name= proj_name, retrieved_on= as.character(today()))
  }
  
} else {}

# =====================================================================
# Retrieve the daily flight data by list of airport codes -------------

v_acode <- ICAO_airport_meta$airportCode %>% unique() %>% sort()

v_i <- seq(length(v_acode))

l_flight <- list()
for (i in v_i) {
  # cat(rep("-", 10), i, rep("-", 10), "\n")
  
  tmp_acode <- v_acode[i]
  
  tmp_from <- fromDate
  tmp_to <- ymd(toDate)-1
  
  tmp_lines <- readLines(
    here::here(proj_name, "raw_data", "flights",
               sprintf("%s_%s_%s.json", tmp_acode, tmp_from, tmp_to))
    , warn= FALSE)
  
  tmp_str <- paste(tmp_lines, collapse= "")
  
  # check weird json file, that contains incompleted centent ----------
  if (length(tmp_lines)>2 & substr(tmp_str, str_length(tmp_str), str_length(tmp_str))!="]") {
    
    cat(rep("-", 10), i, " [", tmp_acode, "] ", rep("-", 10), "\n")
    print(substr(tmp_str, 1, 10))
    print(substr(tmp_str, str_length(tmp_str), str_length(tmp_str)))
    
    cat("incompleted LIST\n")
    
  } else {
    tmp_df <- jsonlite::fromJSON(tmp_str, flatten= TRUE)
    
    if (length(tmp_df)==0) {
      # cat("empty LIST\n")
    } else {
      
      lapply(seq(nrow(tmp_df)), function(idx) {
        obj <- tmp_df[idx, ]
        
        n_records <- length(obj$airportList[[1]])
        
        if (n_records>0) {
          al <- obj$airportList
          
          al$date = unique(obj$`_id.date`)
          al$orig_airportCode = unique(obj$`_id.orig`)
          
        } else {
          al <- NULL
        }
        
        return(al)
      }) -> l_tmp
      
      df_part <- do.call("rbind", l_tmp)
      
      l_flight <- append(l_flight, list(df_part))
    }
    
  }
  
}

df_selected_flight <- do.call("rbind", l_flight)

# =====================================================================
# Data cleansing and Aggregation --------------------------------------

colnames(df_selected_flight) <- c("airportList", "date", "orig_airportCode")

df_selected_flight <- as_tibble(df_selected_flight) %>% tidyr::unnest(
  .id= c("date", "orig_airportCode"),
  cols = c(airportList, date, orig_airportCode))

df_selected_flightX <- df_selected_flight %>% 
  dplyr::mutate(date= ymd(date)) %>%
  dplyr::rename(
    dest_airportCode= airport,
    num_flight= count,
    dest_countryName= countryName)

# Add back destination details ----------
df_selected_flightX <- dplyr::select(
  ICAO_airport_meta, c(countryCode, airportCode, cityName)) %>%
  
  dplyr::rename(
    dest_countryCode= countryCode, 
    dest_cityName= cityName
  ) %>%
  left_join(df_selected_flightX, ., by= c("dest_airportCode"="airportCode"))

# Add back origin details ----------
df_selected_flightX <- dplyr::select(
  ICAO_airport_meta, c(countryName, countryCode, airportCode, cityName)) %>%
  
  dplyr::rename(
    orig_countryName= countryName, 
    orig_countryCode= countryCode, 
    orig_cityName= cityName
  ) %>%
  left_join(df_selected_flightX, ., by= c("orig_airportCode"="airportCode"))

# Rearrange the columns order ----------
df_selected_flightX <- df_selected_flightX %>%
  dplyr::select(c(date, num_flight, starts_with("orig_"), starts_with("dest_")))

df_selected_flightX <- df_selected_flightX %>% 
  dplyr::arrange(date, orig_countryCode, dest_countryCode)

# Load ICAO airport meta ----------
ICAO_airport_meta <- read_csv(here::here(proj_name, "raw_data", "ICAO_airport_meta.csv"))

# Aggregate the spatial meta ----------
df_selected_flightX <- ICAO_airport_meta %>% 
  dplyr::select(airportCode, airportName, latitude, longitude) %>%
  
  dplyr::rename(
    orig_airportName= airportName, 
    orig_latitude= latitude, 
    orig_longitude= longitude
  ) %>%
  left_join(df_selected_flightX, ., by= c("orig_airportCode"="airportCode"))

df_selected_flightX <- ICAO_airport_meta %>% 
  dplyr::select(airportCode, airportName, latitude, longitude) %>%
  
  dplyr::rename(
    dest_airportName= airportName, 
    dest_latitude= latitude, 
    dest_longitude= longitude
  ) %>%
  left_join(df_selected_flightX, ., by= c("dest_airportCode"="airportCode"))

df_selected_flightX <- df_selected_flightX %>%
  dplyr::select(
    date, num_flight, 
    orig_airportCode, orig_airportName, orig_countryCode, orig_countryName, 
    orig_cityName, orig_latitude, orig_longitude, 
    dest_airportCode, dest_airportName, dest_countryCode, dest_countryName, 
    dest_cityName, dest_latitude, dest_longitude)

# Filter by the ICAO valid airport codes ----------
df_selected_flightX <- df_selected_flightX %>%
  dplyr::filter(
    orig_airportCode %in% ICAO_airport_meta$airportCode & 
      dest_airportCode %in% ICAO_airport_meta$airportCode)


write_csv(df_selected_flightX,
          here::here(proj_name, "raw_data",
                     sprintf("flight_%s_%s.csv", fromDate, toDate)))

# =====================================================================






# NOTE: -------------------------------------------------------------------------------
# *************************************************************************************
# [_02_construct_network.R]: Construct dynamic travel network (country-country)
# *************************************************************************************

# *** Reminder: Make sure ran the program [00] and [01] ***
# *** Reminder: Please create a folder named "RData" under the project root for temporary storage ***

# ==============================================================
# Load library -------------------------------------------------

library(dplyr)
library(readr)

library(lubridate)

library(igraph)

# ==============================================================
# Setup --------------------------------------------------------

# Set Reproducible seed ----------
seed <- 1010
set.seed(seed)

proj_name <- ""

`%ni%` <- Negate(`%in%`)

target_date <- "2020-12-03"

# ==============================================================
# Note/ Reminder -----------------------------------------------

# Ref: http://quips.anbdata.com/project/dev/5c1c21b205c09f70bfe60eeeeb46316af89506e9.html
# According to the CAPSCA note: 
#   due to a technical problem, no data is available for the period from 13 July to 21 July. 
#   All statistics presented including that time period should not be used.

# ==============================================================
# Network construction -----------------------------------------

df_flight <- read_csv(
  here::here(proj_name, "raw_data", 
             sprintf("flight_2019-01-01_%s.csv", target_date)))

tmp_flightX <- df_flight %>%
  dplyr::select(date, orig_countryCode, dest_countryCode) %>%
  dplyr::filter(year(date)==2020)

v_date <- tmp_flightX$date %>% unique()

# ------------------------------------------------------------------

# Directed network ----------
l_gD <- lapply(seq(length(v_date)), function(idx) {
  
  # cat(rep("-", 10), idx, rep("-", 10), "\n")
  
  tmp_date <- v_date[idx]
  
  tmp_df <- tmp_flightX %>%
    dplyr::filter(date==tmp_date) %>%
    dplyr::select(orig_countryCode, dest_countryCode) %>% unique()
  
  # Directed network used ********
  tmp_g <- igraph::graph_from_data_frame(tmp_df, directed= TRUE) %>%
    igraph::simplify(remove.multiple= TRUE, remove.loops= TRUE)
  
  return(tmp_g)
})


# Undirected network ----------
l_gU <- lapply(l_gD, function(g) {
  tmp_g <- igraph::as.undirected(g) %>%
    igraph::simplify(remove.multiple= TRUE, remove.loops= TRUE)
  
  return(tmp_g)
})

save(list= c("v_date", "l_gD", "l_gU"), file= here::here(proj_name, "RData", "l_graph.RData"))

# # =============================================================
# # Optional codes ----------------------------------------------
# 
# # Convert the graph object into Origin-Destination matrix ----------
# g <- l_gU[[1]]
# OD_matrix <- igraph::as_adjacency_matrix(g, type= "both", sparse= TRUE)
# 
# # Compute the degree matrix ----------
# degree_matrix <- matrix(data= NA, nrow= nrow(OD_matrix), ncol= nrow(OD_matrix))
# dimnames(degree_matrix) <- list(colnames(OD_matrix), colnames(OD_matrix))
# diag(degree_matrix) <- colSums(as.matrix(OD_matrix), na.rm= TRUE)

# ====================================================================


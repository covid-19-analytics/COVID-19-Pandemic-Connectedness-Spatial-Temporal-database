
# NOTE: -------------------------------------------------------------------------------
# *************************************************************************************
# [_03_calculate_stats.R]: Calculate network statistics 
# *************************************************************************************

# *** Reminder: Make sure ran the program [00], [01], and [02] ***

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

# ==============================================================
# Load constructed networks ------------------------------------

load(here::here(proj_name, "RData", "l_graph.RData"))

# ==============================================================
# Network statistics -------------------------------------------

lapply(seq(length(v_date)), function(idx) {
  tmp_date <- v_date[idx]
  
  tmp_gD <- l_gD[[idx]]
  tmp_gU <- l_gU[[idx]]
  
  tmp_df <- data.frame(date= tmp_date,
                       stringsAsFactors= FALSE)
  
  tmp_df$V_t <- length(V(tmp_gU)) # num_node
  tmp_df$E_t <- gsize(tmp_gU) # num_edge
  tmp_df$D_t <- edge_density(tmp_gU, loops= FALSE) # edge_density
  tmp_df$R_t <- reciprocity(tmp_gD, ignore.loops= TRUE, mode= "ratio") # reciprocity
  
  return(tmp_df)
  
}) -> l_netStat

df_netStat <- do.call("rbind", l_netStat)

# -------------------------------------------------------------

save(df_netStat, file= here:::here(proj_name, "RData", "df_netStat.RData"))
write_csv(df_netStat, here::here(proj_name, "output", "network_statistics.csv"))

# =====================================================================
# =====================================================================




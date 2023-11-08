link_hf <- function(shp, data) {
  # link the data to the shapefile
  # shp: shapefile
  # data: data.table
  # both should have two columns called "adm1" and "hf"
  # return: shapefile with data
  
  # transform data.table into dplyr tibble
  data <- as_tibble(data)
  
  # merge data with shp using dplyr join
  shp <- shp %>% left_join(data, by = c("hf" = "hf"))
  
  # return the shapefile
  return(shp)
}

link_adm1 <- function(shp, data) {
  browser()
  data <- as_tibble(data)
  shp <- shp %>% left_join(data, by = c("adm1" = "adm1"))
  return(shp)
}

link_adm2 <- function(shp, data) {
  data <- as_tibble(data)
  shp <- shp %>% left_join(data, by = c("adm1" = "adm1", "adm2" = "adm2"))
  return(shp)
}

# given catchment shapefile, data which linked to adm2
# and meta data of adm1, adm2, hf
# link all data together
link_adm2_hf <- function(shp_catchment, data, meta) {
  # shp_catchment, hf name
  # data, adm1 - adm2 - value
  # meta, adm1 - adm2 - hf
  # return: shp_catchment with data
  
  data <- as.data.table(data)
  meta <- as.data.table(meta)
  # left join data with meta
  joined <- meta[data, on = c("adm1", "adm2"), nomatch = 0]
  
  # remove adm1, adm2 from the joined
  joined[, c("adm1", "adm2") := NULL]
  
  # left join with shp_catchment
  browser()
  
  # summarize all other columns by hf, using data.table syntax
  joined <- joined[, lapply(.SD, sum, na.rm = TRUE), by = .(hf) ]
  
  # change it to tibble
  joined <- as_tibble(joined)
  
  # merge with shapefile
  shp_catchment <- shp_catchment %>% 
    left_join(joined, by = c("hf" = "hf"))
  
  return(shp_catchment)
}
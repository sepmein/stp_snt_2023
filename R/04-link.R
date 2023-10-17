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
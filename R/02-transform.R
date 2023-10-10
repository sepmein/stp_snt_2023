
# 1. shapefile ------------------------------------------------------------


## 1.1. get closest hf for each adm2 ---------------------------------------

transform_shp_get_closest_hf <- function(shp_adm2_nmcp,
                                         shp_hf) {
  # shp_adm2_nmcp is the shapefile of adm2
  # shp_hf is the shapefile of health facility
  # shp_adm2_nmcp has a column called adm2
  # shp_hf has a column called hf
  
  # find the distance between each adm2 and each hf, a matrix will be returned
  distances <- st_distance(shp_adm2_nmcp, shp_hf)
  
  # find the index of the closest hf for each adm2
  closest_hospital_index <- apply(distances, 1, which.min)
  
  # add a column called closest_hospital to shp_adm2_nmcp
  shp_adm2_nmcp$hf <- shp_hf$hf[closest_hospital_index]
  
  # return the new shapefile
  return(shp_adm2_nmcp)
}


## 1.2. get the merged adm1-hf level of shapefile --------------------------

#' get the merged adm1-hf level of shapefile
#' 
#' This function we merge the same adm1-hf combination, and get the
#' adm1-hf level of shapefile, by using shp_adm2_nmcp_hf
#' @param shp_adm2_nmcp_hf the shapefile of adm2 with closest hf
#' @return the shapefile of adm1-hf level
transform_shp_get_adm1_hf <- function(shp_adm2_nmcp_hf) {
  # Ensure input is of class sf
  stopifnot(class(shp_adm2_nmcp_hf)[1] == "sf")
  
  # Group by adm1 and hf, and summarise geometry to merge the same adm1-hf combinations
  adm1_hf_merged <- shp_adm2_nmcp_hf %>%
    group_by(adm1, hf) %>%
    summarise(geometry = st_union(geometry), .groups = "drop")
  
  # Update the geometry column to reflect the new merged geometries
  adm1_hf_merged_sf <- st_sf(adm1_hf_merged)
  
  return(adm1_hf_merged_sf)}

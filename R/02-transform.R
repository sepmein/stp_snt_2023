
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

## 1.3. get the merged adm1-hf level of shapefile --------------------------
# 1. create an adm1 level of shapefile for each group of adm1 firstly
# 2. within each adm1 level of shapefile
# The function transform_shp_get_adm1_hf_within you provided is intended to merge administrative level 1 (adm1) shapefiles with health facility (hf) shapefiles based on their spatial relationships. Here's a breakdown of the function and some clarifications:
# Creating an adm1 level of shapefile: You are grouping the shp_adm2 shapefile by adm1 and then merging (union) the geometries within each group to create a new shapefile shp_adm1 that represents the administrative level 1 boundaries.
# Assigning adm1 to each health facility: For each health facility in shp_hf with GPS coordinates, you are finding the corresponding adm1 and adding it as a new column to shp_hf.
# Assigning closest health facility to each adm2: This step is described in the comments but not implemented in the code. The idea is to:
# For each adm2 in shp_adm2, get its adm1 name.
# For each adm1, find all the health facilities inside it.
# Calculate the distance between the selected adm2 and all the health facilities.
# Find the closest health facility and assign it to the adm2.
# Producing adm1 - hf level of shapefile: This step is also described in the comments but not implemented. The goal is to group the assigned health facilities and produce a new shapefile that represents the relationship between adm1 and health facilities.
transform_shp_get_adm1_hf_within <- function(shp_adm2, shp_hf) {
  shp_adm1 <- shp_adm2 %>%
    group_by(adm1) %>%
    summarise(geometry = st_union(geometry), .groups = "drop")

  # 3. for each adm2 in shp_adm2, get the adm1 name, for each adm1, get all the hf inside,
  # 4. calculate the distance for the selected adm2 and all the hfs, calculate the distance,
  # 5. find the cloest one, assign this one to the adm2
  for (i in 1:nrow(shp_adm2)) {
    current_row <- shp_adm2[i, ]
    adm1 <- shp_adm2[i, ]$adm1
    adm2 <- shp_adm2[i, ]$adm2
    hf_within_adm1 <- shp_hf |> filter(adm1 == !!adm1)
    distances <- st_distance(shp_adm2[i, ], hf_within_adm1)
    closest_hospital_index <- apply(distances, 1, which.min)
    browser()
    shp_adm2[i, "hf"] <- hf_within_adm1$hf[closest_hospital_index]
  }
  # 6. for the assigned hfs, group them and them produce adm1 - hf level of shapefile
  adm1_hf <- shp_adm2 %>%
    group_by(adm1, hf) %>%
    summarise(geometry = st_union(geometry), .groups = "drop")
  return(adm1_hf)
}

# 2. transform month -------------------------------------------------------

# from the data.table there is a column called month, but the data in the month
# column is in Portuguese, we need to transform it into numbered format.
transform_month <- function(d) {
  browser()
  d[month == "Janeiro", month := 1]
  d[month == "Fevereiro", month := 2]
  d[month == "Março", month := 3]
  d[month == "Abril", month := 4]
  d[month == "Maio", month := 5]
  d[month == "Junho", month := 6]
  d[month == "Julho", month := 7]
  d[month == "Agosto", month := 8]
  d[month == "Setembro", month := 9]
  d[month == "Outubro", month := 10]
  d[month == "Novembro", month := 11]
  d[month == "Dezembro", month := 12]
  # Uppercase scenario [1] JANEIRO   FEVEREIRO MARÇO     ABRIL     MAIO      <NA>      JUNHO     JULHO     AGOSTO   
  # [10] SETEMBRO  OUTUBRO   NOVEMBRO  DEZEMBRO 
  d[month == "JANEIRO", month := 1]
  d[month == "FEVEREIRO", month := 2]
  d[month == "MARÇO", month := 3]
  d[month == "ABRIL", month := 4]
  d[month == "MAIO", month := 5]
  d[month == "JUNHO", month := 6]
  d[month == "JULHO", month := 7]
  d[month == "AGOSTO", month := 8]
  d[month == "SETEMBRO", month := 9]
  d[month == "OUTUBRO", month := 10]
  d[month == "NOVEMBRO", month := 11]
  d[month == "DEZEMBRO", month := 12]
  
  # lowercase scenario [1] janeiro   fevereiro março     abril     maio      junho     julho     agosto
  # [9] setembro  outubro   novembro  dezembro
  d[month == "janeiro", month := 1]
  d[month == "fevereiro", month := 2]
  d[month == "março", month := 3]
  d[month == "abril", month := 4]
  d[month == "maio", month := 5]
  d[month == "junho", month := 6]
  d[month == "julho", month := 7]
  d[month == "agosto", month := 8]
  d[month == "setembro", month := 9]
  d[month == "outubro", month := 10]
  d[month == "novembro", month := 11]
  d[month == "dezembro", month := 12]
  
  
  return(d)
}


# fix sex

transform_sex <- function(d) {
  d[sex == "Female", sex := "F"]
  d[sex == "Male", sex := "M"]
  d[sex == "f", sex := "F"]
  d[sex == "m", sex := "M"]
}

pyremid_plot <- function(fixed_adm1_estimated_population) {
  data <- fixed_adm1_estimated_population[,
                                          lapply(.SD, sum),
                                          by = .(year, sex),
                                          .SDcols = c(4:18)] |>
    # dcast to long format, the year column is the id
    melt(id.vars = c("year", "sex")) |>
    mutate(
      population = case_when(sex == "f" ~ -value,
                             TRUE ~ value),
      variable = as.factor(variable)
    )
  
  pop_range <- range(data$population)
  
  age_range_seq <- pretty(pop_range, n = 10)
  
  data |>
    ggplot(aes(x = population,
               y = variable,
               fill = sex)) +
    geom_col() +
    snt::sn_theme() +
    # scale_x_continuous(
    #                    labels = abs(age_range_seq)) +
    scale_fill_brewer(palette = "Dark2") +
    theme(legend.position = "top") 
}

# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline

# Load packages required to define the pipeline:
library(targets)
library(tarchetypes)

# Set target options:
tar_option_set(
  packages = c(
    "qs",
    "readxl",
    "data.table",
    "Hmisc",
    "sf",
    "fuzzyjoin",
    "dplyr"
  ),
  format = "qs"
  #
  # For distributed computing in tar_make(), supply a {crew} controller
  # as discussed at https://books.ropensci.org/targets/crew.html.
  # Choose a controller that suits your needs. For example, the following
  # sets a controller with 2 workers which will run as local R processes:
  #
  #   controller = crew::crew_controller_local(workers = 2)
  #
  # Alternatively, if you want workers to run on a high-performance computing
  # cluster, select a controller from the {crew.cluster} package. The following
  # example is a controller for Sun Grid Engine (SGE).
  #
  #   controller = crew.cluster::crew_controller_sge(
  #     workers = 50,
  #     # Many clusters install R as an environment module, and you can load it
  #     # with the script_lines argument. To select a specific verison of R,
  #     # you may need to include a version string, e.g. "module load R/4.3.0".
  #     # Check with your system administrator if you are unsure.
  #     script_lines = "module load R"
  #   )
  #
  # Set other options as needed.
)

# tar_make_clustermq() is an older (pre-{crew}) way to do distributed computing
# in {targets}, and its configuration for your machine is below.
options(clustermq.scheduler = "multicore")

# tar_make_future() is an older (pre-{crew}) way to do distributed computing
# in {targets}, and its configuration for your machine is below.
future::plan(future.callr::callr)

# Run the R scripts in the R/ folder with your custom functions:
tar_source()
# source("other_functions.R") # Source other scripts as needed.

# Replace the target list below with your own:
list(
  #### 1. files ####
  # 1.1. routine database from the country version 2023.10.1
  tar_qs(
    f_routine,
    "data/04-routine/FICHEIRO OMS BEATRIZ -250923_as_17_08.xlsx"
  ),
  # 1.2a. shapefile adm1 level extracted from WHO gishub
  tar_target(
    f_shp_adm1_who,
    "data/01-shapefile/gishub/STP_adm1.shp",
    format = "file"
  ),
  # 1.2b. shapefile adm2 level extracted from WHO gishub
  tar_target(
    f_shp_adm2_who,
    "data/01-shapefile/gishub/STP_adm2.shp",
    format = "file"
  ),
  # 1.2c. shapefile adm2 level from NMCP
  tar_target(
    f_shp_adm2_nmcp,
    "data/01-shapefile/stp_nmcp_village_reprojected.shp",
    format = "file"
  ),
  # 1.3.1. fix adm1 for hf
  tar_qs(f_fix_adm1_hf,
         ""),
  
  #### 2. load data ####
  # 2.1. load the health facilities list
  tar_target(hf,
             load_hf(f_routine)),
  # 2.2. load the estimated population
  tar_target(estimated_population,
             load_estimated_population(f_routine)),
  # 2.3. load the estimated population adm3 level
  tar_target(
    estimated_population_adm3,
    load_estimated_population_adm3(f_routine)
  ),
  # 2.4. load the routine database
  tar_target(routine,
             load_routine(f_routine)),
  # 2.5. load elimination
  tar_target(elimination,
             load_elimination(f_routine)),
  # 2.6. load passive cases
  tar_target(passive_cases,
             load_case_2022(f_routine)),
  # 2.7. load active cases
  tar_target(active_cases,
             load_active_cases_2022(f_routine)),
  # 2.8. load routine intervention
  tar_target(routine_intervention,
             load_routine_intervention(f_routine)),
  # 2.9. load IRS
  tar_target(irs,
             load_irs(f_routine)),
  # 2.10. load ITN campaign
  tar_target(itn_campaign,
             load_itn_campaign(f_routine)),
  # 2.11. load ITN routine
  tar_target(itn_routine,
             load_itn_routine(f_routine)),
  # 2.12. load lsm
  tar_target(lsm,
             load_lsm(f_routine)),
  # 2.13. load vector
  tar_target(vector,
             load_vector(f_routine)),
  # 2.14. load vector resistance
  tar_target(vector_resistance,
             load_vector_resistance(f_routine)),
  
  #### 2a. load shapefile ####
  # 2a.1 load adm1 shapefile
  tar_target(shp_adm1_who,
             st_read(f_shp_adm1_who)),
  # 2a.2. load adm2 shapefile
  tar_target(shp_adm2_who,
             st_read(f_shp_adm2_who)),
  # 2a.3. load adm2 shapefile from NMCP
  tar_target(
    shp_adm2_nmcp,
    st_read(f_shp_adm2_nmcp) |>
      # transform to WGS84
      st_transform(4326) |>
      rename(adm1 = Distrito, adm2 = Localidade)
  ),
  
  #### 3. unique values ####
  # 3.0.1. adm1 from shp_adm1_who
  tar_target(adm1,
             extract_adm1(shp_adm2_who)),
  # 3.0.2. adm1-adm2 from adm1, adm2
  tar_target(adm1_adm2_nmcp,
             extract_adm1_adm2_nmcp(shp_adm2_nmcp)),
  
  # 3.1. adm1 from hf
  tar_target(adm1_from_hf,
             hf[, .(adm1 = unique(adm1))]),
  # 3.2. adm2 from hf
  tar_target(adm2_from_hf,
             hf[, .(adm2 = unique(adm2))]),
  # 3.3. hf from hf
  tar_target(hf_from_hf,
             hf[, .(hf = unique(hf))]),
  # 3.4. adm1 from estimated_population
  tar_target(adm1_from_estimated_population,
             estimated_population[, .(adm1 = unique(adm1))]),
  # 3.5. adm1 from estimated_population_adm2
  tar_target(
    adm1_from_estimated_population_adm3,
    estimated_population_adm3[, .(adm1 = unique(adm1))]
  ),
  # 3.6. adm2 from estimated_population_adm2
  tar_target(
    adm3_from_estimated_population_adm3,
    estimated_population_adm3[, .(adm3 = unique(adm3))]
  ),
  # 3.7. adm1 from routine
  tar_target(adm1_from_routine,
             routine[, .(adm1 = unique(adm1))]),
  # 3.8. hf from routine
  tar_target(hf_from_routine,
             routine[, .(hf = unique(hf))]),
  # 3.9. adm1 from elimination
  tar_target(adm1_from_elimination,
             elimination[, .(adm1 = unique(adm1))]),
  # 3.10. adm2 from elimination
  tar_target(adm2_from_elimination,
             elimination[, .(adm2 = unique(adm2))]),
  # 3.11. adm1 from passive case level data 2022
  tar_target(adm1_from_passive_cases,
             passive_cases[, .(adm1 = unique(adm1))]),
  # 3.12. adm2 from passive case level data 2022
  tar_target(adm2_from_passive_cases,
             passive_cases[, .(adm2 = unique(adm2))]),
  # 3.13. adm1 from active case level data 2022
  tar_target(adm1_from_active_cases,
             active_cases[, .(adm1 = unique(adm1))]),
  # 3.14. adm2 from active case level data 2022
  tar_target(adm2_from_active_cases,
             active_cases[, .(adm2 = unique(adm2))]),
  # 3.15. adm1 from routine intervention
  tar_target(adm1_from_routine_intervention,
             routine_intervention[, .(adm1 = unique(adm1))]),
  # 3.16. hf from routine intervention
  tar_target(hf_from_routine_intervention,
             routine_intervention[, .(hf = unique(hf))]),
  # 3.17. adm1 from irs
  tar_target(adm1_from_irs,
             irs[, .(adm1 = unique(adm1))]),
  # 3.18. adm2 from irs
  tar_target(adm2_from_irs,
             irs[, .(adm2 = unique(adm2))]),
  # 3.19. adm1 from itn campaign
  tar_target(adm1_from_itn_campaign,
             itn_campaign[, .(adm1 = unique(adm1))]),
  # 3.20. adm1 from itn routine
  tar_target(adm1_from_itn_routine,
             itn_routine[, .(adm1 = unique(adm1))]),
  # 3.21. adm1 from lsm
  tar_target(adm1_from_lsm,
             lsm[, .(adm1 = unique(adm1))]),
  # 3.22. adm1 adm1 from adm2_nmcp
  tar_target(
    adm1_from_shp_adm2_nmcp,
    shp_adm2_nmcp |> st_drop_geometry() |>
      distinct(adm1) |>
      as.data.table()
  ),
  # 3.22. adm2 from lsm
  tar_target(adm2_from_lsm,
             lsm[, .(adm2 = unique(adm2))]),
  # 3.23. adm1 from vector
  tar_target(adm1_from_vector,
             vector[, .(adm1 = unique(adm1))]),
  # 3.24. adm2 from vector
  tar_target(adm2_from_vector,
             vector[, .(adm2 = unique(adm2))]),
  # 3.25. adm1 from vector resistance
  tar_target(adm1_from_vector_resistance,
             vector_resistance[, .(adm1 = unique(adm1))]),
  # 3.26. adm2 from vector resistance
  tar_target(adm2_from_vector_resistance,
             vector_resistance[, .(adm2 = unique(adm2))]),
  
  #### 4. comparison ####
  # 4.1. adm1 from hf and estimated_population, check if they are identical to each other
  tar_target(
    adm1_from_hf_estimated_population,
    setdiff(adm1_from_hf$adm1,
            adm1_from_estimated_population$adm1)
  ),
  # 4.2 adm1 from adm1_from_hf_estimated_population and adm1_from_estimated_population_adm2, check if they are identical to each other
  tar_target(
    adm1_from_hf_estimated_population_adm3,
    setdiff(adm1_from_hf$adm1,
            adm1_from_estimated_population_adm3$adm1)
  ),
  # 4.3. adm1 from hf and routine, check if they are identical to each other
  tar_target(
    adm1_from_hf_routine,
    setdiff(adm1_from_hf$adm1,
            adm1_from_routine$adm1)
  ),
  # 4.4. hf from hf and routine, check if they are identical to each other
  tar_target(
    hf_from_hf_routine,
    setdiff(hf_from_hf$hf,
            hf_from_routine$hf)
  ),
  # 4.5. adm1 from hf and elimination, check if they are identical to each other
  tar_target(
    adm1_from_hf_elimination,
    setdiff(adm1_from_hf$adm1,
            adm1_from_elimination$adm1)
  ),
  # 4.6. adm2 from hf and elimination, check if they are identical to each other
  tar_target(
    adm2_from_hf_elimination,
    setdiff(adm2_from_hf$adm2,
            adm2_from_elimination$adm2)
  ),
  # 4.7. adm1 from hf and passive_cases, check if they are identical to each other
  tar_target(
    adm1_from_hf_passive_cases,
    setdiff(adm1_from_hf$adm1,
            adm1_from_passive_cases$adm1)
  ),
  # 4.8. adm2 from hf and passive_cases, check if they are identical to each other
  tar_target(
    adm2_from_hf_passive_cases,
    setdiff(adm2_from_hf$adm2,
            adm2_from_passive_cases$adm2)
  ),
  # 4.9. adm1 from hf and active_cases, check if they are identical to each other
  tar_target(
    adm1_from_hf_active_cases,
    setdiff(adm1_from_hf$adm1,
            adm1_from_active_cases$adm1)
  ),
  # 4.10. adm2 from hf and active_cases, check if they are identical to each other
  tar_target(
    adm2_from_hf_active_cases,
    setdiff(adm2_from_hf$adm2,
            adm2_from_active_cases$adm2)
  ),
  # 4.11. adm1 from hf and routine_intervention, check if they are identical to each other
  tar_target(
    adm1_from_hf_routine_intervention,
    setdiff(adm1_from_hf$adm1,
            adm1_from_routine_intervention$adm1)
  ),
  # 4.12. hf from hf and routine_intervention, check if they are identical to each other
  tar_target(
    hf_from_hf_routine_intervention,
    setdiff(hf_from_hf$hf,
            hf_from_routine_intervention$hf)
  ),
  # 4.13. adm1 from hf and irs, check if they are identical to each other
  tar_target(
    adm1_from_hf_irs,
    setdiff(adm1_from_hf$adm1,
            adm1_from_irs$adm1)
  ),
  # 4.14. adm2 from hf and irs, check if they are identical to each other
  tar_target(
    adm2_from_hf_irs,
    setdiff(adm2_from_hf$adm2,
            adm2_from_irs$adm2)
  ),
  # 4.15. adm1 from hf and itn_campaign, check if they are identical to each other
  tar_target(
    adm1_from_hf_itn_campaign,
    setdiff(adm1_from_hf$adm1,
            adm1_from_itn_campaign$adm1)
  ),
  # 4.16. adm1 from hf and itn_routine, check if they are identical to each other
  tar_target(
    adm1_from_hf_itn_routine,
    setdiff(adm1_from_hf$adm1,
            adm1_from_itn_routine$adm1)
  ),
  # 4.17. adm1 from hf and lsm, check if they are identical to each other
  tar_target(
    adm1_from_hf_lsm,
    setdiff(adm1_from_hf$adm1,
            adm1_from_lsm$adm1)
  ),
  # 4.18. adm2 from hf and lsm, check if they are identical to each other
  tar_target(
    adm2_from_hf_lsm,
    setdiff(adm2_from_hf$adm2,
            adm2_from_lsm$adm2)
  ),
  # 4.19. adm1 from hf and vector, check if they are identical to each other
  tar_target(
    adm1_from_hf_vector,
    setdiff(adm1_from_hf$adm1,
            adm1_from_vector$adm1)
  ),
  # 4.20. adm2 from hf and vector, check if they are identical to each other
  tar_target(
    adm2_from_hf_vector,
    setdiff(adm2_from_hf$adm2,
            adm2_from_vector$adm2)
  ),
  # 4.21. adm1 from hf and vector_resistance, check if they are identical to each other
  tar_target(
    adm1_from_hf_vector_resistance,
    setdiff(adm1_from_hf$adm1,
            adm1_from_vector_resistance$adm1)
  ),
  # 4.22. adm2 from hf and vector_resistance, check if they are identical to each other
  tar_target(
    adm2_from_hf_vector_resistance,
    setdiff(adm2_from_hf$adm2,
            adm2_from_vector_resistance$adm2)
  ),
  
  #### 5. fuzzy match ####
  ##### 5.1. adm1 #####
  # 5.1.1. hf
  tar_target(fuzzy_adm1_hf,
             match_adm1(adm1, adm1_from_hf)),
  # 5.1.2. adm1_from_estimated_population
  tar_target(
    fuzzy_adm1_estimated_population,
    match_adm1(adm1, adm1_from_estimated_population)
  ),
  # 5.1.3. adm1_from_estimated_population_adm3
  tar_target(
    fuzzy_adm1_estimated_population_adm3,
    match_adm1(adm1, adm1_from_estimated_population_adm3)
  ),
  # 5.1.4. adm1_from_routine
  tar_target(fuzzy_adm1_routine,
             match_adm1(adm1, adm1_from_routine)),
  # 5.1.5. adm1_from_elimination
  tar_target(
    fuzzy_adm1_elimination,
    match_adm1(adm1, adm1_from_elimination)
  ),
  # 5.1.6. adm1_from_passive_cases
  tar_target(
    fuzzy_adm1_passive_cases,
    match_adm1(adm1, adm1_from_passive_cases)
  ),
  # 5.1.7. adm1_from_active_cases
  tar_target(
    fuzzy_adm1_active_cases,
    match_adm1(adm1, adm1_from_active_cases)
  ),
  # 5.1.8. adm1_from_routine_intervention
  tar_target(
    fuzzy_adm1_routine_intervention,
    match_adm1(adm1, adm1_from_routine_intervention)
  ),
  # 5.1.9. adm1_from_irs
  tar_target(fuzzy_adm1_irs,
             match_adm1(adm1, adm1_from_irs)),
  # 5.1.10. adm1_from_itn_campaign
  tar_target(
    fuzzy_adm1_itn_campaign,
    match_adm1(adm1, adm1_from_itn_campaign)
  ),
  # 5.1.11. adm1_from_itn_routine
  tar_target(
    fuzzy_adm1_itn_routine,
    match_adm1(adm1, adm1_from_itn_routine)
  ),
  # 5.1.12. adm1_from_lsm
  tar_target(fuzzy_adm1_lsm,
             match_adm1(adm1, adm1_from_lsm)),
  # 5.1.13. adm1_from_vector
  tar_target(fuzzy_adm1_vector,
             match_adm1(adm1, adm1_from_vector)),
  # 5.1.14. adm1_from_vector_resistance
  tar_target(
    fuzzy_adm1_vector_resistance,
    match_adm1(adm1, adm1_from_vector_resistance)
  ),
  # 5.1.15. adm1_from_shp_adm2_nmcp
  tar_target(
    fuzzy_adm1_shp_adm2_nmcp,
    match_adm1(adm1, adm1_from_shp_adm2_nmcp)
  ),
  ##### 5.2. adm2 #####
  
  ##### 5.3. hf -----------------------------------------------------------------
  
  ###### 5.3.1. hf from hf and hf from routine -----------------------------------
  tar_target(
    fuzzy_hf_hf_from_routine,
    match_hf(hf_from_hf, hf_from_routine)
  ),
  
  
  
  
  #### 6. manual fix ####
  ##### 6.1. adm1 #####
  # in adm1_from_hf_estimated_population_adm3, RAP should be Principe
  # 6.1.1. adm1_from_hf
  tar_target(fixed_adm1_hf,
             fix_adm1(hf, fuzzy_adm1_hf)),
  # 6.1.2. adm1_from_estimated_population
  tar_target(
    fixed_adm1_estimated_population,
    fix_adm1(estimated_population, fuzzy_adm1_estimated_population)
  ),
  # 6.1.3. adm1_from_estimated_population_adm3
  tar_target(
    fixed_adm1_estimated_population_adm3,
    estimated_population_adm3[adm1 == "RAP", adm1 := "Principe"] |>
      fix_adm1(fuzzy_adm1_estimated_population_adm3)
  ),
  # 6.1.4. adm1_from_routine
  tar_target(fixed_adm1_routine,
             fix_adm1(routine, fuzzy_adm1_routine)),
  # 6.1.5. adm1_from_elimination
  tar_target(
    fixed_adm1_elimination,
    fix_adm1(elimination, fuzzy_adm1_elimination)
  ),
  # 6.1.6. adm1_from_passive_cases
  tar_target(
    fixed_adm1_passive_cases,
    fix_adm1(passive_cases, fuzzy_adm1_passive_cases)
  ),
  # 6.1.7. adm1_from_active_cases
  tar_target(
    fixed_adm1_active_cases,
    fix_adm1(active_cases, fuzzy_adm1_active_cases)
  ),
  # 6.1.8. adm1_from_routine_intervention
  tar_target(
    fixed_adm1_routine_intervention,
    fix_adm1(routine_intervention, fuzzy_adm1_routine_intervention)
  ),
  # 6.1.9. adm1_from_irs
  tar_target(fixed_adm1_irs,
             fix_adm1(irs, fuzzy_adm1_irs)),
  # 6.1.10. adm1_from_itn_campaign
  tar_target(
    fixed_adm1_itn_campaign,
    fix_adm1(itn_campaign, fuzzy_adm1_itn_campaign)
  ),
  # 6.1.11. adm1_from_itn_routine
  # in adm1_from_itn_route, there is an extra adm1 called "CNE", which might stands for National Center for Endemic Diseases (CNE) (Sao Tome and Principe). Not sure why, set CNE to NA firstly
  tar_target(
    fixed_adm1_itn_routine,
    itn_routine[adm1 == "CNE", adm1 := NA_character_] |>
      fix_adm1(fuzzy_adm1_itn_routine)
  ),
  # 6.1.12. adm1_from_lsm
  tar_target(fixed_adm1_lsm,
             fix_adm1(lsm, fuzzy_adm1_lsm)),
  # 6.1.13. adm1_from_vector
  tar_target(fixed_adm1_vector,
             fix_adm1(vector, fuzzy_adm1_vector)),
  # 6.1.14. adm1_from_vector_resistance
  # in adm1_from_vector_resistance, RAP should be Principe
  # also manually exclude the "N/A" from the list
  tar_target(
    fixed_adm1_vector_resistance,
    vector_resistance[adm1 == "RAP", adm1 :=  "Principe"][adm1 == "N/A" , adm1 := NA_character_] |>
      fix_adm1(fuzzy_adm1_vector_resistance)
  ),
  # 6.1.15. adm1_from_shp_adm2_nmcp
  tar_target(
    fixed_adm1_shp_adm2_nmcp,
    shp_adm2_nmcp |>
      mutate(adm1 = ifelse(adm1 == "Pagué", "Principe", adm1)) |>
      as.data.table() |>
      fix_adm1(fuzzy_adm1_shp_adm2_nmcp) |>
      st_as_sf()
  ),
  ##### 6.2. adm1 adm2 combination #####
  # 6.2.1. find duplicated adm1 adm2 combination in shp_adm2_nmcp
  tar_target(
    duplicated_adm1_adm2_shp,
    extract_duplicated_adm1_adm2_nmcp(shp_adm2_nmcp)
  ),
  # 6.2.2. export the duplicated adm1-adm2 combination in shp_adm2_nmcp
  tar_target(
    export_duplicated_adm1_adm2_shp,
    fwrite(duplicated_adm1_adm2_shp |> st_drop_geometry(),
           file = "report/01-shapefile/01-duplicated-adm1-adm2-list.csv")
  ),
  
  
  ##### 6.3. hf -----------------------------------------------------------------
  
  ###### 6.3.1. hf in routine data -----------------------------------------------
  tar_target(
    fixed_hf_routine,
    fixed_adm1_routine |>
      mutate(hf = ifelse(hf == "POSTO DE PICÃO", "Picão", hf)) |>
      mutate(hf = ifelse(hf == "POSTO DE AEROPORTO", "Aeroporto", hf)) |>
      mutate(hf = ifelse(hf == "POSTO DE SUNDY", "Sundy", hf)) |>
      mutate(hf = ifelse(
        hf == "Centro Saude Trindade", "Trindade", hf
      )) |>
      mutate(hf = ifelse(hf == "Posto saude Bombom", "Bombom", hf)) |>
      mutate(hf = ifelse(hf == "Posto de Saude de Conde", "Conde", hf)) |>
      mutate(hf = ifelse(hf == "POSTO DE PANTUFO", "Pantufo", hf)) |>
      mutate(hf = ifelse(hf == "POSTO DE S. MARÇAL", "São Marçal", hf)) |>
      mutate(hf = ifelse(hf == "P. S. DE ÁGUA IZÉ", "Agua Izé", hf)) |>
      mutate(hf = ifelse(hf == "POSTO S. DE SANTANA", "Santana", hf)) |>
      mutate(
        hf = ifelse(hf == "POSTO DE QUARTEL", "Can not find match POSTO DE QUARTEL", hf)
      )
  ),
  
  
  # 3. transform ---------------------------------------------------------------
  ##### 3.1. shapefile -----------------------------------------------------------
  ###### 3.1.1. hf ---------------------------------------------------------------
  # transform hf to sf, using long and lat, and set crs to 4326
  tar_target(shp_hf,
             fixed_adm1_hf |>
               st_as_sf(
                 coords = c("long", "lat"), crs = 4326
               )),
  ###### 3.1.2. get closet hf -----------------------------------------------------
  # for each adm2, find the closet hf, as in this project, there are more hfs
  # than adm2, and some data are hf level, so we have to match adm2 to hfs
  tar_target(
    shp_adm2_nmcp_hf,
    transform_shp_get_closest_hf(fixed_adm1_shp_adm2_nmcp,
                                 shp_hf)
  ),
  ###### 3.1.3. get adm1-hf level of shapefile --------------------------------
  # in this shapefile, we merge the same adm1-hf combination, and get the
  # adm1-hf level of shapefile, by using shp_adm2_nmcp_hf
  tar_target(shp_adm1_hf,
             transform_shp_get_adm1_hf(shp_adm2_nmcp_hf)),
  
  
  # 4. export -----------------------------------------------------------------
  ##### 4.1. shapefile -----------------------------------------------------------
  ###### 4.1.1. hf ---------------------------------------------------------------
  # export hf shapefile
  tar_target(
    export_shp_hf,
    st_write(
      shp_hf |> st_make_valid(),
      "results/2-shapefile/hf.shp",
      crs = st_crs(4326),
      delete_dsn = TRUE
    )
  ),
  ###### 4.1.2. adm2_nmcp --------------------------------------------------------
  # export adm2_nmcp shapefile
  tar_target(
    export_shp_adm1_hf,
    st_write(
      shp_adm1_hf |> st_make_valid(),
      "results/2-shapefile/shp_adm1_hf.shp",
      crs = st_crs(4326),
      delete_dsn = TRUE
    )
  )
)

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
    "snt",
    "qs",
    "readxl",
    "data.table",
    "Hmisc",
    "sf",
    "fuzzyjoin",
    "dplyr",
    "tmap",
    "lubridate",
    "ggplot2",
    "stringr",
    "ggpubr",
    "gtsummary"
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
  
  #### 1. files ---------------------------------------------------------------
  
  ##### 1.1. routine database from the country version 2023.10.1 --------------
  
  tar_file(
    f_routine,
    "data/04-routine/Cópia de FICHEIRO OMS BEATRIZ -041023_Principal (1).xlsx"
  ),
  
  ##### 1.2a. shapefile adm1 level extracted from WHO gishub ------------------
  
  tar_target(
    f_shp_adm1_who,
    "data/01-shapefile/gishub/STP_adm1.shp",
    format = "file"
  ),
  
  ##### 1.2b. shapefile adm2 level extracted from WHO gishub ------------------
  
  tar_target(
    f_shp_adm2_who,
    "data/01-shapefile/gishub/STP_adm2.shp",
    format = "file"
  ),
  ##### 1.2c. shapefile adm2 level from NMCP ----------------------------------
  tar_target(
    f_shp_adm2_nmcp,
    "data/01-shapefile/stp_nmcp_village_reprojected.shp",
    format = "file"
  ),
  

  ##### 1.3 localities - hf -----------------------------------------------------
  tar_file(
    f_localities_hf,
    "data/02-health_facilities/Localidades posto.xlsx"
  ),
  
  #### 2. load data ####
  
  ##### 2.1. health facilities list ----
  
  tar_target(hf,
             load_hf(f_routine)),
  
  tar_target(adm2_hf,
             load_adm2_hf(f_localities_hf)
             ),
  
  ##### 2.2. load the estimated population ----
  
  tar_target(estimated_population,
             load_estimated_population(f_routine)),
  
  ##### 2.3. estimated population adm2 level ----
  
  tar_target(
    estimated_population_adm2,
    load_estimated_population_adm2(f_routine)
  ),
  
  ##### 2.4. routine database ----
  
  tar_target(routine,
             load_routine(f_routine) |> 
            transform_month()),
  
  ##### 2.5. elimination ----
  
  tar_target(elimination,
             load_elimination(f_routine)),
  
  ##### 2.6. passive cases ----
  
  tar_target(passive_cases,
             load_case_2022(f_routine) |>
               transform_month() |>
               transform_sex()
               ),
  
  ##### 2.7. active cases ----
  
  tar_target(active_cases,
             load_active_cases_2022(f_routine) |>
               transform_month() |> 
               transform_sex()
             ),
  
  ##### 2.8. load routine intervention ----
  
  tar_target(routine_intervention,
             load_routine_intervention(f_routine) |> 
               transform_month()),
  
  ##### 2.9. load IRS ----
  
  tar_target(irs,
             load_irs(f_routine)),
  
  ##### 2.10. load ITN campaign ----
  
  tar_target(itn_campaign,
             load_itn_campaign(f_routine)),
  
  ##### 2.11. load ITN routine ----
  # tar_target(itn_routine,
  #            load_itn_routine(f_routine)),
  
  ##### 2.12. load lsm ----
  
  tar_target(lsm,
             load_lsm(f_routine)),
  
  ##### 2.13. load vector ----
  
  tar_target(vector,
             load_vector(f_routine) |> transform_month()),
  
  ##### 2.14. load vector resistance ----
  
  tar_target(vector_resistance,
             load_vector_resistance(f_routine) |> transform_month()),
  
  ##### 2a. load shapefile ####
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

  ##### 3.1. shp, from WHO, ADM1 level --------------------------------------
  
  # 3.0.1. adm1 from shp_adm1_who
  tar_target(adm1,
             extract_adm1(shp_adm2_who)),
  
  ##### 3.2. shp, from NMCP, ADM2 level , fixed adm1 using WHO standard ------
  
  # adm1-adm2 from adm1, adm2
  tar_target(adm1_adm2_nmcp,
             extract_adm1_adm2_nmcp(fixed_adm1_shp_adm2_nmcp)),
  
  # 3.22. adm1 adm1 from adm2_nmcp
  tar_target(
    adm1_from_shp_adm2_nmcp,
    shp_adm2_nmcp |> st_drop_geometry() |>
      distinct(adm1) |>
      as.data.table()
  ),
  
  # duplicated adm2
  tar_target(
    duplicated_adm2_nmcp,
    shp_adm2_nmcp |> 
      group_by(adm2) |> 
      filter(n() > 1) |> 
      group_by(adm1, adm2) |>
      filter(n() == 1) |>
      st_write("results/2-shapefile/duplicated/duplicated-localities.shp",
               delete_dsn = TRUE
               )
  ),
  tar_target(
    duplicated_adm2_nmcp_csv,
    shp_adm2_nmcp |> 
      group_by(adm2) |> 
      filter(n() > 1) |> 
      group_by(adm1, adm2) |>
      filter(n() == 1) |> 
      st_drop_geometry() |>
      fwrite("results/2-shapefile/duplicated/duplicated-localities.csv")
  ),
  
  ##### 3.3. health facilities(the `US` tab) ----------------------------------
  
  # 3.1. adm1 from hf
  tar_target(adm1_from_hf,
             hf[, .(adm1 = unique(adm1))]),
  # 3.2. adm2 from hf
  tar_target(adm2_from_hf,
             hf[, .(adm2 = unique(adm2))]),
  # 3.3. hf from hf
  tar_target(hf_from_hf,
             hf[, .(hf = unique(hf))]),
  
  ##### 3.4. estimated population ----------------------------------------------
  
  # 3.4. adm1 from estimated_population
  tar_target(adm1_from_estimated_population,
             estimated_population[, .(adm1 = unique(adm1))]),
  
  ##### 3.5. estimated population adm2 -----------------------------------------
  
  # 3.5. adm1 from estimated_population_adm2
  tar_target(
    adm1_from_estimated_population_adm2,
    estimated_population_adm2[, .(adm1 = unique(adm1))]
  ),
  # 3.6. adm2 from estimated_population_adm2
  tar_target(
    adm2_from_estimated_population_adm2,
    estimated_population_adm2[, .(adm2 = unique(adm2))]
  ),
  
  # 3.6. adm1-adm2 from estimated population adm2
  tar_target(
    adm1_adm2_from_estimated_population_adm2,
    fixed_adm1_estimated_population_adm2[, .(adm1, adm2 )] |> unique()
  ),
  
  ##### 3.6. routine database --------------------------------------------------
  
  # 3.7. adm1 from routine
  tar_target(adm1_from_routine,
             routine[, .(adm1 = unique(adm1))]),
  # 3.8. hf from routine
  tar_target(hf_from_routine,
             routine[, .(hf = unique(hf))]),
  
  ##### 3.7. elimination -------------------------------------------------------
  
  # 3.9. adm1 from elimination
  tar_target(adm1_from_elimination,
             elimination[, .(adm1 = unique(adm1))]),
  # 3.10. adm2 from elimination
  tar_target(adm2_from_elimination,
             elimination[, .(adm2 = unique(adm2))]),
  # 3.10. adm2 from elimination
  tar_target(adm1_adm2_from_elimination,
             fixed_adm1_elimination[, .(adm1, adm2 )] |> unique()),
  
  ##### 3.8. passive case data -------------------------------------------------
  
  # 3.11. adm1 from passive case level data 2022
  tar_target(adm1_from_passive_cases,
             passive_cases[, .(adm1 = unique(adm1))]),
  # 3.12. adm2 from passive case level data 2022
  tar_target(adm2_from_passive_cases,
             passive_cases[, .(adm2 = unique(adm2))]),
  # 3.12. adm2 from passive case level data 2022
  tar_target(adm1_adm2_from_passive_cases,
             fixed_adm1_passive_cases[, .(adm1, adm2 )] |> unique()),
  
  ##### 3.9. active case -------------------------------------------------------
  
  # 3.13. adm1 from active case level data 2022
  tar_target(adm1_from_active_cases,
             active_cases[, .(adm1 = unique(adm1))]),
  # 3.14. adm2 from active case level data 2022
  tar_target(adm2_from_active_cases,
             active_cases[, .(adm2 = unique(adm2))]),
  
  ##### 3.10. routine intervention ---------------------------------------------
  
  # 3.15. adm1 from routine intervention
  tar_target(adm1_from_routine_intervention,
             routine_intervention[, .(adm1 = unique(adm1))]),
  # 3.16. hf from routine intervention
  tar_target(hf_from_routine_intervention,
             routine_intervention[, .(hf = unique(hf))]),
  
  ##### 3.11. irs --------------------------------------------------------------
  
  # adm1
  tar_target(adm1_from_irs,
             irs[, .(adm1 = unique(adm1))]),
  # adm2
  tar_target(adm2_from_irs,
             irs[, .(adm2 = unique(adm2))]),
  # adm1-adm2
  tar_target(adm1_adm2_from_irs,
             fixed_adm1_irs[, .(adm1, adm2 )] |> unique()),
  
  ##### 3.12. itn campaingn ----------------------------------------------------
  
  # 3.19. adm1 from itn campaign
  tar_target(adm1_from_itn_campaign,
             itn_campaign[, .(adm1 = unique(adm1))]),
  
  ##### 3.13. itn routine ------------------------------------------------------
  
  # 3.20. adm1 from itn routine
  # tar_target(adm1_from_itn_routine,
  #            itn_routine[, .(adm1 = unique(adm1))]),
  
  ##### 3.14. Larval Source management -----------------------------------------
  
  # 3.21. adm1 from lsm
  tar_target(adm1_from_lsm,
             lsm[, .(adm1 = unique(adm1))]),
  
  # 3.22. adm2 from lsm
  tar_target(adm2_from_lsm,
             lsm[, .(adm2 = unique(adm2))]),
  
  # adm1-adm2 from lsm
  tar_target(adm1_adm2_from_lsm,
             fixed_adm1_lsm[, .(adm1, adm2 )] |> unique()),
  
  ##### 3.15. Vector -----------------------------------------------------------
  
  # 3.23. adm1 from vector
  tar_target(adm1_from_vector,
             vector[, .(adm1 = unique(adm1))]),
  
  # 3.24. adm2 from vector
  tar_target(adm2_from_vector,
             vector[, .(adm2 = unique(adm2))]),
  
  # adm1-adm2
  tar_target(adm1_adm2_from_vector,
             fixed_adm1_vector[, .(adm1, adm2 )] |> unique()),
  
  ##### 3.16. Vector Resistance ------------------------------------------------
  
  # 3.25. adm1 from vector resistance
  tar_target(adm1_from_vector_resistance,
             vector_resistance[, .(adm1 = unique(adm1))]),
  # 3.26. adm2 from vector resistance
  tar_target(adm2_from_vector_resistance,
             vector_resistance[, .(adm2 = unique(adm2))]),
  # adm1-adm2
  tar_target(adm1_adm2_from_vector_resistance,
             fixed_adm1_vector_resistance[, .(adm1, adm2 )] |> unique()),
  
  ##### 3.17. adm2-hf list provided by the country -------
  tar_target(
    hf_from_adm2_hf,
    adm2_hf[order(hf), .(hf = unique(hf))] |> 
      fwrite("report/03-hf/hf-from-adm2-hf.csv")
  ),
  
  tar_target(
    adm1_adm2_from_adm2_hf,
    adm2_hf[order(adm1, adm2), .(adm1, adm2)] |> 
      unique() |>
      fwrite("report/03-hf/adm1-adm2-from-adm2-hf.csv")
  ),
  #### 4. comparison ####
  # This section is design for compare the unique value generated from the last
  # section with the unique value from the previous section. If they are not
  # identical, then there is a need to align the data.
  
  
  # 4.1. adm1 from hf and estimated_population, check if they are identical to 
  # each other
  tar_target(
    adm1_from_hf_estimated_population,
    setdiff(adm1_from_hf$adm1,
            adm1_from_estimated_population$adm1)
  ),
  # 4.2 adm1 from adm1_from_hf_estimated_population and adm1_from_estimated_population_adm2, check if they are identical to each other
  tar_target(
    adm1_from_hf_estimated_population_adm2,
    setdiff(adm1_from_hf$adm1,
            adm1_from_estimated_population_adm2$adm1)
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
  # tar_target(
  #   adm1_from_hf_itn_routine,
  #   setdiff(adm1_from_hf$adm1,
  #           adm1_from_itn_routine$adm1)
  # ),
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
  
  ###### 5.1.1. hf ----
  
  tar_target(fuzzy_adm1_hf,
             match_adm1(adm1, adm1_from_hf)),
  
  ###### 5.1.2. estimated_population ----
  
  tar_target(
    fuzzy_adm1_estimated_population,
    match_adm1(adm1, adm1_from_estimated_population)
  ),
  
  ###### 5.1.3. estimated_population_adm2 ----
 
  tar_target(
    fuzzy_adm1_estimated_population_adm2,
    match_adm1(adm1, adm1_from_estimated_population_adm2)
  ),
  
  ###### 5.1.4. routine ----
 
  tar_target(fuzzy_adm1_routine,
             match_adm1(adm1, adm1_from_routine)),
  
  ###### 5.1.5. elimination ----
 
  tar_target(
    fuzzy_adm1_elimination,
    match_adm1(adm1, adm1_from_elimination)
  ),
  
  ###### 5.1.6. passive_cases ----
 
  tar_target(
    fuzzy_adm1_passive_cases,
    match_adm1(adm1, adm1_from_passive_cases)
  ),
  
  ###### 5.1.7. active_cases ----
 
  tar_target(
    fuzzy_adm1_active_cases,
    match_adm1(adm1, adm1_from_active_cases)
  ),
  
  ###### 5.1.8. routine_intervention ----
 
  tar_target(
    fuzzy_adm1_routine_intervention,
    match_adm1(adm1, adm1_from_routine_intervention)
  ),
  
  ###### 5.1.9. irs ----
 
  tar_target(fuzzy_adm1_irs,
             match_adm1(adm1, adm1_from_irs)),
  
  ###### 5.1.10. itn_campaign ----
 
  tar_target(
    fuzzy_adm1_itn_campaign,
    match_adm1(adm1, adm1_from_itn_campaign)
  ),
  
  ###### 5.1.11. itn_routine ----
 
  # tar_target(
  #   fuzzy_adm1_itn_routine,
  #   match_adm1(adm1, adm1_from_itn_routine)
  # ),
  
  ###### 5.1.12. lsm ----
 
  tar_target(fuzzy_adm1_lsm,
             match_adm1(adm1, adm1_from_lsm)),
  
  ###### 5.1.13. vector ----
 
  tar_target(fuzzy_adm1_vector,
             match_adm1(adm1, adm1_from_vector)),
  
  ###### 5.1.14. vector_resistance ----
 
  tar_target(
    fuzzy_adm1_vector_resistance,
    match_adm1(adm1, adm1_from_vector_resistance)
  ),
  
  ###### 5.1.15. shp_adm2_nmcp ----
 
  tar_target(
    fuzzy_adm1_shp_adm2_nmcp,
    match_adm1(adm1, adm1_from_shp_adm2_nmcp)
  ),
  
  ##### 5.2. adm1 adm2 #####

  ###### 5.2.1 population  ---------------------------------------------------
  
  tar_target(
    fuzzy_adm2_pop,
    match_adm2(adm1_adm2_nmcp, adm1_adm2_from_estimated_population_adm2)
  ),
  # export
  tar_target(
    export_fuzzy_adm2_pop,
    fuzzy_adm2_pop |> fwrite("report/02-fuzzy/adm2/fuzzy_adm2_pop.csv")
  ),
  
  ###### 5.2.2. elimination  -------------------------------------------------
  
  tar_target(
    # adm1_adm2_from_elimination
    fuzzy_adm2_elimination,
    match_adm2(adm1_adm2_nmcp, adm1_adm2_from_elimination)
  ),
  # export
  tar_target(
    export_fuzzy_adm2_elimination,
    fuzzy_adm2_elimination |> 
      fwrite("report/02-fuzzy/adm2/fuzzy_adm2_elimination.csv")
  ),
  
  ###### 5.2.3. irs -------------------------------------------------
  
  tar_target(
    fuzzy_adm2_irs,
    match_adm2(adm1_adm2_nmcp, adm1_adm2_from_irs)
  ),
  # export
  tar_target(
    export_fuzzy_adm2_irs,
    fuzzy_adm2_irs |> fwrite("report/02-fuzzy/adm2/fuzzy_adm2_irs.csv")
  ),
  
  ###### 5.2.4. lsm --------------------------------------------------
  
  tar_target(
    fuzzy_adm2_lsm,
    match_adm2(adm1_adm2_nmcp, adm1_adm2_from_lsm)
  ),
  # export
  tar_target(
    export_fuzzy_adm2_lsm,
    fuzzy_adm2_lsm |> fwrite("report/02-fuzzy/adm2/fuzzy_adm2_lsm.csv")
  ),
  
  ###### 5.2.5. vector --------------------------------------------------
  
  tar_target(
    fuzzy_adm2_vector,
    match_adm2(adm1_adm2_nmcp, adm1_adm2_from_vector)
  ),
  # export
  tar_target(
    export_fuzzy_adm2_vector,
    fuzzy_adm2_vector |> fwrite("report/02-fuzzy/adm2/fuzzy_adm2_vector.csv")
  ),
  
  ###### 5.2.6. vector resistance ----------------------------------------
  
  tar_target(
    fuzzy_adm2_vector_resistance,
    match_adm2(adm1_adm2_nmcp, adm1_adm2_from_vector_resistance)
  ),
  # export
  tar_target(
    export_fuzzy_adm2_vector_resistance,
    fuzzy_adm2_vector_resistance |> 
      fwrite("report/02-fuzzy/adm2/fuzzy_adm2_vector_resistance.csv")
  ), 
  
  ###### 5.2.7. meta_adm2_hf ---------------------------------------------------
  tar_target(
    fuzzy_shp_with_adm2_hf,
    match_adm2(adm2_hf, adm1_adm2_nmcp)
  ),
  tar_target(
    export_fuzzy_shp_with_adm2_hf,
    fuzzy_shp_with_adm2_hf |> fwrite("report/02-fuzzy/adm2/fuzzy_shp_with_adm2_hf.csv")
  ),
  
  ##### 5.3. hf -----------------------------------------------------------------
  
  ###### 5.3.1. hf from hf and hf from routine -----------------------------------
  tar_target(
    fuzzy_hf_from_routine,
    match_hf(hf_from_hf, hf_from_routine)
  ),
  
  #### 6. manual fix ####
  ##### 6.1. adm1 #####
  # in adm1_from_hf_estimated_population_adm2, RAP should be Principe
  # 6.1.1. adm1_from_hf
  tar_target(fixed_adm1_hf,
             fix_adm1(hf, fuzzy_adm1_hf)),
  # 6.1.2. adm1_from_estimated_population
  tar_target(
    fixed_adm1_estimated_population,
    estimated_population[adm1 == "RAP", adm1 := "Principe"] |>
    fix_adm1(fuzzy_adm1_estimated_population) |>
      setcolorder(c("adm1", setdiff(names(estimated_population), "adm1")))
  ),
  # 6.1.3. adm1_from_estimated_population_adm2
  tar_target(
    fixed_adm1_estimated_population_adm2,
    estimated_population_adm2[adm1 == "RAP", adm1 := "Principe"] |>
      fix_adm1(fuzzy_adm1_estimated_population_adm2)
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
    active_cases[adm1 == "RAP", adm1 := "Principe"] |>
      fix_adm1(fuzzy_adm1_active_cases)
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
  # in adm1_from_itn_route, there is an extra adm1 called "CNE", 
  # which might stands for National Center for Endemic Diseases (CNE) (Sao Tome and Principe). 
  # Not sure why, set CNE to NA firstly
  # tar_target(
  #   fixed_adm1_itn_routine,
  #   itn_routine[adm1 == "CNE", adm1 := NA_character_] |>
  #     fix_adm1(fuzzy_adm1_itn_routine)
  # ),
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
    vector_resistance[
      adm1 == "RAP", adm1 :=  "Principe"][
      adm1 == "N/A" , adm1 := NA_character_] |>
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
  # tar_target(
  #   export_duplicated_adm1_adm2_shp,
  #   fwrite(duplicated_adm1_adm2_shp |> st_drop_geometry(),
  #          file = "report/01-shapefile/01-duplicated-adm1-adm2-list.csv")
  # ),
  
  
  ##### 6.3. hf -----------------------------------------------------------------
  
  ###### 6.3.1. hf in routine data -----------------------------------------------
  tar_target(
    fixed_hf_routine,
    fixed_adm1_routine |>
      mutate(
        hf = case_when(
          hf == "POSTO DE PICÃO" ~ "Picão",
          hf == "POSTO DE AEROPORTO" ~ "Aeroporto",
          hf == "POSTO DE SUNDY" ~ "Sundy",
          hf == "Centro Saude Trindade" ~ "Trindade",
          hf == "Posto saude Bombom" ~ "Bombom",
          hf == "Posto de Saude de Conde" ~ "Conde",
          hf == "POSTO DE NOVA ESTRELA" ~ "Nova Estrela",
          hf == "POSTO DE PORTO REAL" ~ "Porto Real",
          hf == "Centro de Saude de Guadalupe" ~ "Guadalupe",
          hf == "Posto de Saude de Desejada" ~ "Desejada",
          hf == "Posto de Saude de Micolo" ~ "Micolo",
          hf == "Posto de Saude de Conde" ~ "Conde",
          hf == "Centro de Saúde de Neves" ~ "Neves",
          hf == "POSTO DE PANTUFO" ~ "Pantufo",
          hf == "POSTO DE MADRE DE DEUS" ~ "Madre Deus",
          hf == "P. C. DE SANTA CECILIA" ~ "Santa Cecilia",
          hf == "POSTO DE PANTUFO" ~ "Pantufo",
          hf == "POSTO DE S. MARÇAL" ~ "São Marçal",
          hf == "P. S. DE ÁGUA IZÉ" ~ "Agua Izé",
          hf == "POSTO S. DE SANTANA" ~ "Santana",
          hf == "POSTO DE QUARTEL" ~ "Quartel",
          hf == "HOSPITAL DOUTOR QUARESMA DIAS DA GRAÇA" ~ "Hospital Principe",
          hf == "POSTO DE NOVA APOSTÓLICA" ~ "Nova Apostólica",
          hf == "POSTO DE ÁGUA ARROZ" ~ "Agua Arroz",
          hf == "P. SAÚDE DE V. D´AMÉRICA" ~ "Voz de America",
          hf == "POSTO SAÚDE DE PINHEIRA ROÇA" ~ "Pinheira Roça",
          hf == "P. S. DE RIBEIRA AFONSO" ~ "Ribeira Afonso I",
          hf == "P. S. IRMÃS C. DE R. AFONSO" ~ "Ribeira Afonso II(Sta Infancia)",
          hf == "P. VILA FERNANDA" ~ "Vila Fernanda",
          TRUE ~ hf
        )
      ) |>
      fix_hf(fuzzy_hf_from_routine)
  ),
  
  
  # 7. transform ---------------------------------------------------------------
  ##### 7.1. shapefile -----------------------------------------------------------
  ###### 7.1.1. hf ---------------------------------------------------------------
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
  tar_target(
    meta_adm2_hf,
    shp_adm2_nmcp_hf |>
      st_drop_geometry() |>
      select(adm1, adm2, hf)
  ),
  ###### 3.1.3. Method: Cross adm1: get adm1-hf level of shapefile --------------------------------
  # in this shapefile, we merge the same adm1-hf combination, and get the
  # adm1-hf level of shapefile, by using shp_adm2_nmcp_hf
  tar_target(shp_catchment,
             transform_shp_get_adm1_hf(shp_adm2_nmcp_hf)),
  
  ###### 3.1.4. Method: Within adm1: get adm1-hf level of shapefile --------------------------------
  # tar_target(shp_adm1_hf_within,
  #            transform_shp_get_adm1_hf_within(fixed_adm1_shp_adm2_nmcp, shp_hf)
  #            ),
  
  ###### 3.1.5. get adm1 by using adm2 -------------------------------------------------
  # group adm1
  tar_target(
    shp_adm1_nmcp,
    fixed_adm1_shp_adm2_nmcp |> 
      group_by(adm1) |> 
      summarise(st_union(geometry))
  ),
  # 8. link --------------------------------------------------------------------
  ##### 8.1. Routine data with HF shapefile ------------------------------------
  tar_target(
    shp_routine,
    link_hf(shp_catchment |> select(-adm1),
            fixed_hf_routine |> select(-adm1))
  ),
  tar_target(dt_routine,
             shp_routine |> st_drop_geometry() |> as.data.table()
             ),
  

  ##### 8.2. population -----------------------------------------
  # aggregate by adm1, year, 
  tar_target(
    shp_pop_adm1,
    link_adm1(
      shp_adm1_nmcp,
      fixed_adm1_estimated_population[
        ,
        .(pop = sum(.SD)), 
        by = .(adm1, year), 
        .SDcols = c(4:18)
        ]
      )
  ),
  # export shp_pop_adm1
  tar_target(
    dt_pop_adm1,
    shp_pop_adm1 |> st_drop_geometry() |> 
      fwrite("results/4-population/pop-adm1.csv")
  ),
  # export shapefile
  tar_target(
    export_shp_pop_adm1,
    shp_pop_adm1 |> 
      st_write(
        "results/4-population/pop-adm1.shp",
        crs = st_crs(4326),
        delete_dsn = TRUE
      )
  ),
  # by adm2, year
  tar_target(
    shp_pop_adm2,
    link_adm2(
      fixed_adm1_shp_adm2_nmcp,
      fixed_adm1_estimated_population_adm2
    )
  ),
  # export shp_pop_adm2
  tar_target(
    dt_pop_adm2,
    shp_pop_adm2 |> st_drop_geometry() |> 
      fwrite("results/4-population/pop-adm2.csv")
  ),
  # export shapefile
  tar_target(
    export_shp_pop_adm2,
    shp_pop_adm2 |> 
      st_write(
        "results/4-population/pop-adm2.shp",
        crs = st_crs(4326),
        delete_dsn = TRUE
        
      )
  ),
  
  # find adm2-hf list
  # based on adm2, and adm2-hf list, created hf-catchment area
  tar_target(
    shp_pop_hf,
    link_adm2_hf(
      shp_catchment,
      shp_pop_adm2 |> st_drop_geometry() |> select(
        -OBJECTID_1, -tipo, -Shape_Leng, -Shape_Area,
        -POP, -Palud
      ),
      meta_adm2_hf
    )
  ),
  
  # 9. quality checks of routine data ------------------------------------------
  ##### 9.1. test duplicate in the routine data
  tar_target(
    duplicate_routine,
    dt_routine[, .N, by = .(hf, year, month)][N > 1]
  ),
  ##### 9.1. check the reporting rate of each hf -------------------------------
  tar_target(
    report_rate_routine,
    snt::sn_ana_report_status(
      dt_routine[
        !is.na(year)][
          , year := as.numeric(year)][
            , month := as.numeric(month)][
              , date := make_date(year, month, 1)
            ],
      by_cols = c("hf", "date"),
      exclude_cols = "hf|year|month|date"
    )
  ),
  # tar_target(
  #   plot_report_rate_by_adm1, sn_plot_reprat_by_adm(
  #     report_rate_routine[,month:=1],
  #     "results/3-plot/03-report_rate_by_adm1.png"
  #   )
  # ),
 
  tar_target(
    plot_report_rate_by_hf,
    # heat map of reporting status of hf
    report_rate_routine |>
      mutate(rep = as.factor(rep)) |>
      ggplot() + 
      geom_tile(aes(x = date, y = hf, fill = rep)) + 
      scale_x_date(date_labels = "%Y-%m", guide = guide_axis(check.overlap = TRUE), date_breaks = "3 month") + 
      scale_fill_viridis_d(option = "F") + sn_theme()
  ),
  tar_target(
    save_plot_report_rate_by_hf,
    ggsave(
      "results/3-plot/03-report_rate_by_hf.png", 
      plot_report_rate_by_hf, 
      width = 16, height = 10)
  ),
  # report status table for each hf, by year, calculate the reporting rate
  tar_target(
    reporting_rate_hf,
    report_rate_routine[,
                        .(year = year(date),
                          hf,
                          rep)
    ][
      , .(rep = sum(rep) / .N),
      by = .(hf, year)
    ] |> 
      # make it wider
      dcast(hf ~ year, value.var = "rep") 
  ),
  # plot the reporting rate of each hf
  tar_target(
    plot_reporting_rate_hf,
    reporting_rate_hf |> 
      # wide to long
      melt(id.vars = "hf") |>
      ggplot() + 
      geom_tile(aes(x = variable, y = hf, color = value, fill = value)) + 
      scale_color_viridis_c() + scale_fill_viridis_c()+ sn_theme()
  ),
  tar_target(
    save_plot_reporting_rate_hf,
    ggsave(
      "results/3-plot/03-plot_reporting_rate_hf.png", 
      plot_reporting_rate_hf,
      width = 16, height = 10)
  ),
  ##### 9.2. report rate by index -----------------------------------------------
  tar_target(
    report_rate_routine_index_1, sn_ana_report_rate(
      dt_routine[!is.na(year)][, year := as.numeric(year)][, month := as.numeric(month)],
      on = "index",
      # "alladm"      
      # [5] "alladm_u5"    "alladm_ov5"   "alladm_p"     "susp"        
      # [9] "susp_u5"      "susp_ov5"     "susp_p"       "test"        
      # [13] "test_u5"      "test_ov5"     "test_p"       "conf"        
      # [17] "conf_u5"      "conf_ov5"     "conf_p"       "negative"    
      # [21] "negative_u5"  "negative_ov5" "negative_p"   "treat"       
      # [25] "treat_u5"     "treat_ov5"    "treat_p"      "maladm"      
      # [29] "maladm_u5"    "maladm_ov5"   "maladm_p"     "severe"      
      # [33] "severe_u5"    "severe_ov5"   "severe_p"     "alldth"      
      # [37] "alldth_u5"    "alldth_ov5"   "alldth_p"     "maldth"      
      # [41] "maldth_u5"    "maldth_ov5"   "maldth_p"   
      col = c(
        "alladm",
        "alladm_u5",
        "alladm_ov5",
        "alladm_p",
        "susp",
        "susp_u5",
        "susp_ov5",
        "susp_p",
        "test",
        "test_u5",
        "test_ov5",
        "test_p",
        "conf",
        "conf_u5",
        "conf_ov5",
        "conf_p",
        "negative",
        "negative_u5",
        "negative_ov5",
        "negative_p",
        "treat",
        "treat_u5",
        "treat_ov5",
        "treat_p",
        "maladm",
        "maladm_u5",
        "maladm_ov5",
        "maladm_p"
      ),
      by_cols = c("year", "month"),
      meta_adm = c("adm1", "hf"),
      meta_date = c("year", "month"),
      exclude_cols = "adm1|hf|year|month"
    )
  ),
  tar_target(
    plot_report_rate_by_index_1, sn_plot_reprat_by_index_fixed(
      report_rate_routine_index_1,
      "results/3-plot/03-report_rate_by_index_1.png"
    )
  ),
 
       
  tar_target(
    report_rate_routine_index_2, sn_ana_report_rate(
      dt_routine[!is.na(year)][, year := as.numeric(year)][, month := as.numeric(month)],
      on = "index",
      # "alladm"      
      # [5] "alladm_u5"    "alladm_ov5"   "alladm_p"     "susp"        
      # [9] "susp_u5"      "susp_ov5"     "susp_p"       "test"        
      # [13] "test_u5"      "test_ov5"     "test_p"       "conf"        
      # [17] "conf_u5"      "conf_ov5"     "conf_p"       "negative"    
      # [21] "negative_u5"  "negative_ov5" "negative_p"   "treat"       
      # [25] "treat_u5"     "treat_ov5"    "treat_p"      "maladm"      
      # [29] "maladm_u5"    "maladm_ov5"   "maladm_p"     "severe"      
      # [33] "severe_u5"    "severe_ov5"   "severe_p"     "alldth"      
      # [37] "alldth_u5"    "alldth_ov5"   "alldth_p"     "maldth"      
      # [41] "maldth_u5"    "maldth_ov5"   "maldth_p"   
      col = c(
        "severe",
        "severe_u5",
        "severe_ov5",
        "severe_p",
        
        "alldth",
        "alldth_u5",
        "alldth_ov5",
        "alldth_p",
        
        "maldth",
        "maldth_u5",
        "maldth_ov5",
        "maldth_p"
        
          
      ),
      by_cols = c("year", "month"),
      meta_adm = c("adm1", "hf"),
      meta_date = c("year", "month"),
      exclude_cols = "adm1|hf|year|month|adm2|type|owner|lat|long|comment"
    )
  ),
  tar_target(
    plot_report_rate_by_index_2, sn_plot_reprat_by_index_fixed(
      report_rate_routine_index_2,
      "results/3-plot/03-report_rate_by_index_2.png"
    )
  ),
  
  tar_target(
    report_rate_routine_index_1_ps, sn_ana_report_rate(
      dt_routine[!is.na(year)
                 ][
                   , year := as.numeric(year)][
                     , month := as.numeric(month)][
                       hf,
                       on = "hf"
                     ][
                       type == "Posto Saúde"
                     ],
      on = "index",
      # "alladm"      
      # [5] "alladm_u5"    "alladm_ov5"   "alladm_p"     "susp"        
      # [9] "susp_u5"      "susp_ov5"     "susp_p"       "test"        
      # [13] "test_u5"      "test_ov5"     "test_p"       "conf"        
      # [17] "conf_u5"      "conf_ov5"     "conf_p"       "negative"    
      # [21] "negative_u5"  "negative_ov5" "negative_p"   "treat"       
      # [25] "treat_u5"     "treat_ov5"    "treat_p"      "maladm"      
      # [29] "maladm_u5"    "maladm_ov5"   "maladm_p"     "severe"      
      # [33] "severe_u5"    "severe_ov5"   "severe_p"     "alldth"      
      # [37] "alldth_u5"    "alldth_ov5"   "alldth_p"     "maldth"      
      # [41] "maldth_u5"    "maldth_ov5"   "maldth_p"   
      col = c(
        "alladm",
        "alladm_u5",
        "alladm_ov5",
        "alladm_p",
        "susp",
        "susp_u5",
        "susp_ov5",
        "susp_p",
        "test",
        "test_u5",
        "test_ov5",
        "test_p",
        "conf",
        "conf_u5",
        "conf_ov5",
        "conf_p",
        "negative",
        "negative_u5",
        "negative_ov5",
        "negative_p",
        "treat",
        "treat_u5",
        "treat_ov5",
        "treat_p",
        "maladm",
        "maladm_u5",
        "maladm_ov5",
        "maladm_p"
      ),
      by_cols = c("year", "month"),
      meta_adm = c("adm1", "hf"),
      meta_date = c("year", "month"),
      exclude_cols = "adm1|hf|year|month|adm2|type|owner|lat|long|comment"
    )
  ),
  tar_target(
    plot_report_rate_by_index_1_ps, sn_plot_reprat_by_index_fixed(
      report_rate_routine_index_1_ps,
      "results/3-plot/03-report_rate_by_index_1_ps.png"
    )
  ),
  
  
  tar_target(
    report_rate_routine_index_2_ps, sn_ana_report_rate(
      dt_routine[!is.na(year)][, year := as.numeric(year)][, month := as.numeric(month)][
        hf,
        on = "hf"
      ][
        type == "Posto Saúde"
      ],
      on = "index",
      # "alladm"      
      # [5] "alladm_u5"    "alladm_ov5"   "alladm_p"     "susp"        
      # [9] "susp_u5"      "susp_ov5"     "susp_p"       "test"        
      # [13] "test_u5"      "test_ov5"     "test_p"       "conf"        
      # [17] "conf_u5"      "conf_ov5"     "conf_p"       "negative"    
      # [21] "negative_u5"  "negative_ov5" "negative_p"   "treat"       
      # [25] "treat_u5"     "treat_ov5"    "treat_p"      "maladm"      
      # [29] "maladm_u5"    "maladm_ov5"   "maladm_p"     "severe"      
      # [33] "severe_u5"    "severe_ov5"   "severe_p"     "alldth"      
      # [37] "alldth_u5"    "alldth_ov5"   "alldth_p"     "maldth"      
      # [41] "maldth_u5"    "maldth_ov5"   "maldth_p"   
      col = c(
        "severe",
        "severe_u5",
        "severe_ov5",
        "severe_p",
        
        "alldth",
        "alldth_u5",
        "alldth_ov5",
        "alldth_p",
        
        "maldth",
        "maldth_u5",
        "maldth_ov5",
        "maldth_p"
        
        
      ),
      by_cols = c("year", "month"),
      meta_adm = c("adm1", "hf"),
      meta_date = c("year", "month"),
      exclude_cols = "adm1|hf|year|month|adm2|type|owner|lat|long|comment"
    )
  ),
  tar_target(
    plot_report_rate_by_index_2_ps, sn_plot_reprat_by_index_fixed(
      report_rate_routine_index_2_ps,
      "results/3-plot/03-report_rate_by_index_2_ps.png"
    )
  ),
  
  tar_target(
    report_rate_routine_index_1_cs, sn_ana_report_rate(
      dt_routine[!is.na(year)][, year := as.numeric(year)][, month := as.numeric(month)][
        hf,
        on = "hf"
      ][
        type == "Centro Saúde"
      ],
      on = "index",
      # "alladm"      
      # [5] "alladm_u5"    "alladm_ov5"   "alladm_p"     "susp"        
      # [9] "susp_u5"      "susp_ov5"     "susp_p"       "test"        
      # [13] "test_u5"      "test_ov5"     "test_p"       "conf"        
      # [17] "conf_u5"      "conf_ov5"     "conf_p"       "negative"    
      # [21] "negative_u5"  "negative_ov5" "negative_p"   "treat"       
      # [25] "treat_u5"     "treat_ov5"    "treat_p"      "maladm"      
      # [29] "maladm_u5"    "maladm_ov5"   "maladm_p"     "severe"      
      # [33] "severe_u5"    "severe_ov5"   "severe_p"     "alldth"      
      # [37] "alldth_u5"    "alldth_ov5"   "alldth_p"     "maldth"      
      # [41] "maldth_u5"    "maldth_ov5"   "maldth_p"   
      col = c(
        "alladm",
        "alladm_u5",
        "alladm_ov5",
        "alladm_p",
        "susp",
        "susp_u5",
        "susp_ov5",
        "susp_p",
        "test",
        "test_u5",
        "test_ov5",
        "test_p",
        "conf",
        "conf_u5",
        "conf_ov5",
        "conf_p",
        "negative",
        "negative_u5",
        "negative_ov5",
        "negative_p",
        "treat",
        "treat_u5",
        "treat_ov5",
        "treat_p",
        "maladm",
        "maladm_u5",
        "maladm_ov5",
        "maladm_p"
      ),
      by_cols = c("year", "month"),
      meta_adm = c("adm1", "hf"),
      meta_date = c("year", "month"),
      exclude_cols = "adm1|hf|year|month|adm2|type|owner|lat|long|comment"
    )
  ),
  tar_target(
    plot_report_rate_by_index_1_cs, sn_plot_reprat_by_index_fixed(
      report_rate_routine_index_1_cs,
      "results/3-plot/03-report_rate_by_index_1_cs.png"
    )
  ),
  
  
  tar_target(
    report_rate_routine_index_2_cs, sn_ana_report_rate(
      dt_routine[!is.na(year)][, year := as.numeric(year)][, month := as.numeric(month)][
        hf,
        on = "hf"
      ][
        type == "Centro Saúde"
      ],
      on = "index",
      # "alladm"      
      # [5] "alladm_u5"    "alladm_ov5"   "alladm_p"     "susp"        
      # [9] "susp_u5"      "susp_ov5"     "susp_p"       "test"        
      # [13] "test_u5"      "test_ov5"     "test_p"       "conf"        
      # [17] "conf_u5"      "conf_ov5"     "conf_p"       "negative"    
      # [21] "negative_u5"  "negative_ov5" "negative_p"   "treat"       
      # [25] "treat_u5"     "treat_ov5"    "treat_p"      "maladm"      
      # [29] "maladm_u5"    "maladm_ov5"   "maladm_p"     "severe"      
      # [33] "severe_u5"    "severe_ov5"   "severe_p"     "alldth"      
      # [37] "alldth_u5"    "alldth_ov5"   "alldth_p"     "maldth"      
      # [41] "maldth_u5"    "maldth_ov5"   "maldth_p"   
      col = c(
        "severe",
        "severe_u5",
        "severe_ov5",
        "severe_p",
        
        "alldth",
        "alldth_u5",
        "alldth_ov5",
        "alldth_p",
        
        "maldth",
        "maldth_u5",
        "maldth_ov5",
        "maldth_p"
        
        
      ),
      by_cols = c("year", "month"),
      meta_adm = c("adm1", "hf"),
      meta_date = c("year", "month"),
      exclude_cols = "adm1|hf|year|month|adm2|type|owner|lat|long|comment"
    )
  ),
  tar_target(
    plot_report_rate_by_index_2_cs, sn_plot_reprat_by_index_fixed(
      report_rate_routine_index_2_cs,
      "results/3-plot/03-report_rate_by_index_2_cs.png"
    )
  ),
  
  tar_target(
    report_rate_routine_index_1_h, sn_ana_report_rate(
      dt_routine[!is.na(year)][, year := as.numeric(year)][, month := as.numeric(month)][
        hf,
        on = "hf"
      ][
        type == "Hospital"
      ],
      on = "index",
      # "alladm"      
      # [5] "alladm_u5"    "alladm_ov5"   "alladm_p"     "susp"        
      # [9] "susp_u5"      "susp_ov5"     "susp_p"       "test"        
      # [13] "test_u5"      "test_ov5"     "test_p"       "conf"        
      # [17] "conf_u5"      "conf_ov5"     "conf_p"       "negative"    
      # [21] "negative_u5"  "negative_ov5" "negative_p"   "treat"       
      # [25] "treat_u5"     "treat_ov5"    "treat_p"      "maladm"      
      # [29] "maladm_u5"    "maladm_ov5"   "maladm_p"     "severe"      
      # [33] "severe_u5"    "severe_ov5"   "severe_p"     "alldth"      
      # [37] "alldth_u5"    "alldth_ov5"   "alldth_p"     "maldth"      
      # [41] "maldth_u5"    "maldth_ov5"   "maldth_p"   
      col = c(
        "alladm",
        "alladm_u5",
        "alladm_ov5",
        "alladm_p",
        "susp",
        "susp_u5",
        "susp_ov5",
        "susp_p",
        "test",
        "test_u5",
        "test_ov5",
        "test_p",
        "conf",
        "conf_u5",
        "conf_ov5",
        "conf_p",
        "negative",
        "negative_u5",
        "negative_ov5",
        "negative_p",
        "treat",
        "treat_u5",
        "treat_ov5",
        "treat_p",
        "maladm",
        "maladm_u5",
        "maladm_ov5",
        "maladm_p"
      ),
      by_cols = c("year", "month"),
      meta_adm = c("adm1", "hf"),
      meta_date = c("year", "month"),
      exclude_cols = "adm1|hf|year|month|adm2|type|owner|lat|long|comment"
    )
  ),
  tar_target(
    plot_report_rate_by_index_1_h, sn_plot_reprat_by_index_fixed(
      report_rate_routine_index_1_h,
      "results/3-plot/03-report_rate_by_index_1_h.png"
    )
  ),
  
  
  tar_target(
    report_rate_routine_index_2_h, sn_ana_report_rate(
      dt_routine[!is.na(year)][, year := as.numeric(year)][, month := as.numeric(month)][
        hf,
        on = "hf"
      ][
        type == "Hospital"
      ],
      on = "index",
      # "alladm"      
      # [5] "alladm_u5"    "alladm_ov5"   "alladm_p"     "susp"        
      # [9] "susp_u5"      "susp_ov5"     "susp_p"       "test"        
      # [13] "test_u5"      "test_ov5"     "test_p"       "conf"        
      # [17] "conf_u5"      "conf_ov5"     "conf_p"       "negative"    
      # [21] "negative_u5"  "negative_ov5" "negative_p"   "treat"       
      # [25] "treat_u5"     "treat_ov5"    "treat_p"      "maladm"      
      # [29] "maladm_u5"    "maladm_ov5"   "maladm_p"     "severe"      
      # [33] "severe_u5"    "severe_ov5"   "severe_p"     "alldth"      
      # [37] "alldth_u5"    "alldth_ov5"   "alldth_p"     "maldth"      
      # [41] "maldth_u5"    "maldth_ov5"   "maldth_p"   
      col = c(
        "severe",
        "severe_u5",
        "severe_ov5",
        "severe_p",
        
        "alldth",
        "alldth_u5",
        "alldth_ov5",
        "alldth_p",
        
        "maldth",
        "maldth_u5",
        "maldth_ov5",
        "maldth_p"
        
        
      ),
      by_cols = c("year", "month"),
      meta_adm = c("adm1", "hf"),
      meta_date = c("year", "month"),
      exclude_cols = "adm1|hf|year|month|adm2|type|owner|lat|long|comment"
    )
  ),
  tar_target(
    plot_report_rate_by_index_2_h, sn_plot_reprat_by_index_fixed(
      report_rate_routine_index_2_h,
      "results/3-plot/03-report_rate_by_index_2_h.png"
    )
  ),
  
  
  # tar_target(
  #   report_status_routine,
  #   sn_ana_report_status(dt_routine[!is.na(year)][, year:= as.numeric(year)][, month := as.numeric(month)],
  #                      on = "adm",
  #                      meta_adm = c("adm1", "hf"),
  #                      meta_date = c("year", "month"),
  #                      exclude_cols = "adm1|hf|year|month",
  #                      by_cols = NULL
  #   )
  # ),
  
  ##### 9.3. outliers -----------------------------------------------------------
  
  tar_target(
    outliers_routine_1,
    sn_plot_outliers_improved(
      dt_routine,
      #  [9] "susp"                                         
      # [10] "susp_u5"                                      
      # [11] "susp_ov5"                                     
      # [12] "susp_p"                                       
      # [13] "test"                                         
      # [14] "test_u5"                                      
      # [15] "test_ov5"                                     
      # [16] "test_p"                                       
      # [17] "conf"                                         
      # [18] "conf_u5"                                      
      # [19] "conf_ov5"                                     
      # [20] "conf_p" 
      "susp", "susp_u5", "susp_ov5", "susp_p", 
      "test", "test_u5", "test_ov5", "test_p"
    )
  ),
  tar_target(
    export_outliers_routine_1,
    ggsave(
      "results/3-plot/04-outliers_routine_1.png",
      outliers_routine_1,
      width = 10, height = 3
    )
  ),

  # [21] "negative"                                     
  # [22] "negative_u5"                                  
  # [23] "negative_ov5"                                 
  # [24] "negative_p"                                   
  # [25] "treat"                                        
  # [26] "treat_u5"                                     
  # [27] "treat_ov5"                                    
  # [28] "treat_p"                                      
  # [29] "maladm"                                       
  # [30] "maladm_u5"                                    
  # [31] "maladm_ov5"                                   
  # [32] "maladm_p"                                     
  tar_target(
    outliers_routine_2,
    sn_plot_outliers_improved(
      dt_routine,
      "negative", "negative_u5", "negative_ov5", "negative_p", 
      "maladm", "maladm_u5", "maladm_ov5", "maladm_p"
    )
  ),
  tar_target(
    export_outliers_routine_2,
    ggsave(
      "results/3-plot/04-outliers_routine_2.png",
      outliers_routine_2,
      width = 10, height = 3
    )
  ),
  
  # [33] "severe"                                       
  # [34] "severe_u5"                                    
  # [35] "severe_ov5"                                   
  # [36] "severe_p"                                     
  # [37] "alldth"                                       
  # [38] "alldth_u5"                                    
  # [39] "alldth_ov5"                                   
  # [40] "alldth_p"                                     
  # [41] "maldth"                                       
  # [42] "maldth_u5"                                    
  # [43] "maldth_ov5"                                   
  # [44] "maldth_p"                                     
  tar_target(
    outliers_routine_31,
    sn_plot_outliers_improved(
      dt_routine,
     "conf", "conf_u5", "conf_ov5", "conf_p",
     "severe", "severe_u5", "severe_ov5", "severe_p",
     "treat", "treat_u5", "treat_ov5", "treat_p"
    )
  ),
  tar_target(
    export_outliers_routine_31,
    ggsave(
      "results/3-plot/04-outliers_routine_31.png",
      outliers_routine_31,
      width = 10, height = 4
    )
  ),
  tar_target(
    outliers_routine_32,
    sn_plot_outliers_improved(
      dt_routine,
      "alldth", "alldth_u5", "alldth_ov5", "alldth_p", 
      "maldth", "maldth_u5", "maldth_ov5", "maldth_p"
    )
  ),
  tar_target(
    export_outliers_routine_32,
    ggsave(
      "results/3-plot/04-outliers_routine_32.png",
      outliers_routine_32,
      width = 10, height = 2
    )
  ),
  # bookmark
  tar_target(
    outliers_routine_4,
    sn_plot_outliers_improved(
      fixed_adm1_routine_intervention,
      "anc1", "anc2", "anc3", "anc4", "ipt1", "ipt2", "ipt3", 
      "ipt4", "itn_p", "itn_v", "stock"
    )
  ),
  tar_target(
    export_outliers_routine_4,
    ggsave(
      "results/3-plot/04-outliers_routine_4.png",
      outliers_routine_4,
      width = 10, height = 6
    )
  ),

  ##### 4. consistency ------------------------------------------------------------------------------------------------

  ###### 4.1. routine ------------------------------------------------------------------------------------------------
  
  # use snt package to plot out consistency
  tar_target(
    plot_routine_consistency_1,
    sn_plot_consistency(
      dt_routine,
      "test", "susp"
    )
  ),
  tar_target(
    save_plot_routine_consistency_1,
    ggsave(
      "results/3-plot/05-plot_routine_consistency_1.png", 
      plot_routine_consistency_1,
      width = 8, height = 6
    ),
    format = "file"
  ),
  tar_target(
    plot_routine_consistency_2,
    snt::sn_plot_consistency(
      dt_routine,
      "treat", "conf"
    )
  ),
  tar_target(
    save_plot_routine_consistency_2,
    ggsave(
      "results/3-plot/05-plot_routine_consistency_2.png", 
      plot_routine_consistency_2,
      width = 8, height = 6
    ),
    format = "file"
  ),
  tar_target(
    plot_routine_consistency_3,
    snt::sn_plot_consistency(
      dt_routine,
      "maladm", "alladm"
    )
  ),
  tar_target(
    save_plot_routine_consistency_3,
    ggsave(
      "results/3-plot/05-plot_routine_consistency_3.png", 
      plot_routine_consistency_3,
      width = 8, height = 6
    ),
    format = "file"
  ),
  tar_target(
    plot_routine_consistency_4,
    snt::sn_plot_consistency(
      dt_routine,
      "negative", "test"
    )
  ),
  tar_target(
    save_plot_routine_consistency_4,
    ggsave(
      "results/3-plot/05-plot_routine_consistency_4.png", 
      plot_routine_consistency_4,
      width = 8, height = 6
    ),
    format = "file"
  ),
  tar_target(
    plot_routine_consistency_5,
    snt::sn_plot_consistency(
      dt_routine,
      "treat", "maladm"
    )
  ),
  tar_target(
    save_plot_routine_consistency_5,
    ggsave(
      "results/3-plot/05-plot_routine_consistency_5.png", 
      plot_routine_consistency_5,
      width = 8, height = 6
    ),
    format = "file"
  ),
  tar_target(
    plot_routine_consistency_6,
    snt::sn_plot_consistency(
      dt_routine,
      "maldth", "alldth"
    )
  ),
  tar_target(
    save_plot_routine_consistency_6,
    ggsave(
      "results/3-plot/05-plot_routine_consistency_6.png", 
      plot_routine_consistency_6,
      width = 8, height = 6
    ),
    format = "file"
  ),
  
  ###### 4.2. intervention ------------------------------------------------------------------------------------------------
  
  tar_target(
    plot_intervention_consistency_1,
    snt::sn_plot_consistency(
      fixed_adm1_routine_intervention,
      "anc1","anc2"
    )
  ),
  tar_target(
    save_plot_intervention_consistency_1,
    ggsave(
      "results/3-plot/05-plot_intervention_consistency_1.png", 
      plot_intervention_consistency_1,
      width = 8, height = 6
    ),
    format = "file"
  ),
  
  tar_target(
    plot_intervention_consistency_2,
    snt::sn_plot_consistency(
      fixed_adm1_routine_intervention,
      "anc2", "anc3"
    )
  ),
  tar_target(
    save_plot_intervention_consistency_2,
    ggsave(
      "results/3-plot/05-plot_intervention_consistency_2.png", 
      plot_intervention_consistency_2,
      width = 8, height = 6
    ),
    format = "file"
  ),
  
  tar_target(
    plot_intervention_consistency_4,
    snt::sn_plot_consistency(
      fixed_adm1_routine_intervention,
      "ipt1", "ipt2"
    )
  ),
  tar_target(
    save_plot_intervention_consistency_4,
    ggsave(
      "results/3-plot/05-plot_intervention_consistency_4.png", 
      plot_intervention_consistency_4,
      width = 8, height = 6
    ),
    format = "file"
  ),
  
  tar_target(
    plot_intervention_consistency_5,
    snt::sn_plot_consistency(
      fixed_adm1_routine_intervention,
      "ipt2","ipt3"
    )
  ),
  tar_target(
    save_plot_intervention_consistency_5,
    ggsave(
      "results/3-plot/05-plot_intervention_consistency_5.png", 
      plot_intervention_consistency_5,
      width = 8, height = 6
    ),
    format = "file"
  ),
  
  tar_target(
    plot_intervention_consistency_6,
    snt::sn_plot_consistency(
      fixed_adm1_routine_intervention,
      "anc1", "ipt1"
    )
  ),
  tar_target(
    save_plot_intervention_consistency_6,
    ggsave(
      "results/3-plot/05-plot_intervention_consistency_6.png", 
      plot_intervention_consistency_6,
      width = 8, height = 6
    ),
    format = "file"
  ),
  
  tar_target(
    plot_intervention_consistency_7,
    snt::sn_plot_consistency(
      fixed_adm1_routine_intervention,
      "anc2", "ipt2"
    )
  ),
  tar_target(
    save_plot_intervention_consistency_7,
    ggsave(
      "results/3-plot/05-plot_intervention_consistency_7.png", 
      plot_intervention_consistency_7,
      width = 8, height = 6
    ),
    format = "file"
  ),
  
  tar_target(
    plot_intervention_consistency_8,
    snt::sn_plot_consistency(
      fixed_adm1_routine_intervention,
      "anc3", "ipt3"
    )
  ),
  tar_target(
    save_plot_intervention_consistency_8,
    ggsave(
      "results/3-plot/05-plot_intervention_consistency_8.png", 
      plot_intervention_consistency_8,
      width = 8, height = 6
    ),
    format = "file"
  ),
  
  # 10. export ------------------------------------------------------------------
  ##### 1. shapefile ---------------------------------------------------------
  ###### 1.1. hf -------------------------------------------------------------
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
  ###### 1.2. adm2_nmcp ------------------------------------------------------
  # export adm2_nmcp shapefile
  tar_target(
    export_shp_adm1_hf,
    st_write(
      shp_catchment |> st_make_valid() |>
        st_simplify(dTolerance = 0.001, preserveTopology = TRUE),
      "results/2-shapefile/shp_catchment.shp",
      crs = st_crs(4326),
      delete_dsn = TRUE
    )
  ),
  
  # export adm1-adm2 table
  tar_target(
    export_adm1_adm2_list_nmcp,
    adm1_adm2_nmcp |> 
      fwrite("results/2-shapefile/adm1_adm2_list_nmcp.csv")
  ),
  
  # 11. plot ----------------------------------------------------------------
  ###### 1. adm1 pop ---------------------------------------------------------
  # plot shp_adm1_pop, by facet year, using tmap, plot in one map
  tar_target(
    plot_adm1_pop,
    shp_pop_adm1 |>
      tm_shape() +
      tm_borders() +
      tm_polygons(col = c("pop")) +
      tm_facets(by = "year")
  ),
  tar_target(
    save_plot_adm1_pop,
    plot_adm1_pop |> 
      tmap_save("results/3-plot/01-plot_adm1_pop.png", width = 10, height = 5)
  ),
  
  # plot pop adm1 by year, with stacked bar chart
  tar_target(
    plot_adm1_pop_bar,
    shp_pop_adm1 |>
      ggplot(aes(x = year, y = pop, fill = adm1)) +
      geom_bar(stat = "identity") +
      sn_theme() +
      # use 
      # change y axis label to population
      ylab("Population")
  ),
  # export the plot
  tar_target(
    save_plot_adm1_pop_bar,
    ggsave("results/3-plot/02-plot_adm1_pop_bar.png", 
           plot_adm1_pop_bar,
             width = 10, height = 5),
    format = "file"
  ),
  
  # pyremid plot
  tar_target(
    pyremid_plot_pop,
    pyremid_plot(fixed_adm1_estimated_population)
  ),
  # export the plot
  tar_target(
    save_pyremid_plot_pop,
    ggsave("results/3-plot/02-plot_pyremid_plot_pop.png", 
           pyremid_plot_pop,
           width = 10, height = 10),
    format = "file"
  ),
  
  ##### 2. routine -----------------------------------------------------------------

  # plot a heatmap for showing the conf data from dt_routine
  tar_target(
    plot_conf_heatmap,
    dt_routine[, date := make_date(year, month, 1)][] |>
      ggplot() +
      geom_tile(aes(
        x = .data$date,
        y = .data$hf,
        fill = .data$conf
      )) + scale_x_date(
        date_labels = "%Y",
        guide = guide_axis(check.overlap = TRUE),
        date_breaks = "1 year"
      ) +
      scale_fill_viridis_c() + sn_theme() 
  ),
  # export the plot
  tar_target(
    save_plot_conf_heatmap,
    ggsave(
      "results/3-plot/05-plot_conf_heatmap.png", 
      plot_conf_heatmap,
      width = 16, height = 9
      ),
    format = "file"
  ),
  
  # bar plot of confirmed cases
  tar_target(
    barplot_routine_conf,
    dt_routine[, date := make_date(year, month, 1)][# summarise conf by date
      , .(conf = sum(conf, na.rm = TRUE)),
      by = .(date)] |>
      ggplot() +
      geom_col(aes(x = .data$date,
                   y = .data$conf)) + scale_x_date(
                     date_labels = "%Y-%m",
                     guide = guide_axis(check.overlap = TRUE),
                     date_breaks = "2 month"
                   ) +
      scale_fill_viridis_c() + sn_theme() 
  ),
  tar_target(
    save_barplot_routine_conf,
    ggsave(
      "results/3-plot/05-barplot_routine_conf.png", 
      barplot_routine_conf,
      width = 21, height = 9
    ),
    format = "file"
  ),
  
  # plot shp_routine, by facet year, using tmap, plot in one map
  tar_target(
    plot_routine,
    shp_routine |>
      tm_shape() +
      tm_borders() +
      tm_polygons(col=c("routine")) +
      tm_facets(by="year")
  ),
  
  # shapefile for routine data
  tar_target(
    shp_routine_hf,
    shp_hf |> left_join(
      dt_routine, by = c("hf")
    ) |> 
      st_write(
        "results/2-shapefile/shp_routine_hf.shp",
        crs = st_crs(4326),
        append=FALSE
      )
  ),
  # export shp_routine_hf
  tar_target(
    save_shp_routine_hf,
    shp_routine_hf 
  ),
  
  # tmap_animation for conf cases by month
  # tar_target(
  #   plot_routine_animation,
  #   shp_routine |> 
  #     mutate(year_month = as.Date(paste0(year, "-", month, "-01"))) |>
  #     tm_shape() +
  #     tm_borders() +
  #     tm_polygons("conf") +
  #     tm_facets_wrap("year_month")
  # ),
  # tar_target(
  #   save_animation_plot_routine,
  #   tmap_animation(tm = plot_routine_animation, 
  #                  filename = "results/3-plot/05-plot_routine_animation.gif",
  #                  dpi = 300,
  #                  width = 16, height = 9,
  #                  delay = 40)
  # ),
        # filename = "results/3-plot/05-plot_routine_animation.gif",
        # width = 800, height = 600, delay = 0.5
  
  ###### 2.1. analysis -------
  tar_target(
    plot_conf_outof_outpatient,
    dt_routine[
      adm2_hf[, .(adm1, hf)] |> unique(), on = "hf" 
    ][
      , date := lubridate::make_date(year, month, 1)
    ][,
       .(
         conf = sum(conf, na.rm = TRUE),
         susp = sum(susp, na.rm = TRUE)
       ),
       by = .(adm1, hf, date)][,
                                      .(
                                        ratio_conf_susp = conf / susp,
                                        adm1,
                                        hf,
                                        date
                                      )] |>
    # Line graphs showing trends per HF. There should be one graph per district with many lines showing the trends per HF (Yaxis=%, Xaxis=month-year)
      ggplot(aes(x = date, y = ratio_conf_susp, group = hf, color = hf)) +
      geom_line() +
      facet_wrap(~adm1, ncol = 2) +
      labs(title = "Ratio of confirmed to suspected cases",
           subtitle = "Outpatient cases",
           x = "date",
           y = "Ratio") +
      sn_theme() +
      theme(legend.position = "none")
  ),
  tar_target(
    # save
    save_plot_conf_outof_outpatient,
    ggsave(
      "results/3-plot/05-plot_conf_outof_outpatient.png", 
      plot_conf_outof_outpatient,
      width = 10, height = 6
  ),
  format = "file"
  ),
  
  tar_target(
    plot_conf_outof_outpatient_u5,
    dt_routine[
      adm2_hf[, .(adm1, hf)] |> unique(), on = "hf" 
    ][
      , date := lubridate::make_date(year, month, 1)
    ][,
      .(
        conf_u5 = sum(conf_u5, na.rm = TRUE),
        susp_u5 = sum(susp_u5, na.rm = TRUE)
      ),
      by = .(adm1, hf, date)
      ][,
        .(
        ratio_conf_susp_u5 = conf_u5 / susp_u5,
                                adm1,
                                hf,
                                date
                              )] |>
      # Line graphs showing trends per HF. There should be one graph per district with many lines showing the trends per HF (Yaxis=%, Xaxis=month-year)
      ggplot(aes(x = date, y = ratio_conf_susp_u5, group = hf, color = hf)) +
      geom_line() +
      facet_wrap(~adm1, ncol = 2) +
      labs(title = "Ratio of confirmed to suspected cases under 5",
           subtitle = "Outpatient cases",
           x = "date",
           y = "Ratio") +
      # do not plot label
      sn_theme() +
      theme(legend.position = "none")
  ),
  tar_target(
    save_plot_conf_outof_outpatient_u5,
    ggsave(
      "results/3-plot/05-plot_conf_outof_outpatient_u5.png", 
      plot_conf_outof_outpatient_u5,
      width = 10, height = 6
    ),
    format = "file"
  ),
    tar_target(
      plot_conf_outof_outpatient_ov5,
      dt_routine[
        adm2_hf[, .(adm1, hf)] |> unique(), on = "hf" 
      ][
        , date := lubridate::make_date(year, month, 1)
      ][,
        .(
          conf_ov5 = sum(conf_ov5, na.rm = TRUE),
          susp_ov5 = sum(susp_ov5, na.rm = TRUE)
        ),
        by = .(adm1, hf, date)][,
                                .(
                                  ratio_conf_susp_ov5 = conf_ov5 / susp_ov5,
                                  adm1,
                                  hf,
                                  date
                                )] |>
        # Line graphs showing trends per HF. There should be one graph per district with many lines showing the trends per HF (Yaxis=%, Xaxis=month-year)
        ggplot(aes(x = date, y = ratio_conf_susp_ov5, group = hf, color = hf)) +
        geom_line() +
        facet_wrap(~adm1, ncol = 2) +
        labs(title = "Ratio of confirmed to suspected cases over 5",
             subtitle = "Outpatient cases",
             x = "date",
             y = "Ratio") +
        sn_theme() +
        theme(legend.position = "none")
    ),
    tar_target(
      # save
      save_plot_conf_outof_outpatient_ov5,
      ggsave(
        "results/3-plot/05-plot_conf_outof_outpatient_ov5.png", 
        plot_conf_outof_outpatient_ov5,
        width = 10, height = 6
      ),
      format = "file"
      ),
  

  ##### Maps of number of malaria patients per month for all ages ---------------
  tar_target(
    plot_map_malaria_cases,
    shp_routine |> mutate(
      date = lubridate::make_date(year, month, 1)
    ) |> 
      group_by(hf, year) |>
      summarise(case = sum(conf, na.rm = TRUE), 
                .groups = "drop"
                ) |>
      tm_shape() +
      tm_polygons(
        fill = "case", 
        fill.legend = tm_legend(
          title = "Confirmed Cases"
        )
      ) +
      tm_facets_wrap("year", nrow = 1)
  ),
  
  tar_target(
    save_plot_map_malaria_cases,
    tmap::tmap_save(
      tm = plot_map_malaria_cases,
      filename = "results/3-plot/09-plot_map_malaria_cases.png",
      dpi = 300,
      width = 16, height = 8
    )
  ),
  
  
  ##### 3. passive cases ------------
  tar_target(
    plot_passive_bar_by_year,
    fixed_adm1_passive_cases |>
      ggdensity(x = "age",
                add = "mean", rug = TRUE,
                color = "adm1", fill = "adm1")
      
  ),
  tar_target(
    save_plot_passive_bar_by_year,
    ggsave(
      "results/3-plot/06-plot_passive_age_distribution.png", 
      plot_passive_bar_by_year,
      width = 10, height = 6
    ),
    format = "file"      
  ),
  tar_target(
    plot_passive_bar_by_sex,
    fixed_adm1_passive_cases |>
      gghistogram(x = "age",
                  add = "mean", rug = TRUE,
                  color = "sex", fill = "sex",
                  palette = c("#00AFBB", "#E7B800"))
  ),
  tar_target(
    save_plot_passive_bar_by_sex,
    ggsave(
      "results/3-plot/06-plot_passive_sex_distribution.png", 
      plot_passive_bar_by_sex,
      width = 10, height = 6
    ),
    format = "file"      
  ),
  tar_target(
    barplot_passive_by_adm1,
    fixed_adm1_passive_cases[
      , age_group := ifelse(age <= 5, "Under 5", "Over 5")][
      # summarise cases by sex and age group(over 5 and under 5) for each adm1
      , .N, by = .(adm1, sex, age_group)
    ] |>
      # Bar graphs
      ggplot(aes(x = adm1, y = N, fill = interaction(sex, age_group))) +
      geom_bar(stat = "identity", position = "dodge") +
      labs(title = "Cases Summary by adm1, sex, and age group",
           x = "adm1",
           y = "Number of Cases",
           fill = "Sex & Age Group") +
      sn_theme()
      
      
  ),
  
  tar_target(
    save_barplot_passive_by_adm1,
        ggsave(
          "results/3-plot/06-barplot_barplot_passive_by_adm1.png", 
          barplot_passive_by_adm1,
          width = 10, height = 6
        ),
    format = "file"
  ),
  tar_target(
    tbl_passive_cases,
    fixed_adm1_passive_cases |> 
      tbl_summary(
        include = c(adm1, sex, age),
        by = month, # split table by group
        missing = "no" # don't list missing data separately
      ) %>%
      add_n() %>% # add column with total number of non-missing observations
      add_p() %>% # test for a difference between groups
      modify_header(label = "**Variable**") %>% # update the column header
      bold_labels()
  ),
  
  tar_target(
    map_passive_cases,
    shp_catchment |>
      left_join(fixed_adm1_passive_cases[, .(n = .N), by = .(hf)]) |>
      # plot map with tmap
      tm_shape() +
      tm_polygons(
        fill = "n", 
        # fill.scale = tm_scale_intervals(values = "n"), 
        fill.legend = tm_legend(
          title = "Confirmed Cases - Passive Surverillance"
        )
     )
  ),
  tar_target(
    save_map_passive_cases,
    tmap_save(tm = map_passive_cases, 
              filename = "results/3-plot/07-map_passive_cases.png", 
              width = 10, height = 6)
  ),

  ##### 4. active cases ---------------------------------------------------------
  # for each adm1, make a bar plot active cases and passive cases
  tar_target(
    barplot_active_passive_comparison,
    fixed_adm1_passive_cases[
      , .(conf_passive = .N), by = .(adm1)
    ][
      fixed_adm1_active_cases[, .(conf_active = .N), by = .(adm1)], on = "adm1"] |>
      melt(id.vars = "adm1", variable.name = "case_type", value.name = "count") |>
      ggplot(aes(x = adm1, y=count, fill = case_type)) +
      geom_bar(stat = "identity", position = "dodge") +
      labs(y = "Number of Cases", fill = "Case Type") +
      sn_theme() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  ),
  tar_target(
    save_barplot_active_passive_comparison,
    ggsave(
      "results/3-plot/07-_barplot_active_passive_comparison.png", 
      barplot_active_passive_comparison,
      width = 10, height = 6
    ),
    format = "file"
  ),
  
  # bar plot
  tar_target(
    barplot_active_by_adm1,
    fixed_adm1_active_cases[
      , age_group := ifelse(age <= 5, "Under 5", "Over 5")][
        # summarise cases by sex and age group(over 5 and under 5) for each adm1
        , .N, by = .(adm1, sex, age_group)
      ] |>
      # Bar graphs
      ggplot(aes(x = adm1, y = N, fill = interaction(sex, age_group))) +
      geom_bar(stat = "identity", position = "dodge") +
      labs(title = "Cases Summary by adm1, sex, and age group",
           x = "adm1",
           y = "Number of Cases",
           fill = "Sex & Age Group") +
      sn_theme()
  ),
  tar_target(
    save_barplot_active_by_adm1,
    ggsave(
      "results/3-plot/07-barplot_active_by_adm1.png", 
      barplot_active_by_adm1,
      width = 10, height = 6
    ),
    format = "file"
  ),
  
  ##### 4.1 merge with passive ------------
  tar_target(
    only_exist_in_active,
    unique(fixed_adm1_passive_cases)[
      , passive := 1
    ][
      fixed_adm1_active_cases,
      on = c("adm1", "adm2", "hf", "age", "sex", "month")
    ][
      is.na(passive)
    ]
  ),
  tar_target(
    map_active_cases,
    shp_catchment |>
      left_join(only_exist_in_active[, .(n = .N), by = .(hf)]) |>
      # plot map with tmap
      tm_shape() +
      tm_polygons(
        fill = "n", 
        # fill.scale = tm_scale_intervals(values = "n"), 
        fill.legend = tm_legend(
          title = "Extra confirmed cases identified by active surveillance system"
        )
      )
  ),
  tar_target(
    save_map_active_cases,
    tmap_save(tm = map_active_cases, 
              filename = "results/3-plot/08-map_active_cases.png", 
              width = 10, height = 6)
  ),
  ##### elimination status ---------
  tar_target(
    link_adm2_elimination_status,
    link_adm2(
      fixed_adm1_shp_adm2_nmcp,
      fixed_adm1_elimination
    )
  ),
  tar_target(
    map_elimination_status,
    link_adm2_elimination_status |>
      # plot map with tmap
      tm_shape() +
      tm_polygons(
        fill = "elimination", 
        # fill.scale = tm_scale_intervals(values = "n"), 
        fill.legend = tm_legend(
          title = "Elimination Status"
        )
      )
  ),
  tar_target(
    save_map_elimination_status,
    tmap_save(tm = map_elimination_status, 
              filename = "results/3-plot/08-map_elimination_status.png", 
              width = 10, height = 6)
  ),
  

  ##### irs -------------------------------------------------------------------------------------------------------------
  
  # coverage
  tar_target(
    map_irs_coverage_by_localities_year,
    fixed_adm1_shp_adm2_nmcp |> 
      cross_join(tibble(year = 2019:2022)) |>
      left_join(fixed_adm1_irs, by = c("adm1", "adm2", "year")) |>
      tm_shape() +
      tm_polygons(
        fill = "cover", 
        # fill.scale = tm_scale_intervals(values = "n"), 
        fill.legend = tm_legend(
          title = "IRS Coverage"
        )
      ) +
      tm_facets_wrap("year", nrow = 1)
  ),
  tar_target(
    save_map_irs_coverage_by_localities_year,
    tmap_save(tm = map_irs_coverage_by_localities_year, 
              filename = "results/3-plot/10-map_irs_coverage_by_localities_year.png", 
              width = 16, height = 6)
  ),
  
  # planned
  tar_target(
    map_irs_planned_by_localities_year,
    fixed_adm1_shp_adm2_nmcp |> 
      cross_join(tibble(year = 2019:2022)) |>
      left_join(fixed_adm1_irs, by = c("adm1", "adm2", "year")) |>
      tm_shape() +
      tm_polygons(
        fill = "irs_planned", 
        # fill.scale = tm_scale_intervals(values = "n"), 
        fill.legend = tm_legend(
          title = "IRS planned"
        )
      ) +
      tm_facets_wrap("year", nrow = 1)
  ),
  tar_target(
    save_map_irs_planned_by_localities_year,
    tmap_save(tm = map_irs_planned_by_localities_year, 
              filename = "results/3-plot/10-map_irs_planned_by_localities_year.png", 
              width = 16, height = 6)
  ),
  
  ##### ITN mass -------------------------------------------------------------------------------------------------------
  tar_target(
    map_itn_mass,
    shp_adm1_nmcp |>
      left_join(fixed_adm1_itn_campaign, by = c("adm1")) |>
      tm_shape() +
      tm_polygons(
        fill = "itn", 
        # fill.scale = tm_scale_intervals(values = "n"), 
        fill.legend = tm_legend(
          title = "ITN distributed"
        )
      ) 
  ),
  tar_target(
    save_map_itn_mass,
    tmap_save(tm = map_itn_mass,
              filename = "results/3-plot/11-map_itn_mass.png", 
              width = 16, height = 6)
  ),
  tar_target(
    map_itn_coverage,
    shp_adm1_nmcp |>
      left_join(fixed_adm1_itn_campaign, by = c("adm1"))  |>
      left_join(fixed_adm1_estimated_population[,
                                                .(pop = sum(.SD)),
                                                by = .(adm1, year),
                                                .SDcols = c(4:18)][year == 2022],
                by = c("adm1")) |>
      mutate(coverage = itn / pop) |>
      tm_shape() +
      tm_polygons(fill = "coverage",
                  # fill.scale = tm_scale_intervals(values = "n"),
                  fill.legend = tm_legend(title = "ITN coverage")) 
  ),
  tar_target(
    save_map_itn_coverage,
    tmap_save(tm = map_itn_coverage,
              filename = "results/3-plot/11-map_itn_coverage.png", 
              width = 16, height = 6)
  ),

  ##### lsm -------------------------------------------------------------------------------------------------------------
  tar_target(
    bubble_lsm,
    fixed_adm1_lsm |>
      mutate(positive_rate = positive / sampled) |>
      mutate(average_anopheles = as.numeric(average_anopheles)) |>
      mutate(area = as.numeric(area)) |>
      mutate(anopheles = positive * average_anopheles) |>
      filter(sampled != 0) |>
      ggplot(aes(
        x = anopheles,
        y = positive_rate,
        size = area,
        fill = adm1
      )) +
      geom_point(alpha = 0.5,
                 shape = 21,
                 color = "black") +
      snt::sn_theme() +
      scale_x_continuous(trans = 'log2') +
      scale_size(range = c(0.5, 20)) +
      viridis::scale_fill_viridis(discrete = TRUE,
                                  guide = "legend",
                                  option = "D") +
      theme(legend.position = "bottom") +
      xlab("Anopheles Captured") +
      ylab("Laval positive rate in sampled waterbodies")
    # + theme(legend.position = "none")
    
  ),
  tar_target(
    save_bubble_lsm,
    ggsave(
      filename = "results/3-plot/12-bubble_lsm.png",
      plot = bubble_lsm,
      width = 16,
      height = 7
      )
  ),
  
  # comparing anopheles captured
  tar_target(
    dense_lsm_anopheles,
    fixed_adm1_lsm |>
      filter(sampled != 0) |>
      ggpubr::ggdensity(x = "anopheles",
                add = "mean", rug = TRUE,
                color = "adm1", fill = "adm1") +
      scale_x_continuous(trans = 'log10')
  ),
  
  # target area selected
  tar_target(
    dense_lsm_area,
    fixed_adm1_lsm |>
      ggpubr::gghistogram(x = "area",
                        add = "mean", rug = TRUE,
                        color = "adm1", fill = "adm1")
  ),
  tar_target(
    save_dense_lsm_area,
    ggsave(
      filename = "results/3-plot/12-dense_lsm_area.png",
      plot = dense_lsm_area,
      width = 10,
      height = 7
    )
  ),
  
  # scanned area
  tar_target(
    dense_lsm_scanned_area,
    fixed_adm1_lsm |>
      ggpubr::gghistogram(x = "scanned_area",
                          add = "mean", rug = TRUE,
                          color = "adm1", fill = "adm1")
  ),
  tar_target(
    save_dense_lsm_scanned_area,
    ggsave(
      filename = "results/3-plot/12-dense_lsm_scanned_area.png",
      plot = dense_lsm_scanned_area,
      width = 10,
      height = 7
    )
  ),
  
  tar_target(
    dense_lsm_scanned,
    fixed_adm1_lsm |>
      filter(scanned != 0) |>
      ggpubr::gghistogram(x = "scanned",
                          add = "mean", rug = TRUE,
                          color = "adm1", fill = "adm1",
                          bins = 20
                          ) +
      xlab("Area scanned %")
  ),
  tar_target(
    save_dense_lsm_scanned,
    ggsave(
      filename = "results/3-plot/12-dense_lsm_scanned.png",
      plot = dense_lsm_scanned,
      width = 10,
      height = 7
    )
  ),
  
  # barplot for lsm, aggregated sprayed / issued / unsprayed by each adm1, then plot an stacked barplot
  tar_target(
    barplot_lsm_sprayed,
    fixed_adm1_lsm[
      ,
      .(sprayed = sum(sprayed),
        issued = sum(issued),
        unsprayed = sum(unsprayed)),
      by = .(adm1)
    ] |>
      melt(id.vars = "adm1") |>
      ggplot(aes(x = adm1, y = value, fill = variable)) +
      geom_bar(stat = "identity") +
      snt::sn_theme() +
      theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
      xlab("District") +
      ylab("Number of waterbodies")
  ),
  tar_target(
    save_barplot_lsm_sprayed,
    ggsave(
      filename = "results/3-plot/12-barplot_lsm_sprayed.png",
      plot = barplot_lsm_sprayed,
      width = 4,
      height = 7
    )
  ),
  
  # barplot for lsm, aggregated sprayed / issued / unsprayed by each adm1, then plot an stacked barplot
  tar_target(
    barplot_lsm_sampled,
    fixed_adm1_lsm[
      ,
      .(sampled = sum(sampled),
        positive = sum(positive)),
      by = .(adm1)
    ] |>
      melt(id.vars = "adm1") |>
      ggplot(aes(x = adm1, y = value, fill = variable)) +
      geom_bar(stat = "identity") +
      snt::sn_theme() +
      theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
      xlab("District") +
      ylab("Number of waterbodies sampled and positive")
  ),
  tar_target(
    save_barplot_lsm_sampled,
    ggsave(
      filename = "results/3-plot/12-barplot_lsm_sampled.png",
      plot = barplot_lsm_sampled,
      width = 4,
      height = 7
    )
  ),
  
  # map of spayed waterbodies by adm2
  tar_target(
    map_lsm_sprayed,
    fixed_adm1_shp_adm2_nmcp |> 
      left_join(fixed_adm1_lsm) |>
      tm_shape() +
      tm_polygons(
        fill = "sprayed", 
        # fill.scale = tm_scale_intervals(values = "n"), 
        fill.legend = tm_legend(
          title = "Sprayed waterbodies"
        )
      )
  ),
  tar_target(
    save_map_lsm_sprayed,
    tmap_save(tm = map_lsm_sprayed, 
              filename = "results/3-plot/12-map_lsm_sprayed.png", 
              width = 10, height = 30)
  ),
  
  # vector
  # plot larvea, stacked barplot for lav_1, lav_2, lav_3, lav_4 and pupa, facet by adm1 and adm2
  tar_target(
    plot_bar_larvea,
    fixed_adm1_vector[, .(date = make_date(year, month), adm1, adm2, lav_1, lav_2, lav_3, lav_4, pupa)] |>
      melt(id.vars = c("adm1", "adm2", "date")) |>
      ggplot(aes(x = date, y = value, fill = variable)) +
      geom_bar(stat = "identity") +
      facet_wrap(adm1 ~ adm2) + # Use vars() to specify the variables
      snt::sn_theme() +
      theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
      xlab("District") +
      ylab("Number of larvea and pupa")
  ),
  tar_target(
    save_plot_bar_larvea,
    ggsave(plot = plot_bar_larvea, 
              filename = "results/3-plot/12-plot_bar_larvea.png", 
              width = 20, height = 10)
  ),
  
  # plot larvea, stacked barplot for lav_1, lav_2, lav_3, lav_4 and pupa, facet by adm1 and adm2
  tar_target(
    plot_bar_larvea_adm1,
    fixed_adm1_vector[
      , .(date = make_date(year, month), adm1, adm2, lav_1, lav_2, lav_3, lav_4, pupa)
      ][
        , .(
          lav_1 = sum(lav_1),
          lav_2 = sum(lav_2),
          lav_3 = sum(lav_3),
          lav_4 = sum(lav_4),
          pupa = sum(pupa)
        ),
        by = .(date, adm1)
      ] |>
      melt(id.vars = c("adm1", "date")) |>
      ggplot(aes(x = date, y = value, fill = variable)) +
      geom_bar(stat = "identity") +
      snt::sn_theme() +
      scale_x_date(
        date_labels = "%Y-%m",
        guide = guide_axis(check.overlap = TRUE),
        date_breaks = "6 month"
      ) +
      xlab("District") +
      ylab("Number of larvea and pupa")
  ),
  tar_target(
    save_plot_bar_larvea_adm1,
    ggsave(plot = plot_bar_larvea_adm1, 
           filename = "results/3-plot/12-plot_bar_larvea_adm1.png", 
           width = 20, height = 10)
  ),
  
  # vector
  # plot larvea, stacked barplot for lav_1, lav_2, lav_3, lav_4 and pupa, facet by adm1 and adm2
  tar_target(
    plot_bar_adult,
    fixed_adm1_vector[, .(date = make_date(year, month), adm1, adm2, mos_adult_inside, mos_adult_outside)] |>
      melt(id.vars = c("adm1", "adm2", "date")) |>
      ggplot(aes(x = date, y = value, fill = variable)) +
      geom_bar(stat = "identity") +
      facet_wrap(adm1 ~ adm2) + # Use vars() to specify the variables
      snt::sn_theme() +
      theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
      xlab("District") +
      ylab("Number of Adult Mosquitoes Captured")
  ),
  tar_target(
    save_plot_bar_adult,
    ggsave(plot = plot_bar_adult, 
              filename = "results/3-plot/12-plot_bar_adult.png", 
              width = 20, height = 10)
  ),
  
  # vector
  # plot larvea, stacked barplot for lav_1, lav_2, lav_3, lav_4 and pupa, facet by adm1 and adm2
  tar_target(
    plot_bar_adult_adm1,
    fixed_adm1_vector[, .(date = make_date(year, month), adm1, adm2, mos_adult_inside, mos_adult_outside)][
      ,
      .(mos_adult_inside = sum(mos_adult_inside),
        mos_adult_outside = sum(mos_adult_outside)
      ),
      by = .(date, adm1)
    ] |>
      melt(id.vars = c("adm1", "date")) |>
      ggplot(aes(x = date, y = value, fill = variable)) +
      geom_bar(stat = "identity") +
      snt::sn_theme() +
      scale_x_date(
        date_labels = "%Y-%m",
        guide = guide_axis(check.overlap = TRUE),
        date_breaks = "6 month"
      ) +
      xlab("District") +
      ylab("Number of Adult Mosquitoes Captured")
  ),
  tar_target(
    save_plot_bar_adult_adm1,
    ggsave(plot = plot_bar_adult_adm1, 
           filename = "results/3-plot/12-plot_bar_adult_adm1.png", 
           width = 20, height = 10)
  )
)

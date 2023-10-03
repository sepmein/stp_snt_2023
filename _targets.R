# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline

# Load packages required to define the pipeline:
library(targets)
library(tarchetypes)

# Set target options:
tar_option_set(
  packages = c("qs",
    "readxl",
    "data.table",
    "Hmisc"
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
  ##### 1. files #####
  tar_qs(
    f_routine,
    "data/04-routine/FICHEIRO OMS BEATRIZ -250923_as_17_08.xlsx"
  ),

  ##### 2. load data #####
  # 2.1. load the health facilities list
  tar_target(
    hf,
    load_hf(f_routine)
  ),
  # 2.2. load the estimated population
  tar_target(
    estimated_population,
    load_estimated_population(f_routine)
  ),
  # 2.3. load the estimated population adm3 level
  tar_target(
    estimated_population_adm3,
    load_estimated_population_adm3(f_routine)
  ),
  # 2.4. load the routine database
  tar_target(
    routine,
    load_routine(f_routine)
  ),
  # 2.5. load elimination
  tar_target(
    elimination,
    load_elimination(f_routine)
  ),
  # 2.6. load passive cases
  tar_target(
    passive_cases,
    load_case_2022(f_routine)
  ),
  # 2.7. load active cases
  tar_target(
    active_cases,
    load_active_cases_2022(f_routine)
  ),
  # 2.8. load routine intervention
  tar_target(
    routine_intervention,
    load_routine_intervention(f_routine)
  ),
  # 2.9. load IRS
  tar_target(
    irs,
    load_irs(f_routine)
  ),
  # 2.10. load ITN campaign
  tar_target(
    itn_campaign,
    load_itn_campaign(f_routine)
  ),

  ##### 3. unique values #####
  # 3.1. adm1 from hf
  tar_target(
    adm1_from_hf,
    hf[, .(adm1 = unique(adm1))]
  ),
  # 3.2. adm2 from hf
  tar_target(
    adm2_from_hf,
    hf[, .(adm2 = unique(adm2))]
  ),
  # 3.3. hf from hf
  tar_target(
    hf_from_hf,
    hf[, .(hf = unique(hf))]
  ),
  # 3.4. adm1 from estimated_population
  tar_target(
    adm1_from_estimated_population,
    estimated_population[, .(adm1 = unique(adm1))]
  ),
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
  tar_target(
    adm1_from_routine,
    routine[, .(adm1 = unique(adm1))]
  ),
  # 3.8. hf from routine
  tar_target(
    hf_from_routine,
    routine[, .(hf = unique(hf))]
  ),
  # 3.9. adm1 from elimination
  tar_target(
    adm1_from_elimination,
    elimination[, .(adm1 = unique(adm1))]
  ),
  # 3.10. adm2 from elimination
  tar_target(
    adm2_from_elimination,
    elimination[, .(adm2 = unique(adm2))]
  ),
  # 3.11. adm1 from passive case level data 2022
  tar_target(
    adm1_from_passive_cases,
    passive_cases[, .(adm1 = unique(adm1))]
  ),
  # 3.12. adm2 from passive case level data 2022
  tar_target(
    adm2_from_passive_cases,
    passive_cases[, .(adm2 = unique(adm2))]
  ),
  # 3.13. adm1 from active case level data 2022
  tar_target(
    adm1_from_active_cases,
    active_cases[, .(adm1 = unique(adm1))]
  ),
  # 3.14. adm2 from active case level data 2022
  tar_target(
    adm2_from_active_cases,
    active_cases[, .(adm2 = unique(adm2))]
  ),
  # 3.15. adm1 from routine intervention
  tar_target(
    adm1_from_routine_intervention,
    routine_intervention[, .(adm1 = unique(adm1))]
  ),
  # 3.16. hf from routine intervention
  tar_target(
    hf_from_routine_intervention,
    routine_intervention[, .(hf = unique(hf))]
  ),
  # 3.17. adm1 from irs
  tar_target(
    adm1_from_irs,
    irs[, .(adm1 = unique(adm1))]
  ),
  # 3.18. adm2 from irs
  tar_target(
    adm2_from_irs,
    irs[, .(adm2 = unique(adm2))]
  ),
  # 3.19. adm1 from itn campaign
  tar_target(
    adm1_from_itn_campaign,
    itn_campaign[, .(adm1 = unique(adm1))]
  ),

  ##### 4. comparison #####
  # 4.1. adm1 from hf and estimated_population, check if they are identical to each other
  tar_target(
    adm1_from_hf_estimated_population,
    setdiff(
      adm1_from_hf$adm1,
      adm1_from_estimated_population$adm1
    )
  ),
  # 4.2 adm1 from adm1_from_hf_estimated_population and adm1_from_estimated_population_adm2, check if they are identical to each other
  tar_target(
    adm1_from_hf_estimated_population_adm3,
    setdiff(
      adm1_from_hf$adm1,
      adm1_from_estimated_population_adm3$adm1
    )
  ),
  # 4.3. adm1 from hf and routine, check if they are identical to each other
  tar_target(
    adm1_from_hf_routine,
    setdiff(
      adm1_from_hf$adm1,
      adm1_from_routine$adm1
    )
  ),
  # 4.4. hf from hf and routine, check if they are identical to each other
  tar_target(
    hf_from_hf_routine,
    setdiff(
      hf_from_hf$hf,
      hf_from_routine$hf
    )
  ),
  # 4.5. adm1 from hf and elimination, check if they are identical to each other
  tar_target(
    adm1_from_hf_elimination,
    setdiff(
      adm1_from_hf$adm1,
      adm1_from_elimination$adm1
    )
  ),
  # 4.6. adm2 from hf and elimination, check if they are identical to each other
  tar_target(
    adm2_from_hf_elimination,
    setdiff(
      adm2_from_hf$adm2,
      adm2_from_elimination$adm2
    )
  ),
  # 4.7. adm1 from hf and passive_cases, check if they are identical to each other
  tar_target(
    adm1_from_hf_passive_cases,
    setdiff(
      adm1_from_hf$adm1,
      adm1_from_passive_cases$adm1
    )
  ),
  # 4.8. adm2 from hf and passive_cases, check if they are identical to each other
  tar_target(
    adm2_from_hf_passive_cases,
    setdiff(
      adm2_from_hf$adm2,
      adm2_from_passive_cases$adm2
    )
  ),
  # 4.9. adm1 from hf and active_cases, check if they are identical to each other
  tar_target(
    adm1_from_hf_active_cases,
    setdiff(
      adm1_from_hf$adm1,
      adm1_from_active_cases$adm1
    )
  ),
  # 4.10. adm2 from hf and active_cases, check if they are identical to each other
  tar_target(
    adm2_from_hf_active_cases,
    setdiff(
      adm2_from_hf$adm2,
      adm2_from_active_cases$adm2
    )
  ),
  # 4.11. adm1 from hf and routine_intervention, check if they are identical to each other
  tar_target(
    adm1_from_hf_routine_intervention,
    setdiff(
      adm1_from_hf$adm1,
      adm1_from_routine_intervention$adm1
    )
  ),
  # 4.12. hf from hf and routine_intervention, check if they are identical to each other
  tar_target(
    hf_from_hf_routine_intervention,
    setdiff(
      hf_from_hf$hf,
      hf_from_routine_intervention$hf
    )
  ),
  # 4.13. adm1 from hf and irs, check if they are identical to each other
  tar_target(
    adm1_from_hf_irs,
    setdiff(
      adm1_from_hf$adm1,
      adm1_from_irs$adm1
    )
  ),
  # 4.14. adm2 from hf and irs, check if they are identical to each other
  tar_target(
    adm2_from_hf_irs,
    setdiff(
      adm2_from_hf$adm2,
      adm2_from_irs$adm2
    )
  ),
  # 4.15. adm1 from hf and itn_campaign, check if they are identical to each other
  tar_target(
    adm1_from_hf_itn_campaign,
    setdiff(
      adm1_from_hf$adm1,
      adm1_from_itn_campaign$adm1
    )
  )


)

#### 1. database ####

#' Load Health Facility List from routine database
#'
#' This function will read the excel from routine database and return a data frame, transform it into a data.table, then use the function called upData from Hmisc package to do the renaming of table.
#' the data.table will be saved as .qs file
#' @param d the path to the excel file
#' @return data.table contain the health facility list
load_hf <- function(d) {
    dt <- read_excel(d, sheet = "US") |>
        as.data.table() |>
        upData(
            rename = .q(
                `Nome do distrito` = adm1,
                `Nome da localidade` = adm2,
                `Nome da US` = hf,
                `Tipo (Hospital, CS#)` = type,
                `Publico/privada` = owner,
                `Lati GPS` = lat,
                `Longi GPS` = long,
                Observação = comment
            ),
            # labels = .q(
            #     adm1 = "District",
            #     adm2 = "Locality",
            #     hf = "Health Facility",
            #     type = "Type of the health facility, hospital or health center",
            #     owner = "Public or private",
            #     lat = "Latitude",
            #     long = "Longitude",
            #     comment = "Observation"
            # ),
            adm1 = to.plain(adm1), 
            adm2 = to.plain(adm2),
            adm1 = as.factor(adm1),
            adm2 = as.factor(adm2),
            hf = as.factor(hf),
            type = as.factor(type),
            owner = as.factor(owner),
            lat = as.numeric(lat),
            long = as.numeric(long)
        )
    # commment indicate the health facility is not functional
    # Não funcional desde 2022,
    # so we will remove them
    dt[is.na(comment)]
}

load_adm2_hf <- function(f) {
  
    d <- read_excel(f) |>
        as.data.table() |>
        upData(
            rename = .q(
                `Distrito` = adm1,
                `Localidades` = adm2,
                `Posto sanitário` = hf
            ),
            adm1 = to.plain(adm1),
            adm2 = to.plain(adm2),
            hf = str_remove(hf, "PS "),
            hf = str_remove(hf, "CS de "),
            hf = str_remove(hf, "CS ")
        )
#     d[,
#       hf := case_when(
# 
#       )
#       ]
}

#' 2. Load the estimated population data from routine database
#'
#' This function will read the excel from routine database and return a data frame.
#' The data is in long format, disaggregated by sex and year group. Year range is from 2018 - 2023.
#' @param d the path to the excel file
#' @return data.table contain the estimated population
load_estimated_population <- function(d) {
    dt <- read_excel(d, sheet = "Pop-Proj2018-2023", skip = 1) |>
        as.data.table() |>
        upData(
            rename = .q(
                `Nome do distrito` = adm1,
                Ano = year,
                `População todas as idades` = sex
            ),
            # labels = .q(
            #     adm1 = "District",
            #     year = "the year of estimated population",
            #     sex = "Male or Female"
            # ),
            drop = .q(`Nome da localidade...2`, `Nome da localidade...3`),
            adm1 = to.plain(adm1), 
            adm1 = as.factor(adm1),
            sex = as.factor(sex),
            sex = fifelse(sex == "Homens", "m", "f")
        )
    dt[, `Nome da localidade...3`:= NULL]
    
}

# ‘ 3. Load the estimated population data from routine database, adm2 level
#'
#' This function will read the estimated population data
#'
load_estimated_population_adm2 <- function(d) {
    dt <- read_excel(d, sheet = "Pop-por localidade 2012-2023") |>
        as.data.table() |>
        upData(
            rename = .q(
                `Nome do distrito` = adm1,
                `Nome da localidade` = adm2,
                `Pop total 2012` = pop_total_2012,
                `Pop Masculino 2012` = pop_m_2012,
                `Pop Feminino 2012` = pop_f_2012,
                `Pop total 2013` = pop_total_2013,
                `Pop Masculino 2013` = pop_m_2013,
                `Pop Feminino 2013` = pop_f_2013,
                `Pop total 2014` = pop_total_2014,
                `Pop Masculino 2014` = pop_m_2014,
                `Pop Feminino 2014` = pop_f_2014,
                `Pop total 2015` = pop_total_2015,
                `Pop Masculino 2015` = pop_m_2015,
                `Pop Feminino 2015` = pop_f_2015,
                `Pop total 2016` = pop_total_2016,
                `Pop Masculino 2016` = pop_m_2016,
                `Pop Feminino 2016` = pop_f_2016,
                `Pop total 2017` = pop_total_2017,
                `Pop Masculino 2017` = pop_m_2017,
                `Pop Feminino 2017` = pop_f_2017,
                `Pop total 2018` = pop_total_2018,
                `Pop Masculino 2018` = pop_m_2018,
                `Pop Feminino 2018` = pop_f_2018,
                `Pop total 2019` = pop_total_2019,
                `Pop Masculino 2019` = pop_m_2019,
                `Pop Feminino 2019` = pop_f_2019,
                `Pop total 2020` = pop_total_2020,
                `Pop Masculino 2020` = pop_m_2020,
                `Pop Feminino 2020` = pop_f_2020,
                `Pop total 2021` = pop_total_2021,
                `Pop Masculino 2021` = pop_m_2021,
                `Pop Feminino 2021` = pop_f_2021,
                `Pop total 2022` = pop_total_2022,
                `Pop Masculino 2022` = pop_m_2022,
                `Pop Feminino 2022` = pop_f_2022,
                `Pop total 2023` = pop_total_2023,
                `Pop Masculino 2023` = pop_m_2023,
                `Pop Feminino 2023` = pop_f_2023
            ),
            adm1 = to.plain(adm1),
            adm2 = to.plain(adm2),
            adm1 = as.factor(adm1),
            adm2 = as.factor(adm2)
        )
}

# ‘ Load routine data
load_routine <- function(d) {
    dt <-
        read_excel(d, sheet = "Dados rotina agregados (3)", range = "A1:AR2341") |>
        as.data.table() |>
        upData(
            rename = .q(
                `Nome do distrito` = adm1,
                `Nome da US` = hf,
                Mes = month,
                Ano = year,
                `Total pacientes consultas por todas as causas` = alladm,
                `Total pacientes <5` = alladm_u5,
                `Total pacientes >=5` = alladm_ov5,
                `Gravidas` = alladm_p,
                `Total casos suspeitos` = susp,
                `Total suspeitos <5` = susp_u5,
                `Total suspeitos >=5` = susp_ov5,
                `Gravidas suspeitas` = susp_p,
                `Total testados` = test,
                `Total testados <5` = test_u5,
                `Total testados >=5` = test_ov5,
                `Gravidas testadas` = test_p,
                `Total casos positivos` = conf,
                `Total positivos <5` = conf_u5,
                `Total positivos >=5` = conf_ov5,
                `Gravidas testadas positivas` = conf_p,
                `Total casos negativos` = negative,
                `Total negativos <5` = negative_u5,
                `Total negativos >=5` = negative_ov5,
                `Gravidas testadas negativo` = negative_p,
                `Total casos tratados` = treat,
                `Total casos tratados <5` = treat_u5,
                `Total casos tratados >=5` = treat_ov5,
                `Gravidas tratadas` = treat_p,
                `Total pacientes internados` = maladm,
                `Total internados <5` = maladm_u5,
                `Total internado>=5` = maladm_ov5,
                `Gravidas internada` = maladm_p,
                `Total pacientes com malaria grave admitidas` = severe,
                `Total malária grave <5` = severe_u5,
                `Total malária grave >=5` = severe_ov5,
                `Gravidas com malária grave` = severe_p,
                `Total mortes` = alldth,
                `Total morte <5` = alldth_u5,
                `Total morte >=5` = alldth_ov5,
                `Morte Gravidas` = alldth_p,
                `Total mortes malaria` = maldth,
                `Total morte por malária <5` = maldth_u5,
                `Total morte por malária >=5` = maldth_ov5,
                `Morte  por malária Gravidas` = maldth_p
            ),
            adm1 = to.plain(adm1),
            adm1 = as.factor(adm1),
            hf = as.factor(hf)
        )
}

#' load elimination status
#'
load_elimination <- function(d) {
    dt <- read_excel(d, sheet = "Casos por localidade 2018-2022") |>
        as.data.table() |>
        upData(
            rename = .q(
                `Nº de Ordem` = n,
                `Nº de Foco` = n_foco,
                Distrito = adm1,
                Localidade = adm2,
                `2018` = conf_2018,
                `2019` = conf_2019,
                `2020` = conf_2020,
                `2021` = conf_2021,
                `2022` = conf_2022,
                Classificação = elimination
            ),
            n = as.factor(n),
            n_foco = as.factor(n_foco),
            adm1 = to.plain(adm1),
            adm2 = to.plain(adm2),
            adm1 = as.factor(adm1),
            adm2 = as.factor(adm2),
            conf_2018 = fifelse(conf_2018 == "Total casos negativos ", 0, conf_2018),
            conf_2018 = as.numeric(conf_2018)
        )
    
}

#' load case level data for 2022
load_case_2022 <- function(d) {
    dt <- read_excel(d, sheet = "Passiva Casos + 2022", range ="A1:F3182") |>
        as.data.table() |>
        upData(
            rename = .q(
                DATA = month,
                `UNIDADE SANITÁRIA` = hf,
                `DISTRITO DO DOENTE` = adm1,
                `LOCALIDADE DO DOENTE` = adm2,
                IDADE = age,
                SEXO = sex
            ),
            adm1 = to.plain(adm1),
            adm2 = to.plain(adm2),
            adm1 = as.factor(adm1),
            adm2 = as.factor(adm2),
            hf = as.factor(hf),
            age = as.numeric(age)
        )
}

# ‘ active case data for 2022
load_active_cases_2022 <- function(d) {
    dt <- read_excel(
      d, sheet = "Vig. reactiva 2022",
      range = "A1:F3927"
                     ) |>
        as.data.table() |>
        upData(
            rename = .q(
                DATA = month,
                `DISTRITO DO DOENTE` = adm1,
                LOCALIDADE = adm2,
                `UNIDADE SANITÁRIA` = hf,
                IDADE = age,
                SEXO = sex
            ),
            adm1 = to.plain(adm1),
            adm2 = to.plain(adm2),
            adm1 = as.factor(adm1),
            adm2 = as.factor(adm2),
            hf = as.factor(hf),
            age = as.numeric(age)
        )
}

#' load routine intervention
load_routine_intervention <- function(d) {
    dt <- read_excel(d, sheet = "Intervenções de rotina") |>
        as.data.table() |>
        upData(
            rename = .q(
                Distrito = adm1,
                `Nome do estabelecimento de saúde` = hf,
                Ano = year,
                Mês = month,
                `Número de mulheres que visitaram as CPN1` = anc1,
                `Número de mulheres que visitaram as CPN2` = anc2,
                `Número de mulheres que visitaram as CPN3` = anc3,
                `Número de mulheres que visitaram as CPN4` = anc4,
                `Número de mulheres cobertas com TPIg1` = ipt1,
                `Número de mulheres cobertas com TPIg2` = ipt2,
                `Número de mulheres cobertas com TPIg3` = ipt3,
                `Número de mulheres cobertas com TPIg4` = ipt4,
                `Número de MTILDs distribuídos durante as visitas prenatais` = itn_p,
                `Número de MILDAs distribuídos através do sistema de vacinação` = itn_v,
                `Número de rupturas de stock registadas por mês` = stock
            ),
            drop = .q(`Total Gravida que fizeram a CPN1`),
            adm1 = to.plain(adm1),
            hf = as.factor(hf),
            year = as.numeric(year),
            anc1 = as.numeric(anc1),
            anc2 = as.numeric(anc2),
            anc3 = as.numeric(anc3),
            anc4 = as.numeric(anc4),
            ipt1 = as.numeric(ipt1),
            ipt2 = as.numeric(ipt2),
            ipt3 = as.numeric(ipt3),
            ipt4 = as.numeric(ipt4),
            itn_p = as.numeric(itn_p),
            itn_v = as.numeric(itn_v),
            stock = as.numeric(stock)
        )
}

#' load irs
load_irs <- function(d) {
    dt <- read_excel(d, sheet = "PID distrito e locali 2019-2022") |>
        as.data.table() |>
        upData(
            rename = .q(
                Distrito = adm1,
                Localidades = adm2,
                Ano = year,
                `Cilco 1(mês)` = cycle_1,
                `Ciclo2 (mês)` = cycle_2,
                Tratadas = treated,
                Fechadas = closed,
                Recusadas = refused,
                `Não Tratada por Outras Rasões` = not_treated,
                Total = irs_planned,
                Cobertura = cover,
                Desabitadas = uninhabited,
                `Outras constr.` = other,
                `Total Geral` = total,
                `População protegida` = pop,
                `Insecticida (frasco)` = insecticide
            ),
            adm1 = to.plain(adm1),
            adm2 = to.plain(adm2),
            adm1 = as.factor(adm1),
            adm2 = as.factor(adm2),
            year = as.numeric(year),
            cycle_1 = as.numeric(cycle_1),
            cycle_2 = as.numeric(cycle_2),
            treated = as.numeric(treated),
            closed = as.numeric(closed),
            refused = as.numeric(refused),
            not_treated = as.numeric(not_treated),
            irs_planned = as.numeric(irs_planned),
            cover = as.numeric(cover),
            uninhabited = as.numeric(uninhabited)
        )
}

#' load itn campaign
load_itn_campaign <- function(d) {
    dt <- read_excel(d, sheet = "MTILD (Massa)", skip = 1) |>
        as.data.table() |>
        upData(rename = .q(Distrito = adm1, Total = itn),
               keep = .q(adm1, itn),
               adm1 = to.plain(adm1)
               )
    
    dt[adm1 != "Total"]
}

#' load itn routine
# load_itn_routine <- function(d) {
#     dt <- read_excel(d, sheet = "MTILD-rotina", skip = 1) |>
#         as.data.table() |>
#         upData(
#             rename = .q(
#                 Distrito = adm1,
#                 Ano = year,
#                 `< 5 anos` = itn_u5,
#                 Grávidas = itn_p,
#                 Outros = itn_other,
#                 Total = itn
#             ),
#             adm1 = as.factor(adm1)
#         )
# }

#' load lsm
load_lsm <- function(d) {
    dt <- read_excel(d, sheet = "Estudo piloto mapeamentLAV 2021") |>
        as.data.table() |>
        upData(
            rename = .q(
                Distrito = adm1,
                Localidade = adm2,
                `Area km 2` = area,
                scanned = scanned,
                `Water bodies` = water_bodies,
                sprayed = sprayed,
                issued = issued,
                unsprayed = unsprayed,
                `last spray` = last_spray,
                Sampled = sampled,
                `Number positive` = positive,
                `Average Anopheles` = average_anopheles
            ),
            adm1 = to.plain(adm1),
            adm2 = to.plain(adm2),
            positive_rate = positive / sampled,
            average_anopheles = as.numeric(average_anopheles),
            area = as.numeric(area),
            anopheles = average_anopheles * sampled,
            scanned = as.numeric(str_remove(scanned, "%")) / 100,
            scanned_area = area * scanned
        )
}

#' load vector
load_vector <- function(d) {
    dt <- read_excel(d, sheet = "Ab. vectores", skip = 1) |>
        as.data.table() |>
        upData(
            rename = .q(
                Distrito = adm1,
                `Local de sentinela` = adm2,
                Ano = year,
                Mês = month,
                Interior = mos_adult_inside,
                Exterior = mos_adult_outside,
                I = lav_1,
                II = lav_2,
                III = lav_3,
                IV = lav_4,
                Pupa = pupa
            ),
            adm1 = to.plain(adm1),
            adm2 = to.plain(adm2)
        )
}

#' load vector resistance
load_vector_resistance <- function(d) {
    dt <- read_excel(d, sheet = "Res. Insec", skip = 1) |>
        as.data.table() |>
        upData(
            rename = .q(
                Distrito = adm1,
                `Localidade` = adm2,
                `Ano` = year,
                `Mês` = month,
                Inseticida = insecticide,
                `Taxa de mortalidade` = mortality,
                `Status` = resistance
            ),
            adm1 = to.plain(adm1),
            adm2 = to.plain(adm2),
            adm1 = as.factor(adm1),
            adm2 = as.factor(adm2),
            # month = as.factor(month),
            insecticide = as.factor(insecticide),
            resistance = as.factor(resistance)
        )
}

#### 2. shapefile ####
#' extract adm1-adm2 combination from who gishub shapefile
#' The level of adm2 in WHO is actually adm1 in database, district level
extract_adm1 <- function(shp) {
    shp <- shp |>
        sf::st_drop_geometry() |>
        as.data.table()
    shp <- shp[, .(GUID, ADM2_NAME, ADM2_VIZ_N)]
    setnames(shp, c("id", "adm1_capital", "adm1"))
}

#' extract adm1-adm2 combination from nmcp shapefile
extract_adm1_adm2_nmcp <- function(shp) {
    shp |>
        sf::st_drop_geometry() |>
        distinct(adm1, adm2) |>
        mutate(adm1 = to.plain(adm1),
               adm2 = to.plain(adm2))
}

#' I found some of the the record are duplicates records
#' here is the function to identify the duplicates records
extract_duplicated_adm1_adm2_nmcp <- function(shp) {
    #' find the adjacent records
    shp |>
        mutate(adm1 == to.plain(adm1),
               adm2 == to.plain(adm2))
    
    dups_consider_adm1_adm2 <-  shp |>
        group_by(adm1, adm2) |>
        filter(n() > 1) 
    
    dups_consider_adm1_adm2 |>
        st_write("report/01-shapefile/duplicated_adm1_adm2.shp", delete_layer = TRUE)
    
    dups_consider_adm1_adm2 |>
        st_drop_geometry() |>
        fwrite("report/01-shapefile/duplicated_adm1_adm2.csv")

}
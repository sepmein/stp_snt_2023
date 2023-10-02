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
                `Observação` = comment
            ),
            labels = .q(
                adm1 = "District",
                adm2 = "Locality",
                hf = "Health Facility",
                type = "Type of the health facility, hospital or health center",
                owner = "Public or private",
                lat = "Latitude",
                long = "Longitude",
                comment = "Observation"
            ),
            adm1 = as.factor(adm1),
            adm2 = as.factor(adm2),
            hf = as.factor(hf),
            type = as.factor(type),
            owner = as.factor(owner),
            lat = as.numeric(lat),
            long = as.numeric(long)
        )
}

#' 2. Load the estimated population data from routine database
#' 
#' This function will read the excel from routine database and return a data frame.
#' The data is in long format, disaggregated by sex and year group. Year range is from 2018 - 2023.
#' @param d the path to the excel file
#' @return data.table contain the estimated population
load_estimated_population <- function(d) {
    dt <- read_excel(d,
        sheet = "Pop-Proj2018-2023",
        skip = 1) |>
        as.data.table() |>
        upData(
             rename = .q( 
                `Nome do distrito` = adm1,
                `Ano` = year,
                `População todas as idades` = sex
            ),
            labels = .q(
                adm1 = "District",
                year = "the year of estimated population",
                sex = "Male or Female"
            ),
            drop = .q(
                `Nome da localidade...2`,
                `Nome da localidade...3`
            ),
            adm1 = as.factor(adm1),
            sex = as.factor(sex),
            # if sex = Homens, then sex = m, if sex = Mulheres, then sex = f
            sex = fifelse(sex =="Homens", "m", "f")
        )
}

#‘ 3. Load the estimated population data from routine database, adm3 level
#' 
#' This function will read the estimated population data
#' 
load_estimated_population_adm3 <- function(d) {
    dt <- read_excel(d, sheet = "Pop-por localidade 2012-2023") |>
        as.data.table() |>
        upData(
            rename = .q(
                `Nome do distrito` = adm1,
                `Nome da localidade` = adm3,
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
            adm1 = as.factor(adm1),
            adm3 = as.factor(adm3)
        )
}
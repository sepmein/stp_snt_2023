#### 1. generate fuzzy match list ####
match_adm1 <- function(standard, target) {
    # standard and target are data.table
    # they both should have a column name
    # test if they have the same column name

    # select only the column needed
    standard <- standard[!is.na(adm1), .(adm1)]
    target <- target[!is.na(adm1), .(adm1)]
    # join two list by column
    joined <- fuzzyjoin::stringdist_left_join(
        target, standard,
        by = "adm1", method = "osa",
        max_dist = 10,
        distance_col = "distance"
    )
    setDT(joined)
    # for each group of adm1.x get the lowest distance
    joined <- joined[, .SD[which.min(distance)], by = adm1.x]
    joined <- joined[distance > 0]
}

match_adm2 <- function(standard, target) {
    # standard and target are data.table
    # they both have two columns called adm1 and adm2
    
    # select adm1 adn adm2, test if they were NA or not
    standard <- standard[!is.na(adm1) & !is.na(adm2), .(adm1, adm2)]
    target <- target[!is.na(adm1) & !is.na(adm2), .(adm1, adm2)]
    target[, adm1 := to.plain(adm1)]
    target[, adm2 := to.plain(adm2)]
    
    # join two list by column
    joined <- fuzzyjoin::stringdist_left_join(
        target, standard,
        by = c("adm1", "adm2"), method = "jw",
        max_dist = 50,
        distance_col = "distance"
    )
    
    setDT(joined)
    
    joined[, distance := adm1.distance + adm2.distance]
    joined <- joined[, .SD[which.min(distance)], by = .(adm1.x, adm2.x)]
    # joined <- joined[distance > 1e-1]
    # sorted by adm1.x adm2.x
    joined <- joined[order(distance)]
    joined[distance <= 1e-1, accepted := "Yes"]
    joined[distance > 1e-1, accepted := "No"]
}

# a function borrowed from the stackoveflow
to.plain <- function(s) {
    
    # 1 character substitutions
    old1 <- "Ášžþàáâãäåçèéêëìíîïðñòóôõöùúûüý"
    new1 <- "Aszyaaaaaaceeeeiiiidnooooouuuuy"
    s1 <- chartr(old1, new1, s)
    
    # 2 character substitutions
    old2 <- c("œ", "ß", "æ", "ø")
    new2 <- c("oe", "ss", "ae", "oe")
    s2 <- s1
    for(i in seq_along(old2)) s2 <- gsub(old2[i], new2[i], s2, fixed = TRUE)
    
    s2
}

match_hf <- function(standard, target) {
    
    standard <- standard[!is.na(hf), .(hf)]
    target <- target[!is.na(hf), .(hf)]
    # join two list by column
    joined <- fuzzyjoin::stringdist_left_join(
        target, standard,
        by = "hf", method = "osa",
        max_dist = 50, 
        distance_col = "distance"
    )
    setDT(joined)
    browser()
    # for each group of hf.x get the lowest distance
    joined <- joined[, .SD[which.min(distance)], by = hf.x]
    joined <- joined[distance > 0]
    
}

#' fix 
fix_adm1 <- function(db, fuzzy_matched) {
    # db is the data.table
    # fuzzy_matched is the data.table
    # db has a column called adm1
    # fuzzy_matched has two columns called adm1.x and adm1.y
    # join the two data.table by adm1 from db and adm1.x from fuzzy_matched, used adm1.y to replace adm1
    # return the new data.table
    # Join the two data.tables by adm1 from db and adm1.x from fuzzy_matched
    joined <- fuzzy_matched[db, on = .(adm1.x = adm1)]

    # Use adm1.y to replace adm1 if matched, otherwise keep adm1
    joined[!is.na(adm1.y), adm1 := adm1.y]
    joined[is.na(adm1.y), adm1 := adm1.x]
    
    # drop the adm1.x, adm1.y, distance columns
    joined[, c("adm1.x", "adm1.y", "distance") := NULL]

    # Return the new data.table
    return(joined)
}

#' fix 
fix_hf <- function(db, fuzzy_matched) {
    # db is the data.table
    # fuzzy_matched is the data.table
    # db has a column called hf
    # fuzzy_matched has two columns called hf.x and hf.y
    # join the two data.table by hf from db and hf.x from fuzzy_matched, used hf.y to replace hf
    # return the new data.table
    # Join the two data.tables by hf from db and hf.x from fuzzy_matched
    joined <- fuzzy_matched[db, on = .(hf.x = hf)]
    # Use hf.y to replace hf if matched, otherwise keep hf
    joined[!is.na(hf.y), hf := hf.y]
    joined[is.na(hf.y), hf := hf.x]
    
    # drop the hf.x, hf.y, distance columns
    joined[, c("hf.x", "hf.y", "distance") := NULL]
    
    # Return the new data.table
    return(joined)
}

sn_plot_outliers_improved <- function(d, ..., width = 6, height = 4, alpha = 0.4, save_to = NULL) {
  args <- list(...) |>
    unlist()
  melted <- melt(
    d, id.vars = "year", measure.vars = args, variable.name = "index",
    value.name = "value"
  )
  melted <- melted[!is.na(value)]
  melted[, index := factor(index)]
  melted[, year := factor(year)]
  melted[, value := as.numeric(value)]
  plot <- melted |>
    ggplot(aes(x = .data$value, y = .data$index)) +
    # geom_boxplot() +
    geom_point(
      aes(color = .data$year),
      alpha = alpha
    ) +
    sn_theme()
  if (!is.null(save_to)) {
    ggsave(save_to, plot, width = width, height = height, dpi = 300)
  }
  return(plot)
}

sn_plot_reprat_by_hf <- function(d, save_to) {
  d[, `:=`(date, make_date(year, month, 1))]
  plot <- ggplot(d) +
    geom_tile(aes(
      x = .data$date,
      y = .data$hf,
      fill = .data$rep_rat
    )) + scale_x_date(
      date_labels = "%Y",
      guide = guide_axis(check.overlap = TRUE),
      date_breaks = "1 year"
    ) +
    scale_fill_viridis_c() + sn_theme()
  ggsave(save_to,
         plot,
         width = 16,
         height = 9,
         dpi = 300)
  return(plot)
}

sn_plot_reprat_by_index_fixed <- function (d, save_to) 
{
  if (!all(c("year", "month", "variable", "rep_rat") %in% 
           names(d))) {
    stop("The data should contain at least the following columns: year, month, variable, rep_rat")
  }
  d[, `:=`(year, as.numeric(year))]
  d[, `:=`(month, as.numeric(month))]
  d[, `:=`(date, make_date(year, month, 1))]
  plot <- ggplot(d) + geom_tile(aes(x = .data$date, y = .data$variable, 
                                    fill = .data$rep_rat)) + scale_x_date(date_labels = "%Y", 
                                                                          guide = guide_axis(check.overlap = TRUE), date_breaks = "1 year") + 
    scale_fill_viridis_c() + sn_theme()
  ggsave(save_to, plot, width = 16, height = 9, dpi = 300)
  return(plot)
}


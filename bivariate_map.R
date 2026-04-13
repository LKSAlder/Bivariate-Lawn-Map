library(sf)
library(ggplot2)
library(dplyr)
library(classInt)
library(ggspatial)
library(patchwork)

# --------------------------------------------------
# 1. File paths
# --------------------------------------------------
base_folder <- "path/to/your/output/folder"

bf_path <- file.path(base_folder, "BF_NIG.shp")
mi_path <- file.path(base_folder, "MI_NIG.shp")
ot_path <- file.path(base_folder, "OT_NIG.shp")

# --------------------------------------------------
# 2. Read shapefiles
# --------------------------------------------------
bf <- st_read(bf_path, quiet = TRUE)
mi <- st_read(mi_path, quiet = TRUE)
ot <- st_read(ot_path, quiet = TRUE)

# --------------------------------------------------
# 3. Check required fields
# --------------------------------------------------
check_layer <- function(x, layer_name) {
  if (nrow(x) == 0) stop(paste(layer_name, "has 0 features."))
  if (!all(c("Lawn_Ratio", "Lawn_Rate_") %in% names(x))) {
    stop(paste(layer_name, "does not contain Lawn_Ratio and Lawn_Rate_."))
  }
}

check_layer(bf, "BF_NIG")
check_layer(mi, "MI_NIG")
check_layer(ot, "OT_NIG")

# --------------------------------------------------
# 4. Prepare fields and add city name
# --------------------------------------------------
prep_city <- function(x, city_name) {
  x %>%
    mutate(
      lawn_ratio    = as.numeric(Lawn_Ratio),
      lawn_coverage = as.numeric(Lawn_Rate_),
      City          = city_name
    ) %>%
    filter(!is.na(lawn_ratio), !is.na(lawn_coverage)) %>%
    st_transform(4326)
}

bf <- prep_city(bf, "Brantford")
mi <- prep_city(mi, "Mississauga")
ot <- prep_city(ot, "Ottawa")

# --------------------------------------------------
# 5. Create common 3x3 class breaks across all cities
# --------------------------------------------------
all_ratio <- c(bf$lawn_ratio, mi$lawn_ratio, ot$lawn_ratio)
all_cover <- c(bf$lawn_coverage, mi$lawn_coverage, ot$lawn_coverage)

nclass <- 3

ratio_breaks <- unique(classIntervals(all_ratio, n = nclass, style = "quantile")$brks)
cover_breaks <- unique(classIntervals(all_cover, n = nclass, style = "quantile")$brks)

if (length(ratio_breaks) < 4) stop("Not enough unique Lawn_Ratio values for 3 classes.")
if (length(cover_breaks) < 4) stop("Not enough unique Lawn_Rate_ values for 3 classes.")

# --------------------------------------------------
# 6. Assign 3x3 bivariate classes
# --------------------------------------------------
assign_bi_class <- function(x) {
  x %>%
    mutate(
      ratio_class = cut(lawn_ratio,    breaks = ratio_breaks, include.lowest = TRUE, labels = 1:3),
      cover_class = cut(lawn_coverage, breaks = cover_breaks, include.lowest = TRUE, labels = 1:3),
      bi_class    = paste0(ratio_class, "-", cover_class)
    )
}

bf <- assign_bi_class(bf)
mi <- assign_bi_class(mi)
ot <- assign_bi_class(ot)

# --------------------------------------------------
# 7. 3x3 bivariate palette
# Columns = Lawn Ratio (low → high)
# Rows    = Lawn Coverage (low → high)
# --------------------------------------------------
bi_pal <- c(
  "1-1" = "#e8e8e8", "2-1" = "#b5c0da", "3-1" = "#6c83b5",
  "1-2" = "#b8d6be", "2-2" = "#90b2b3", "3-2" = "#567994",
  "1-3" = "#73ae80", "2-3" = "#5a9178", "3-3" = "#2a5a5b"
)

# --------------------------------------------------
# 8. Shared legend labels
# --------------------------------------------------
make_range_labels <- function(brks, digits = 1) {
  sapply(1:(length(brks) - 1), function(i) {
    paste0(
      format(round(brks[i],     digits), nsmall = digits), "–",
      format(round(brks[i + 1], digits), nsmall = digits)
    )
  })
}

ratio_labels <- make_range_labels(ratio_breaks, digits = 1)
cover_labels <- make_range_labels(cover_breaks, digits = 1)

legend_df <- expand.grid(ratio_class = 1:3, cover_class = 1:3)
legend_df$bi_class <- paste0(legend_df$ratio_class, "-", legend_df$cover_class)

legend_plot <- ggplot(legend_df, aes(x = ratio_class, y = cover_class, fill = bi_class)) +
  geom_tile(color = "white", linewidth = 0.5) +
  scale_fill_manual(values = bi_pal, guide = "none") +
  scale_x_continuous(breaks = 1:3, labels = ratio_labels, expand = c(0, 0)) +
  scale_y_continuous(breaks = 1:3, labels = cover_labels, expand = c(0, 0)) +
  labs(x = "Lawn Ratio (%)", y = "Lawn Coverage (%)") +
  coord_equal() +
  theme_minimal(base_size = 8) +
  theme(
    panel.grid   = element_blank(),
    axis.title   = element_text(size = 9),
    axis.text.x  = element_text(size = 7, angle = 20, hjust = 1),
    axis.text.y  = element_text(size = 7),
    panel.border = element_rect(fill = NA, color = "grey50", linewidth = 0.4),
    plot.margin  = margin(5, 5, 5, 5)
  )

# --------------------------------------------------
# 9. Function to make one city map
# --------------------------------------------------
make_city_map <- function(x, city_title) {
  ggplot() +
    geom_sf(data = x, aes(fill = bi_class), color = "grey45", linewidth = 0.12) +
    scale_fill_manual(values = bi_pal, guide = "none", drop = FALSE) +
    coord_sf(expand = FALSE) +
    annotation_scale(location = "bl", width_hint = 0.30) +
    labs(title = city_title) +
    theme_minimal(base_size = 11) +
    theme(
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      axis.title       = element_blank(),
      axis.text        = element_text(size = 8, color = "black"),
      plot.title       = element_text(size = 12, face = "bold", hjust = 0.5),
      plot.margin      = margin(20, 8, 8, 8)
    )
}

# --------------------------------------------------
# 10. Assemble layout with legend at bottom
# --------------------------------------------------
p_bf <- make_city_map(bf, "Brantford")
p_mi <- make_city_map(mi, "Mississauga")
p_ot <- make_city_map(ot, "Ottawa")

bottom_layout <- (p_mi + p_ot + p_bf) /
  legend_plot +
  plot_layout(ncol = 1, heights = c(1, 0.25))

final_plot <- bottom_layout +
  plot_annotation(
    title    = "Bivariate Maps of Lawn Ratio and Lawn Coverage Across Three Cities",
    subtitle = "All three maps use the same 3×3 classification and shared legend",
    theme = theme(
      plot.title    = element_text(size = 16, face = "bold", hjust = 0),
      plot.subtitle = element_text(size = 10, hjust = 0),
      plot.margin   = margin(10, 10, 5, 10)
    )
  )

# --------------------------------------------------
# 11. Save output
# --------------------------------------------------
ggsave(
  filename = file.path(base_folder, "ThreeCity_Bivariate_3x3.png"),
  plot     = final_plot,
  width    = 16,
  height   = 8.5,
  dpi      = 300
)

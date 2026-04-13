# Bivariate Lawn Map

An R script for visualizing urban lawn ratio and lawn coverage as bivariate 
choropleth maps across three cities using a shared 3×3 classification scheme.

> This repository is a companion to [urban-vegetation-classification](https://github.com/LKSAlder/urban-vegetation-classification),
> which produces the neighbourhood-level vegetation statistics used as inputs here.

## What It Does

Takes neighbourhood polygon shapefiles with two vegetation metrics and produces
a single composite figure with:
- One choropleth map per city, coloured by a shared 3×3 bivariate scheme
- A shared legend tile showing the joint distribution of both variables
- A combined layout assembled with `patchwork`

## Variables Mapped

| Field | Description |
|-------|-------------|
| `Lawn_Ratio` | Lawn area as a proportion of total vegetation area (%) |
| `Lawn_Rate_` | Lawn area as a proportion of total neighbourhood area (%) |

## Inputs Required

One shapefile per city, each containing the two fields above. Class breaks are
computed jointly across all three cities so the colour scale is comparable.

## Requirements

```r
install.packages(c("sf", "ggplot2", "dplyr", "classInt", "ggspatial", "patchwork"))
```

## Usage

1. Set `base_folder` and the three shapefile names in the **File paths** section
2. Run the script — the output PNG is saved to the same folder

## Output

A single 16 × 8.5 inch PNG (`ThreeCity_Bivariate_3x3.png`) at 300 dpi.

## Colour Palette

The 3×3 palette encodes low-to-high Lawn Ratio on the x-axis and 
low-to-high Lawn Coverage on the y-axis:

|   | Low Ratio | Mid Ratio | High Ratio |
|---|-----------|-----------|------------|
| **High Coverage** | `#73ae80` | `#5a9178` | `#2a5a5b` |
| **Mid Coverage**  | `#b8d6be` | `#90b2b3` | `#567994` |
| **Low Coverage**  | `#e8e8e8` | `#b5c0da` | `#6c83b5` |

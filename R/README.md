
# nolaOpenData

[![CRAN
downloads](https://cranlogs.r-pkg.org/badges/grand-total/nolaOpenData?color=blue)](https://r-pkg.org/pkg/nolaOpenData)
[![Lifecycle:
stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html)
[![Project Status:
Active](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)

`nolaOpenData` provides a lightweight R interface to the [New Orleans
Open Data Portal](https://data.nola.gov/).

The package allows users to search, filter, and download datasets from
the New Orleans Open Data Portal directly into R without manually
constructing API queries, handling JSON responses, or performing type
conversion.

Designed for students, educators, researchers, journalists, civic
technologists, and analysts, `nolaOpenData` reduces the technical
overhead required to begin working with municipal Open Data while
preserving access to the underlying Socrata infrastructure.

------------------------------------------------------------------------

## How `nolaOpenData` Works

The package provides a streamlined interface to the New Orleans Open
Data Portal’s Socrata API.

Internally, `nolaOpenData`:

- retrieves metadata from the live New Orleans Open Data catalog
- constructs parameterized HTTP requests
- downloads JSON responses from Socrata endpoints
- converts results into tidy tibble outputs
- optionally cleans column names
- optionally performs conservative type coercion

Most workflows begin with `nola_list_datasets()`, which retrieves a live
catalog of datasets available through the New Orleans Open Data Portal.

Datasets can then be downloaded using either:

- a human-readable catalog `key`
- the official Socrata dataset UID, such as `"wx2k-rsac"`

The human-readable key is designed to improve readability and usability,
while the UID is the stable identifier used by the Socrata platform.

## Core Functions

The package provides three primary functions:

- `nola_list_datasets()` retrieves a live catalog of available New
  Orleans Open Data datasets, including human-readable keys, Socrata
  UIDs, names, and other available metadata.

- `nola_pull_dataset()` downloads cataloged datasets using either a
  human-readable key or Socrata UID, with support for filtering,
  ordering, date ranges, optional column-name cleaning, and optional
  type coercion.

- `nola_any_dataset()` downloads data directly from a valid Socrata JSON
  endpoint without requiring the dataset to appear in the package
  catalog.

Datasets retrieved through `nola_pull_dataset()` support arguments
including:

- `limit`
- `filters`
- `date`
- `from`
- `to`
- `date_field`
- `where`
- `order`
- `clean_names`
- `coerce_types`

All functions return tibble outputs.

Advanced users may also provide raw SoQL conditions through the `where`
argument.

SoQL, or Socrata Query Language, is the query syntax used by
Socrata-powered Open Data portals. Additional information is available
from the [Socrata developer
documentation](https://dev.socrata.com/docs/queries/).

------------------------------------------------------------------------

## Installation

### Install from CRAN

``` r
install.packages("nolaOpenData")
```

### Install the development version from GitHub

``` r
# install.packages("pak")
pak::pak("gomes-sh/nolaOpenData")
```

Alternatively:

``` r
# install.packages("remotes")
remotes::install_github("gomes-sh/nolaOpenData")
```

------------------------------------------------------------------------

## Example

``` text
library(nolaOpenData)
library(dplyr)

# Browse available datasets
catalog <- nola_list_datasets()

# Search for datasets containing a keyword
catalog |>
  filter(grepl("hiring", name, ignore.case = TRUE)) |>
  select(key, uid, name)

# Pull a dataset using its UID
example_data <- nola_pull_dataset(
  dataset = "wx2k-rsac",
  limit = 100
)

# Pull the same dataset using its catalog key
example_data_by_key <- nola_pull_dataset(
  dataset = "city_jobs_hiring_data",
  limit = 100
)

# Pull filtered data
filtered_data <- nola_pull_dataset(
  dataset = "wx2k-rsac",
  limit = 100,
  filters = list(
    department = "Safety & Permits"
  )
)
```

The `filters` argument accepts a named list and automatically constructs
the corresponding SoQL filtering conditions.

Multiple values may be supplied for one field:

``` text
filtered_data <- nola_pull_dataset(
  dataset = "wx2k-rsac",
  limit = 100,
  filters = list(
    department = c("Safety & Permits", "FIRE")
  )
)
```

Multiple fields may also be combined:

``` text
filtered_data <- nola_pull_dataset(
  dataset = "wx2k-rsac",
  limit = 100,
  filters = list(
    department = "Safety & Permits",
    job_title = "BUILDING INSPECTOR SUPERVISOR (CLASS CODE 2214)"
  )
)
```

Date filtering is available for datasets containing date or datetime
fields:

``` text
date_filtered_data <- nola_pull_dataset(
  dataset = "wx2k-rsac",
  from = "2025-01-01",
  to = "2026-01-01",
  date_field = "start_date",
  limit = 100
)
```

------------------------------------------------------------------------

## Accessing Any Socrata Endpoint

When a dataset is not available through `nola_list_datasets()`, it can
be downloaded directly using `nola_any_dataset()`.

``` text
endpoint_data <- nola_any_dataset(
  json_link = "https://data.nola.gov/resource/wx2k-rsac.json",
  limit = 100
)
```

Use `nola_pull_dataset()` for catalog-based workflows and
`nola_any_dataset()` when working directly with a Socrata JSON endpoint.

------------------------------------------------------------------------

## Learn by Example

A complete introductory workflow is available in the package vignette:

``` r
vignette("getting-started", package = "nolaOpenData")
```

The vignette demonstrates how to:

- browse the dataset catalog
- download data using a key or UID
- filter records
- work with date ranges
- access direct JSON endpoints
- perform a simple analysis

------------------------------------------------------------------------

## Package Website

Complete documentation is available on the package website:

<https://github.com/gomes-sh/nolaOpenData>

The website includes:

- function reference pages
- installation instructions
- introductory articles
- vignettes
- release notes

------------------------------------------------------------------------

## Development

To run the package tests locally:

``` r
devtools::test()
```

To rebuild the documentation:

``` r
devtools::document()
```

To run a complete package check:

``` r
devtools::check()
```

To rebuild the pkgdown website:

``` r
pkgdown::build_site()
```

------------------------------------------------------------------------

## Contributing

Contributions are welcome.

To report a bug, request a feature, or suggest an improvement, open an
issue on GitHub:

<https://github.com/gomes-sh/nolaOpenData/issues>

Pull requests are also welcome. Before submitting a pull request, please
ensure that:

- package documentation has been regenerated
- automated tests pass
- `devtools::check()` completes successfully
- new behavior is documented and tested

------------------------------------------------------------------------

## Author

**Shelby Lyn Gomes**

Email: <gomessh@mailbox.org>  
GitHub: [@gomes-sh](https://github.com/gomes-sh)

------------------------------------------------------------------------

## Maintenance

Because the package retrieves metadata dynamically from the live New
Orleans Open Data catalog, newly published datasets may become available
without requiring a package update.

Package updates may still be required when the portal changes its
catalog structure, dataset metadata fields, or API behavior.

------------------------------------------------------------------------

## Disclaimer

`nolaOpenData` is an independent project and is not affiliated with,
endorsed by, or maintained by New Orleans or the organization
responsible for the New Orleans Open Data Portal.

#' Pull a CITY_NAME Open Data dataset
#'
#' Downloads a dataset from the CITY_NAME Open Data Socrata API using either a
#' human-readable catalog `key` or the official Socrata dataset `uid` returned by
#' [city_list_datasets()].
#'
#' When a catalog `key` is supplied, `city_pull_dataset()` first retrieves the
#' live CITY_NAME Open Data catalog to look up the corresponding Socrata `uid`,
#' then sends a second request to download the dataset itself. Supplying a `uid`
#' directly is more stable and avoids ambiguity, while keys are provided for
#' readability and classroom-friendly workflows.
#'
#' Dataset keys are generated from dataset names using
#' [janitor::make_clean_names()]. Because keys are derived from live catalog
#' metadata, Socrata UIDs are the most stable identifiers.
#'
#' @param dataset A single dataset `key` or Socrata dataset `uid` from
#'   [city_list_datasets()]. For example, a key may look like
#'   `"example_dataset_name"`, while a UID may look like `"abcd-1234"`.
#' @param limit Number of rows to retrieve. Defaults to 10,000.
#' @param filters Optional named list of exact-match filters. Each list name
#'   should be a field name in the dataset, and each value should be the value
#'   or values to match. Vector values are translated into SQL-style `IN`
#'   conditions in the generated SoQL query. For example,
#'   `filters = list(FILTER_FIELD = c("VALUE_1", "VALUE_2"))` returns rows where
#'   `FILTER_FIELD` is either `"VALUE_1"` or `"VALUE_2"`.
#' @param date Optional single date used to match all records from that day.
#'   Requires `date_field`.
#' @param from Optional start date, inclusive. Requires `date_field`.
#' @param to Optional end date, exclusive. Requires `date_field`.
#' @param date_field Optional date or datetime column to use with `date`,
#'   `from`, or `to`. This must be supplied when any date filter is used. Users
#'   can identify available date columns by inspecting the dataset on the
#'   CITY_NAME Open Data Portal or by pulling a small sample with `limit`.
#' @param where Optional raw SoQL `WHERE` clause for advanced filtering. SoQL is
#'   the Socrata Query Language used by CITY_NAME Open Data. If `date`, `from`,
#'   or `to` are also supplied, their generated conditions are combined with
#'   `where` using `AND`.
#' @param order Optional raw SoQL `ORDER BY` clause, such as
#'   `"DATE_FIELD DESC"`.
#' @param timeout_sec Request timeout in seconds. Defaults to 30.
#' @param clean_names Logical. If `TRUE`, column names are converted to
#'   snake_case using [janitor::clean_names()]. Defaults to `TRUE`.
#' @param coerce_types Logical. If `TRUE`, the package attempts lightweight,
#'   heuristic-based type coercion after downloading the data. Columns are
#'   converted only when at least 95 percent of non-missing values can be parsed
#'   as the target type. This helps avoid unsafe conversions when source data are
#'   inconsistent.
#'
#' @return A tibble containing rows from the requested CITY_NAME Open Data
#'   dataset.
#'
#' @details
#' `city_pull_dataset()` is designed for common catalog-based workflows. For
#' arbitrary Socrata JSON endpoints that are not included in the package catalog,
#' use [city_any_dataset()].
#'
#' The `filters` argument is intended for simple exact-match filtering. For more
#' complex conditions, use the `where` argument with raw SoQL syntax.
#'
#' Internally, filter field names are wrapped in `TRIM()` when constructing SoQL
#' queries to reduce mismatches caused by leading or trailing whitespace in
#' source data.
#'
#' Type coercion is intentionally conservative. When `coerce_types = TRUE`, the
#' package attempts to infer common R column types from the API response, but
#' columns with inconsistent values may remain character columns.
#'
#' Datetime coercion is also conservative. Timezone offsets and sub-second
#' precision may not always be preserved during automatic parsing, and columns
#' with inconsistent datetime formats may remain character columns.
#'
#' @examples
#' if (interactive() && curl::has_internet()) {
#'   # Pull by human-readable key
#'   city_pull_dataset("example_dataset_name", limit = 3)
#'
#'   # Pull by Socrata UID
#'   city_pull_dataset("abcd-1234", limit = 3)
#'
#'   # Filter to one value
#'   city_pull_dataset(
#'     "abcd-1234",
#'     limit = 3,
#'     filters = list(FILTER_FIELD = "VALUE_1")
#'   )
#'
#'   # Filter to multiple values
#'   city_pull_dataset(
#'     "abcd-1234",
#'     limit = 10,
#'     filters = list(FILTER_FIELD = c("VALUE_1", "VALUE_2"))
#'   )
#'
#'   # Date filtering
#'   city_pull_dataset(
#'     "abcd-1234",
#'     from = "2023-01-01",
#'     to = "2024-01-01",
#'     date_field = "DATE_FIELD",
#'     limit = 100
#'   )
#'
#'   # Advanced filtering with raw SoQL
#'   city_pull_dataset(
#'     "abcd-1234",
#'     where = "FILTER_FIELD = 'VALUE_1' AND SECOND_FIELD = 'VALUE_2'",
#'     order = "DATE_FIELD DESC",
#'     limit = 100
#'   )
#' }
#'
#' @export
city_pull_dataset <- function(dataset,
                              limit = 10000,
                              filters = list(),
                              date = NULL,
                              from = NULL,
                              to = NULL,
                              date_field = NULL,
                              where = NULL,
                              order = NULL,
                              timeout_sec = 30,
                              clean_names = TRUE,
                              coerce_types = TRUE) {

  # dataset validation
  if (!is.character(dataset) ||
      length(dataset) != 1 ||
      is.na(dataset) ||
      !nzchar(dataset)) {
    stop(
      "`dataset` must be a single, non-missing character value.",
      call. = FALSE
    )
  }

  cat_tbl <- .city_catalog_tbl()

  # sanity checks on required columns
  req <- c("key", "uid")
  missing_req <- setdiff(req, names(cat_tbl))

  if (length(missing_req) > 0) {
    stop(
      paste0(
        "Internal error: catalog missing required column(s): ",
        paste(missing_req, collapse = ", "),
        "."
      ),
      call. = FALSE
    )
  }

  row <- cat_tbl[
    cat_tbl$key == dataset | cat_tbl$uid == dataset,
    ,
    drop = FALSE
  ]

  if (nrow(row) == 0) {
    stop(
      paste0(
        "Unknown dataset: '", dataset, "'. ",
        "Use `city_list_datasets()` to see available keys and UIDs."
      ),
      call. = FALSE
    )
  }

  if (nrow(row) > 1) {
    stop(
      paste0(
        "Multiple catalog matches found for '", dataset, "'. ",
        "Please use the dataset UID instead."
      ),
      call. = FALSE
    )
  }

  uid <- row$uid[[1]]

  # require date_field if user supplies date filters
  if ((!is.null(date) || !is.null(from) || !is.null(to)) &&
      (is.null(date_field) ||
       !is.character(date_field) ||
       length(date_field) != 1 ||
       !nzchar(date_field))) {
    .city_abort(
      paste0(
        "If `date`, `from`, or `to` are supplied, you must also ",
        "provide a single non-empty `date_field`."
      )
    )
  }

  date_where <- .city_build_date_where(
    date_field = date_field,
    date = date,
    from = from,
    to = to
  )

  where_final <- where

  if (!is.null(date_where)) {
    if (is.null(where_final) || !nzchar(where_final)) {
      where_final <- date_where
    } else {
      where_final <- paste0(
        "(",
        where_final,
        ") AND (",
        date_where,
        ")"
      )
    }
  }

  .city_dataset_request(
    dataset_id = uid,
    limit = limit,
    filters = filters,
    order = order,
    where = where_final,
    timeout_sec = timeout_sec,
    clean_names = clean_names,
    coerce_types = coerce_types
  )
}

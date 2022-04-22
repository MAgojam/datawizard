
#' @title Read (import) data files from various sources
#' @name data_read
#'
#' @description
#' This functions imports data from various file types. It is a small wrapper
#' around `haven::read_spss()`, `haven::read_stata()`, `haven::read_sas()`,
#' `readxl::read_excel()` and `data.table::fread()` resp. `readr::read_delim()`
#' (the latter if package **data.table** is not installed). Thus, supported file
#' types for importing data are data files from SPSS, SAS or Stata, Excel files
#' or text files (like '.csv' files). All non-supported file types are passed
#' to `rio::import()`.
#'
#' @param path Character string, the file path to the data file.
#' @param path_catalog Character string, path to the catalog file. Only relevant
#' for SAS data files.
#' @param encoding The character encoding used for the file. Usually not needed.
#' @param verbose Toggle warnings and messages.
#' @param ... Arguments passed to the related `read_*()` function.
#'
#' @return A data frame.
#'
#' @section Supported file types:
#' `data_read()` is a wrapper around the **haven**, **data.table**, **readr**
#'  **readxl** and **rio** packages. Currently supported file types are `.txt`,
#'  `.csv`, `.xls`, `.xlsx`, `.sav`, `.por`, `.dta` and `.sas` (and related
#'  files). All other file types are passed to `rio::import()`.
#'
#' @section Compressed files (zip) and URLs:
#' `data_read()` can also read the above mentioned files from URLs or from
#' inside zip-compressed files. Thus, `path` can also be a URL to a file like
#' `"http://www.url.com/file.csv"`. When `path` points to a zip-compressed file,
#' and there are multiple files inside the zip-archive, then the first supported
#' file is extracted and loaded.
#'
#' @section General behaviour:
#' `data_read()` detects the appropriate `read_*()` function based on the
#' file-extension of the data file. Thus, in most cases it should be enough to
#' only specify the `path` argument. However, if more control is needed, all
#' arguments in `...` are passed down to the related `read_*()` function.
#'
#' @section Differences to other packages that read foreign data formats:
#' `data_read()` is most comparable to `rio::import()`. For data files from
#' SPSS, SAS or Stata, which support labelled data, variables are converted into
#' their most appropriate type. The major difference to `rio::import()` is
#' that `data_read()` automatically converts variables into factors, unless
#' the variables are only partially labelled, in which case variables are
#' converted to numerics. Character vectors are preserved. Hence, variables,
#' where _all_ values are labelled, will be converted into factors, where
#' imported value labels will be set as factor levels. Else, if a variable
#' has _no_ value labels or less value labels than values, the variable is
#' either converted into numeric or character vector. Value labels are then
#' preserved as `"labels"` attribute.
#'
#' @export
data_read <- function(path, path_catalog = NULL, encoding = NULL, verbose = TRUE, ...) {
  # extract first valid file from zip-file
  if (.file_ext(path) == "zip") {
    path <- .extract_zip(path)
  }

  # read data
  switch(
    .file_ext(path),
    "txt" = ,
    "csv" = .read_text(path, encoding, verbose, ...),
    "xls" = ,
    "xlsx" = .read_excel(path, encoding, verbose, ...),
    "sav" = ,
    "por" = .read_spss(path, encoding, verbose, ...),
    "dta" = .read_stata(path, encoding, verbose, ...),
    "sas7bdat" = .read_sas(path, path_catalog, encoding, verbose, ...),
    .read_unknown(path, verbose, ...)
  )
}



# helper -----------------------

.file_ext <- function(x) {
  pos <- regexpr("\\.([[:alnum:]]+)$", x)
  ifelse(pos > -1L, substring(x, pos + 1L), "")
}


.extract_zip <- function(path) {
  files <- utils::unzip(path, list = TRUE)
  files_ext <- sapply(files$Name, .file_ext)

  supported_filetypes <- c("txt", "csv", "xls", "xlsx", "sav", "por", "dta")
  dest <- files$Name[which(files_ext %in% supported_filetypes)]

  if (length(dest) > 0) {
    d <- tempfile()
    dir.create(d)
    utils::unzip(path, exdir = d)
    path <- file.path(d, dest[1])
  } else {
    stop("The zip-file does not contain any supported file types.", call. = FALSE)
  }

  path
}



# process imported data from SPSS, SAS or Stata -----------------------

.post_process_imported_data <- function(x, verbose) {
  if (verbose) {
    message("Preparing data... Almost there!")
  }
  x[] <- lapply(x, function(i) {
    # save labels
    value_labels <- attr(i, "labels", exact = TRUE)
    variable_labels <- attr(i, "label", exact = TRUE)

    # filter, so only matching value labels remain
    value_labels <- value_labels[value_labels %in% unique(i)]

    # guess variable type
    if (!is.character(i)) {
      # if all values are labelled, we assume factor. Use labels as levels
      if (length(value_labels) == insight::n_unique(i)) {
        i <- factor(as.character(i), labels = names(value_labels))
        value_labels <- NULL
      } else {
        i <- as.numeric(i)
      }
    } else {
      i <- as.character(i)
    }

    # drop unused value labels
    if (!is.null(value_labels) && length(value_labels <- value_labels[value_labels %in% unique(i)])) {
      attr(i, "labels") <- value_labels
    }

    # add back variable label
    attr(i, "label") <- variable_labels
    i
  })

  class(x) <- "data.frame"
  x
}



# read functions -----------------------

.read_spss <- function(path, encoding, verbose, ...) {
  insight::check_if_installed("haven", reason = paste0("to read files of type '", .file_ext(path), "'"))
  if (verbose) {
    message("Reading data...")
  }
  out <- haven::read_sav(file = path, encoding = encoding, user_na = FALSE, ...)
  .post_process_imported_data(out, verbose)
}


.read_stata <- function(path, encoding, verbose, ...) {
  insight::check_if_installed("haven", reason = paste0("to read files of type '", .file_ext(path), "'"))
  if (verbose) {
    message("Reading data...")
  }
  out <- haven::read_dta(file = path, encoding = encoding, ...)
  .post_process_imported_data(out, verbose)
}


.read_sas <- function(path, path_catalog, encoding, verbose, ...) {
  insight::check_if_installed("haven", reason = paste0("to read files of type '", .file_ext(path), "'"))
  if (verbose) {
    message("Reading data...")
  }
  out <- haven::read_sas(data_file = path, catalog_file = path_catalog, encoding = encoding, ...)
  .post_process_imported_data(out, verbose)
}


.read_excel <- function(path, encoding, verbose, ...) {
  insight::check_if_installed("readxl", reason = paste0("to read files of type '", .file_ext(path), "'"))
  if (verbose) {
    message("Reading data...")
  }
  out <- readxl::read_excel(path, ...)
  class(out) <- "data.frame"
  out
}


.read_text <- function(path, encoding, verbose, ...) {
  if (insight::check_if_installed("data.table", quietly = TRUE)) {
    out <- data.table::fread(input = path, ...)
    class(out) <- "data.frame"
    return(out)
  }

  insight::check_if_installed("readr", reason = paste0("to read files of type '", .file_ext(path), "'"))
  if (verbose) {
    message("Reading data...")
  }
  out <- readr::read_delim(path, ...)
  class(out) <- "data.frame"
  out
}


.read_unknown <- function(path, verbose, ...) {
  insight::check_if_installed("rio", reason = paste0("to read files of type '", .file_ext(path), "'"))
  if (verbose) {
    message("Reading data...")
  }
  out <- rio::import(file = path, ...)
  .post_process_imported_data(out, verbose)
}
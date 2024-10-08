#' @title Rescale design weights for multilevel analysis
#' @name rescale_weights
#'
#' @description Most functions to fit multilevel and mixed effects models only
#'   allow to specify frequency weights, but not design (i.e. sampling or
#'   probability) weights, which should be used when analyzing complex samples
#'   and survey data. `rescale_weights()` implements an algorithm proposed
#'   by \cite{Asparouhov (2006)} and \cite{Carle (2009)} to rescale design
#'   weights in survey data to account for the grouping structure of multilevel
#'   models, which then can be used for multilevel modelling.
#'
#' @param data A data frame.
#' @param by Variable names (as character vector, or as formula), indicating
#'   the grouping structure (strata) of the survey data (level-2-cluster
#'   variable). It is also possible to create weights for multiple group
#'   variables; in such cases, each created weighting variable will be suffixed
#'   by the name of the group variable.
#' @param probability_weights Variable indicating the probability (design or
#'   sampling) weights of the survey data (level-1-weight).
#' @param nest Logical, if `TRUE` and `by` indicates at least two
#'   group variables, then groups are "nested", i.e. groups are now a
#'   combination from each group level of the variables in `by`.
#'
#' @return `data`, including the new weighting variables: `pweights_a`
#'   and `pweights_b`, which represent the rescaled design weights to use
#'   in multilevel models (use these variables for the `weights` argument).
#'
#' @details
#'
#' Rescaling is based on two methods: For `pweights_a`, the sample weights
#' `probability_weights` are adjusted by a factor that represents the proportion
#' of group size divided by the sum of sampling weights within each group. The
#' adjustment factor for `pweights_b` is the sum of sample weights within each
#' group divided by the sum of squared sample weights within each group (see
#' Carle (2009), Appendix B). In other words, `pweights_a` "scales the weights
#' so that the new weights sum to the cluster sample size" while `pweights_b`
#' "scales the weights so that the new weights sum to the effective cluster
#' size".
#'
#' Regarding the choice between scaling methods A and B, Carle suggests that
#' "analysts who wish to discuss point estimates should report results based on
#' weighting method A. For analysts more interested in residual between-group
#' variance, method B may generally provide the least biased estimates". In
#' general, it is recommended to fit a non-weighted model and weighted models
#' with both scaling methods and when comparing the models, see whether the
#' "inferential decisions converge", to gain confidence in the results.
#'
#' Though the bias of scaled weights decreases with increasing group size,
#' method A is preferred when insufficient or low group size is a concern.
#'
#' The group ID and probably PSU may be used as random effects (e.g. nested
#' design, or group and PSU as varying intercepts), depending on the survey
#' design that should be mimicked.
#'
#' @references
#'   - Carle A.C. (2009). Fitting multilevel models in complex survey data
#'   with design weights: Recommendations. BMC Medical Research Methodology
#'   9(49): 1-13
#'
#'   - Asparouhov T. (2006). General Multi-Level Modeling with Sampling
#'   Weights. Communications in Statistics - Theory and Methods 35: 439-460
#'
#' @examples
#' if (require("lme4")) {
#'   data(nhanes_sample)
#'   head(rescale_weights(nhanes_sample, "SDMVSTRA", "WTINT2YR"))
#'
#'   # also works with multiple group-variables
#'   head(rescale_weights(nhanes_sample, c("SDMVSTRA", "SDMVPSU"), "WTINT2YR"))
#'
#'   # or nested structures.
#'   x <- rescale_weights(
#'     data = nhanes_sample,
#'     by = c("SDMVSTRA", "SDMVPSU"),
#'     probability_weights = "WTINT2YR",
#'     nest = TRUE
#'   )
#'   head(x)
#'
#'   nhanes_sample <- rescale_weights(nhanes_sample, "SDMVSTRA", "WTINT2YR")
#'
#'   glmer(
#'     total ~ factor(RIAGENDR) * (log(age) + factor(RIDRETH1)) + (1 | SDMVPSU),
#'     family = poisson(),
#'     data = nhanes_sample,
#'     weights = pweights_a
#'   )
#' }
#' @export
rescale_weights <- function(data, by, probability_weights, nest = FALSE) {
  if (inherits(by, "formula")) {
    by <- all.vars(by)
  }

  # check if weight has missings. we need to remove them first,
  # and add back weights to correct cases later

  weight_missings <- which(is.na(data[[probability_weights]]))
  weight_non_na <- which(!is.na(data[[probability_weights]]))

  if (length(weight_missings) > 0) {
    data_tmp <- data[weight_non_na, ]
  } else {
    data_tmp <- data
  }

  # sort id
  data_tmp$.bamboozled <- seq_len(nrow(data_tmp))

  if (nest && length(by) < 2) {
    insight::format_warning(
      sprintf(
        "Only one group variable selected in `by`, no nested structure possible. Rescaling weights for grout '%s' now.",
        by
      )
    )
    nest <- FALSE
  }

  if (nest) {
    out <- .rescale_weights_nested(data_tmp, group = by, probability_weights, nrow(data), weight_non_na)
  } else {
    out <- lapply(by, function(i) {
      x <- .rescale_weights(data_tmp, i, probability_weights, nrow(data), weight_non_na)
      if (length(by) > 1) {
        colnames(x) <- sprintf(c("pweight_a_%s", "pweight_b_%s"), i)
      }
      x
    })
  }

  do.call(cbind, list(data, out))
}





# rescale weights, for one or more group variables ----------------------------

.rescale_weights <- function(x, group, probability_weights, n, weight_non_na) {
  # compute sum of weights per group
  design_weights <- .data_frame(
    group = sort(unique(x[[group]])),
    sum_weights_by_group = tapply(x[[probability_weights]], as.factor(x[[group]]), sum),
    sum_squared_weights_by_group = tapply(x[[probability_weights]]^2, as.factor(x[[group]]), sum),
    n_per_group = as.vector(table(x[[group]]))
  )

  colnames(design_weights)[1] <- group
  x <- merge(x, design_weights, by = group, sort = FALSE)

  # restore original order
  x <- x[order(x$.bamboozled), ]
  x$.bamboozled <- NULL

  # multiply the original weight by the fraction of the
  # sampling unit total population based on Carle 2009

  w_a <- x[[probability_weights]] * x$n_per_group / x$sum_weights_by_group
  w_b <- x[[probability_weights]] * x$sum_weights_by_group / x$sum_squared_weights_by_group

  out <- data.frame(
    pweights_a = rep(NA_real_, times = n),
    pweights_b = rep(NA_real_, times = n)
  )

  out$pweights_a[weight_non_na] <- w_a
  out$pweights_b[weight_non_na] <- w_b

  out
}



# rescale weights, for nested groups ----------------------------

.rescale_weights_nested <- function(x, group, probability_weights, n, weight_non_na) {
  groups <- expand.grid(lapply(group, function(i) sort(unique(x[[i]]))))
  colnames(groups) <- group

  # compute sum of weights per group
  design_weights <- cbind(
    groups,
    .data_frame(
      sum_weights_by_group = unlist(as.list(tapply(
        x[[probability_weights]], lapply(group, function(i) {
          as.factor(x[[i]])
        }), sum
      )), use.names = FALSE),
      sum_squared_weights_by_group = unlist(as.list(tapply(
        x[[probability_weights]]^2, lapply(group, function(i) {
          as.factor(x[[i]])
        }), sum
      )), use.names = FALSE),
      n_per_group = unlist(as.list(table(x[, group])), use.names = FALSE)
    )
  )

  x <- merge(x, design_weights, by = group, sort = FALSE)

  # restore original order
  x <- x[order(x$.bamboozled), ]
  x$.bamboozled <- NULL

  # multiply the original weight by the fraction of the
  # sampling unit total population based on Carle 2009

  w_a <- x[[probability_weights]] * x$n_per_group / x$sum_weights_by_group
  w_b <- x[[probability_weights]] * x$sum_weights_by_group / x$sum_squared_weights_by_group

  out <- data.frame(
    pweights_a = rep(NA_real_, times = n),
    pweights_b = rep(NA_real_, times = n)
  )

  out$pweights_a[weight_non_na] <- w_a
  out$pweights_b[weight_non_na] <- w_b

  out
}

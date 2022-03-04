data(efc, package = "datawizard")

# data_reverse -----------------------------------

test_that("data_reverse, labels preserved", {
  expect_equal(
    attr(data_reverse(efc$e42dep), "label", exact = TRUE),
    "elder's dependency"
  )

  expect_equal(
    names(attr(data_reverse(efc$e42dep), "labels", exact = TRUE)),
    names(attr(efc$e42dep, "labels", exact = TRUE))
  )

  expect_equal(
    attr(data_reverse(efc$e42dep), "labels", exact = TRUE),
    rev(attr(efc$e42dep, "labels", exact = TRUE)),
    ignore_attr = TRUE
  )

  expect_equal(
    names(attr(data_reverse(efc$c12hour), "labels", exact = TRUE)),
    names(attr(efc$c12hour, "labels", exact = TRUE))
  )

  labels <- sapply(data_reverse(efc), function(i) attr(i, "label", exact = TRUE))
  expect_equal(
    labels,
    c(c12hour = "average number of hours of care per week",
      e16sex = "elder's gender",
      e42dep = "elder's dependency",
      c172code = "carer's level of education",
      neg_c_7 = "Negative impact with 7 items")
  )
})



# data_merge -----------------------------------

test_that("data_merge, labels preserved", {
  labels <- sapply(data_merge(efc[c(1:2)], efc[c(3:4)], verbose = FALSE), function(i) attr(i, "label", exact = TRUE))
  expect_equal(
    labels,
    c(c12hour = "average number of hours of care per week",
      e16sex = "elder's gender",
      e42dep = "elder's dependency",
      c172code = "carer's level of education"
    )
  )
})



# data_extract -----------------------------------

test_that("data_extract, labels preserved", {
  expect_equal(
    attr(data_extract(efc, select = "e42dep"), "labels", exact = TRUE),
    attr(efc$e42dep, "labels", exact = TRUE),
    ignore_attr = TRUE
  )

  labels <- sapply(data_extract(efc, select = c("e42dep", "c172code")), function(i) attr(i, "label", exact = TRUE))
  expect_equal(labels, c("elder's dependency", "carer's level of education"))
})



# data_cut -----------------------------------

test_that("data_cut, labels preserved", {
  expect_equal(
    attr(data_cut(efc$c12hour), "label", exact = TRUE),
    attr(efc$c12hour, "label", exact = TRUE),
    ignore_attr = TRUE
  )

  expect_equal(
    attr(data_cut(efc$e42dep), "label", exact = TRUE),
    attr(efc$e42dep, "label", exact = TRUE),
    ignore_attr = TRUE
  )
})



# data_reorder -----------------------------------

test_that("data_reorder, labels preserved", {
  expect_equal(
    attr(data_reorder(efc, "e42dep")[[1]], "label", exact = TRUE),
    attr(efc$e42dep, "label", exact = TRUE),
    ignore_attr = TRUE
  )
})



# data_remove -----------------------------------

test_that("data_remove, labels preserved", {
  expect_equal(
    attr(data_remove(efc, "e42dep")[[1]], "label", exact = TRUE),
    attr(efc$c12hour, "label", exact = TRUE),
    ignore_attr = TRUE
  )
})



# data_rename -----------------------------------

test_that("data_rename, labels preserved", {
  x <- data_rename(efc, "e42dep", "dependency")
  expect_equal(
    attr(x$dependency, "label", exact = TRUE),
    attr(efc$e42dep, "label", exact = TRUE),
    ignore_attr = TRUE
  )
})



# data_addprefix -----------------------------------

test_that("data_addprefix, labels preserved", {
  x <- data_addprefix(efc, "new_")
  expect_equal(
    attr(x$new_e42dep, "label", exact = TRUE),
    attr(efc$e42dep, "label", exact = TRUE),
    ignore_attr = TRUE
  )
})



# data_suffix -----------------------------------

test_that("data_addsuffix, labels preserved", {
  x <- data_addsuffix(efc, "_new")
  expect_equal(
    attr(x$e42dep_new, "label", exact = TRUE),
    attr(efc$e42dep, "label", exact = TRUE),
    ignore_attr = TRUE
  )
})
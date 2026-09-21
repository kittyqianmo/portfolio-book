## -----------------------------------------------------------------------------
#| include: false
has_rdatagouv <- requireNamespace("rdatagouv", quietly = TRUE)
if (has_rdatagouv) {
  library(rdatagouv)
}
library(dplyr)     # for the pipe workflow (pull(), head())
knitr::opts_hooks$set(
  live = function(options) {
    if (isTRUE(options$live)) {
      # Evaluate only when explicitly opted in. Fail closed: absent or unset
      # DATAGOUV_LIVE means "do not touch the network", which is what R CMD
      # build/check (and any ordinary render) want.
      options$eval <- toupper(Sys.getenv("DATAGOUV_LIVE")) == "1"
    }
    options
  },
  dg = function(options) {
    # Gate the in-memory, network-free example chunks (marked `#| dg: <fn>`)
    # so a broken install can never abort R CMD build/check. We fail closed:
    # the chunk runs only on the website — pkgdown sets DATAGOUV_LIVE=1, where
    # the package is guaranteed to work — and is skipped during the packaging
    # build, which normally does not set that variable. A requireNamespace()/
    # get() "is it callable?" prediction proved unreliable on Windows/R-devel,
    # where a present-but-unforceable lazy-load export reports callable yet
    # throws when the function is actually invoked, hard-failing the build
    # (see AGENTS.md). Gating on DATAGOUV_LIVE is therefore a best-effort
    # guard: even with the chunk allowed to run, it can no longer abort the
    # render, because its body is wrapped in try() (a low-level catch-all
    # that contains even the unforceable-export hard failure) and it sets
    # `#| error: true`. dg_summary()/dg_summarise() are still fully exercised
    # by the test suite.
    fun <- options$dg
    ok <- is.character(fun) && length(fun) == 1L &&
      toupper(Sys.getenv("DATAGOUV_LIVE")) == "1" &&
      "package:rdatagouv" %in% search() &&
      !is.null(tryCatch(get(fun, inherits = TRUE), error = function(e) NULL))
    options$eval <- ok && isTRUE(options$eval)
    options
  }
)


## -----------------------------------------------------------------------------
#| live: true
library(rdatagouv)

datasets <- dg_find_datasets(n = 20)
head(datasets)


## -----------------------------------------------------------------------------
#| live: true
cycle <- dg_find_datasets(q = "vélo", n = 10, resources = TRUE)
cycle[, c("title", "n_resources", "has_table", "has_schema")]


## -----------------------------------------------------------------------------
#| live: true
documented <- dg_find_datasets(schema_only = TRUE, n = 10)
documented[, c("title", "has_schema")]


## -----------------------------------------------------------------------------
#| live: true
parquet <- dg_find_datasets(format = "parquet", n = 10)
parquet[, c("title", "formats")]


## -----------------------------------------------------------------------------
#| live: true
orgs <- dg_find_organization(q = "SNCF")
orgs[, c("name", "slug", "datasets")]


## -----------------------------------------------------------------------------
#| live: true
sncf <- dg_find_datasets(organization = "sncf", n = 10)
sncf[, c("title", "organization")]


## -----------------------------------------------------------------------------
#| live: true
topics <- dg_find_topics(q = "mobilité", n = 5)
topics[, c("name", "n_elements")]


## -----------------------------------------------------------------------------
#| live: true
mobility <- dg_find_datasets(topic = topics$id[1], n = 10)
mobility[, c("title", "organization")]


## -----------------------------------------------------------------------------
#| live: true
glimpse <- dg_glimpse("6a6be5976a05df136d48fb7a")
glimpse$quality$score             # 0..1 quality score
glimpse$metrics$views             # how often the dataset is looked at
glimpse$context$license           # e.g. "open" / "notspecified"


## -----------------------------------------------------------------------------
#| live: true
# schema_only filters client-side, so request a batch and take the first hit.
documented <- dg_find_datasets(schema_only = TRUE, n = 100)
table_id <- documented$id[!is.na(documented$id)][[1]]

# Pull it, then inspect the schema of the returned table.
tbl <- dg_pull_dataset(table_id)
schema <- dg_schema(tbl)

# Human-readable titles and descriptions of every column:
head(schema)


## -----------------------------------------------------------------------------
#| live: true
tbl <- dg_pull_dataset("6397c0ff56d3963118a18345")
head(tbl)
dg_table_id(tbl)


## -----------------------------------------------------------------------------
#| dg: dg_problems
#| error: true
try({
# In-memory demo of the problems attribute. A real pull works the same way:
#   tbl <- dg_pull_dataset("<id>")
#   dg_problems(tbl)
try({
  # A column declared "double" but holding some non-numeric cells.
  csv <- tempfile(fileext = ".csv")
  writeLines(c("x,y", "1,2", "2,oops", "3,4"), csv)
  pr <- vroom::problems(vroom::vroom(csv, col_types = vroom::cols(
    x = "d", y = "d"
  )))
  pr[, c("row", "col", "expected", "actual")]
})
})


## -----------------------------------------------------------------------------
#| live: true
# Pull the IRVE charging-points table once, inspect its parsing issues with
# dg_problems(), then re-fetch the same table with the mixed-date columns
# forced to text so nothing is flagged.
tbl <- dg_pull_dataset("5448d3e0c751df01f85d0572")
nrow(dg_problems(tbl))                    # how many mixed-date stragglers
tbl <- dg_refetch(tbl,
  col_types = c(date_mise_en_service = "character", date_maj = "character"))
dg_problems(tbl)                          # NULL — clean re-fetch


## -----------------------------------------------------------------------------
#| live: true
tbl <- dg_pull_dataset("6397c0ff56d3963118a18345")
table_id <- dg_table_id(tbl)
table_id

# Re-fetch the exact same table later:
again <- dg_refetch(tbl)


## -----------------------------------------------------------------------------
# In-memory illustration of resource drift — no network, no rdatagouv calls.
# The file you pulled on day one.
pulled_last_month <- tibble::tibble(city = c("Caen", "Lyon"), bikes = c(42L, 17L))

# The same-named file, re-uploaded by the producer the next month.
published_today <- tibble::tibble(city = c("Caen", "Lyon"), bikes = c(43L, 18L))

# A lookup by file name gives you whatever is current now (drifted):
name_based <- published_today

# A lookup by the stable id saved at pull time gives you the table you
# actually analysed. In a real session that is exactly what happens:
#   saved_id <- dg_table_id(pulled)   # a stable URI, e.g.
#   # `https://www.data.gouv.fr/datasets/<id>#<resource>`
#   back <- dg_refetch(saved_id)      # -> pulled_last_month, not published_today
id_based <- pulled_last_month


## -----------------------------------------------------------------------------
#| dg: dg_summary
#| error: true
try({
# The call is wrapped in try() as a low-level backstop: neither knitr's
# `error: true` option nor the DATAGOUV_LIVE/get() gate can contain a
# present-but-unforceable lazy-load export (the Windows/R-devel failure,
# see AGENTS.md), whereas try() degrades even that hard failure to printed
# output instead of aborting R CMD build/check.
try(dg_summary(iris, name = "iris"))
})


## -----------------------------------------------------------------------------
# In-memory tables — no network needed
#| dg: dg_summarise
#| error: true
try(dg_summarise(datasets = list(iris = iris, mtcars = mtcars)))


## -----------------------------------------------------------------------------
#| live: true
# Find a dataset, take its first id, pull it into a table and read its schema.
dg_find_datasets(q = "recharge électrique", schema_only = TRUE, n = 5) |>
  pull(id) |>
  head(1) |>
  dg_pull_dataset() |>
  dg_schema()


## -----------------------------------------------------------------------------
#| live: true
tbl <- dg_find_datasets(q = "recharge électrique", schema_only = TRUE, n = 5) |>
  pull(id) |>
  head(1) |>
  dg_pull_dataset()

# Save the stable address, then re-fetch the exact same table later.
tbl_id <- dg_table_id(tbl)
again <- dg_refetch(tbl_id)
identical(again, tbl)


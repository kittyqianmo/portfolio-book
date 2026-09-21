## -----------------------------------------------------------------------------
#| include: false
make_gt <- function(df, ...) {
  df |>
    gt::gt(...) |>
    gt::fmt_markdown() |>
    gt::opt_stylize(style = 4)
}


## -----------------------------------------------------------------------------
#| label: tbl-workflow
#| tbl-cap: "**Liste des fonctions exposées du package [{rdatagouv}](https://astamm.github.io/rdatagouv/index.html).** Chaque étape (trouver, juger, télécharger, re-télécharger) est assurée par une fonction dédiée (et quelques fonctions utilitaires)."
#| message: false
#| warning: false
#| echo: false
data.frame(
  check.names = FALSE,
  `Étape du workflow` = c(
    "**Trouver** / chercher",
    "Identifier les producteurs",
    "Identifier les thèmes",
    "**Juger** les colonnes documentées",
    "**Télécharger** une ressource",
    "Résumer le contenu",
    "**Re-télécharger** (reproducibilité)"
  ),
  `Fonction(s)` = c(
    "[`dg_find_datasets()`](https://astamm.github.io/rdatagouv/reference/dg_find_datasets.html)",
    "[`dg_find_organization()`](https://astamm.github.io/rdatagouv/reference/dg_find_organization.html)",
    "[`dg_find_topics()`](https://astamm.github.io/rdatagouv/reference/dg_find_topics.html)",
    "[`dg_schema()`](https://astamm.github.io/rdatagouv/reference/dg_schema.html)",
    "[`dg_pull_dataset()`](https://astamm.github.io/rdatagouv/reference/dg_pull_dataset.html)",
    "[`dg_summary()`](https://astamm.github.io/rdatagouv/reference/dg_summary.html), [`dg_summarise()`](https://astamm.github.io/rdatagouv/reference/dg_summarise.html)",
    "[`dg_refetch()`](https://astamm.github.io/rdatagouv/reference/dg_refetch.html)"
  )
) |>
  make_gt()


## flowchart TD
##     A["dg_find_datasets(*q*)"] -->|"formats / n_resources / has_table / has_schema"| B{"choisir un candidat"}
##     B --> C["dg_pull_dataset(id)"]
##     C --> C2["tibble avec attribut id"]
##     C2 --> D["dg_schema(tbl)"]
##     D --> D2["variables documentées (ou NULL)"]
##     C2 --> E["dg_summarise(tbl)"]
##     E --> F["tibble de métriques"]
##     C2 -. "identifiant stable (attribut)" .-> G["dg_refetch(tbl) / dg_refetch(id)"]
##     G --> H["la même table"]

## -----------------------------------------------------------------------------
#| label: tbl-entrypoints
#| tbl-cap: "**Récapitulatif des 4 points d'entrée de la plateforme [datagouv](https://www.data.gouv.fr/).**"
#| message: false
#| warning: false
#| echo: false
data.frame(
  check.names = FALSE,
  `Point d'entrée dans datagouv` = c(
    "<https://guides.data.gouv.fr/api-de-data.gouv.fr/reference>",
    "<https://www.data.gouv.fr/api/2/>",
    "<https://tabular-api.data.gouv.fr/api/doc>",
    "<https://schema.data.gouv.fr/schemas.json>"
  ),
  `Rôle dans rdatagouv` = c(
    "**Backbone** : recherche catalogue et métadonnées de découverte, téléchargement brut des fichiers.",
    "API v2 (interface uData native) : recherche `datasets/search`, `organizations/search`, `topics/search`, métadonnées riches par dataset.",
    "Service tabulaire (métadonnées par variable) — **non utilisé** par l'implémentation actuelle.",
    "Schémas de données documentés par les producteurs (champs par colonne)."
  )
) |>
  make_gt()


## -----------------------------------------------------------------------------
#| label: tbl-complementarity
#| tbl-cap: "**Complémentarité des quatre points d'entrée de la plateforme [datagouv](https://www.data.gouv.fr/).** Sur l'ensemble des tâches nécessaires au fonctionnement de [{rdatagouv}](https://astamm.github.io/rdatagouv/index.html), une unique API ne suffit pas."
#| message: false
#| warning: false
#| echo: false
data.frame(
  check.names = FALSE,
  `Tâche` = c(
    "Recherche par mots-clés du catalogue",
    "Métadonnées de découverte",
    "Infos par colonne (types, stats)",
    "Servir la table (filtre/pagination)",
    "Couverture",
    "Formats non-CSV (TSV, XLSX, JSON, ZIP)"
  ),
  `v1` = c(
    "✅",
    "✅",
    "❌",
    "fichiers bruts",
    "tous les jeux",
    "✅ (parsing propre)"
  ),
  `v2` = c(
    "✅",
    "✅ (quality, metrics)",
    "❌",
    "❌",
    "tout le catalogue",
    "n/a (découverte, pas de fichier)"
  ),
  `tabular` = c(
    "❌",
    "❌",
    "✅",
    "✅",
    "seulement indexés (404 sinon)",
    "pipeline orienté CSV"
  ),
  `schema` = c(
    "❌",
    "❌",
    "✅ (champs documentés)",
    "❌",
    "avec schéma déclaré (~5,1 %)",
    "n/a"
  )
) |>
  make_gt() |> 
  gt::tab_spanner(
    label = "API",
    columns = c(v1, v2, tabular, schema)
  ) |> 
  gt::cols_align("center")


## -----------------------------------------------------------------------------
#| message: false
#| warning: false
req_data_gouv <- function(req) {
  httr2::req_retry(
    httr2::req_error(
      httr2::req_timeout(
        # Une réponse bloquée ne doit pas geler dg_pull_dataset() indéfiniment.
        httr2::req_user_agent(
          req,
          "rdatagouv R package (https://github.com/stamm-a/rdatagouv)"
        ),
        seconds = 30
      ),
      is_error = function(resp) httr2::resp_status(resp) >= 400,
      body = function(resp) {
        tryCatch(
          httr2::resp_body_json(resp)$message,
          error = function(e) ""
        )
      }
    ),
    is_transient = function(resp) {
      httr2::resp_status(resp) %in% c(429, 500, 502, 503, 504)
    },
    retry_on_failure = TRUE,
    max_tries = 3,
    max_seconds = 8
  )
}

# La requête construite cumule bien les policies httr2
# (user-agent, timeout 30 s, erreurs ≥ 400, retry borné 429/5xx) :
req_data_gouv(httr2::request("https://www.data.gouv.fr/api/2/datasets/search/"))


## -----------------------------------------------------------------------------
#| message: false
#| warning: false
datagouv_base_url <- "https://www.data.gouv.fr/api/1/"

# Composition des URL (fetch_dataset) : $url expose l'URL finale composée.
req <- httr2::request(datagouv_base_url) |>
  httr2::req_url_path_append("datasets", "6a6be5976a05df136d48fb7a")
req$url


## -----------------------------------------------------------------------------
#| message: false
#| warning: false
# Paramètres de query simples (find_dataset) :
req <- httr2::request(datagouv_base_url) |>
  httr2::req_url_path_append("datasets", "6a6be5976a05df136d48fb7a") |>
  httr2::req_url_query(q = "velo", page_size = 50)
req$url


## -----------------------------------------------------------------------------
#| message: false
#| warning: false
# Chaque format devient son propre paramètre répété.
url_v2 <- "https://www.data.gouv.fr/api/2/datasets/search/"
rdatagouv:::append_url_params(
  url = url_v2, 
  frags = c("format=csv", "format=parquet")
)


## -----------------------------------------------------------------------------
#| message: false
#| warning: false
http_perform <- function(req) {
  httr2::req_perform(req)
}


## -----------------------------------------------------------------------------
#| message: false
#| warning: false
library(httr2)

# 1. Construire et configurer la requête via le helper central.
build_request <- function() {
  request("https://www.data.gouv.fr/api/2/datasets/search/") |>
    req_url_query(q = "velo", page_size = 2) |>
    req_user_agent("rdatagouv exemple") |>
    req_timeout(seconds = 30) |>
    req_error(
      is_error = function(resp) resp_status(resp) >= 400,
      body = function(resp) {
        tryCatch(
          httr2::resp_body_json(resp)$message,
          error = function(e) ""
        )
      }
    )
}

# 2. Une « fausse » réponse JSON (comme helper-data.R dans les tests).
build_fake_response <- function(status, json) {
  httr2::response(
    status_code = status,
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw(json)
  )
}

# 3. Exécution + parsing, transport émulé => pas de réseau, sortie déterministe.
with_mocked_responses(
  function(req) {
    build_fake_response(
      status = 200, 
      json = '{"total": 1234, "next_page": null}'
    )
  },
  resp <- http_perform(build_request())
)
cat("Statut HTTP:", resp_status(resp), "\n")
str(resp_body_json(resp))


## -----------------------------------------------------------------------------
#| message: false
#| warning: false
#| error: true
try({
with_mocked_responses(
  function(req) {
    build_fake_response(
      status = 404, 
      json = '{"message": "Ressource introuvable"}'
    )
  },
  http_perform(build_request())
)
})


## -----------------------------------------------------------------------------
#| label: tbl-api
#| tbl-cap: "**Récapitulatif de l'API du package [{rdatagouv}](https://astamm.github.io/rdatagouv/index.html).** Liste des fonctions exposées et de leur rôle."
#| message: false
#| warning: false
#| echo: false
data.frame(
  check.names = FALSE,
  Fonction = c(
    "[`dg_find_datasets()`](https://astamm.github.io/rdatagouv/reference/dg_find_datasets.html)",
    "[`dg_find_organization()`](https://astamm.github.io/rdatagouv/reference/dg_find_organization.html)",
    "[`dg_find_topics()`](https://astamm.github.io/rdatagouv/reference/dg_find_topics.html)",
    "[`dg_pull_dataset()`](https://astamm.github.io/rdatagouv/reference/dg_pull_dataset.html)",
    "[`dg_refetch()`](https://astamm.github.io/rdatagouv/reference/dg_refetch.html)",
    "[`dg_schema()`](https://astamm.github.io/rdatagouv/reference/dg_schema.html)",
    "[`dg_table_id()`](https://astamm.github.io/rdatagouv/reference/dg_table_id.html)",
    "[`dg_problems()`](https://astamm.github.io/rdatagouv/reference/dg_problems.html)",
    "[`dg_summary()`](https://astamm.github.io/rdatagouv/reference/dg_summary.html) / [`dg_summarise()`](https://astamm.github.io/rdatagouv/reference/dg_summarise.html)",
    "[`dg_glimpse()`](https://astamm.github.io/rdatagouv/reference/dg_glimpse.html)"
  ),
  Rôle = c(
    "Rechercher le catalogue (filtres serveur)",
    "Identifier les producteurs",
    "Identifier les thèmes",
    "Télécharger une ressource tabulaire",
    "Re-télécharger la même table (URI)",
    "Colonnes documentées du schéma",
    "Lire l'URI d'une table",
    "Inspecter les problèmes de parsing",
    "Résumer le contenu",
    "Métadonnées v2 d'un dataset"
  )
) |>
  make_gt()


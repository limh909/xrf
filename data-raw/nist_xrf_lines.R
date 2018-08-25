
library(tidyverse)

# Landing page: https://physics.nist.gov/PhysRefData/XrayTrans/Html/search.html
# HTML version: https://physics.nist.gov/cgi-bin/XrayTrans/search.pl?element=All&trans=KL2&trans=KL3&trans=KM3&trans=L2M4&trans=L3M4&trans=L3M5&trans=L3N5&lower=&upper=&units=eV
# curl::curl_download(
#   "https://physics.nist.gov/cgi-bin/XrayTrans/search.pl?download=tab&element=All&trans=KL2&trans=KL3&trans=KM3&trans=L2M4&trans=L3M4&trans=L3M5&trans=L3N5&lower=&upper=&units=eV",
#   "data-raw/nist_xrf_lines.tsv"
# )

nice_names <- . %>%
  str_to_lower() %>%
  str_replace_all("[^a-z0-9]+", "_") %>%
  str_remove("(^_)|(_$)")

header <- read_lines("data-raw/nist_xrf_lines.tsv", skip = 1, n_max = 1) %>%
  str_remove("^Transitions:") %>%
  str_remove("\\band\\b") %>%
  str_split(",") %>%
  first() %>%
  str_trim() %>%
  tibble(x = .) %>%
  separate(x, c("trans", "trans_siegbahn"), " ") %>%
  mutate(trans_siegbahn = str_remove_all(trans_siegbahn, "[\\(\\)]"))

energies <- read_tsv(
  "data-raw/nist_xrf_lines.tsv",
  skip = 4,
  col_types = cols(
    Ele. = col_character(),
    A = col_integer(),
    Trans. = col_character(),
    `Theory (eV)` = col_double(),
    `Unc. (eV)` = col_double(),
    `Direct (eV)` = col_double(),
    `Unc. (eV)_1` = col_double(),
    Blend = col_character(),
    Ref. = col_character()
  )
) %>%
  rename_all(nice_names) %>%
  rename(element = ele, theory_unc_ev = unc_ev, direct_unc_ev = unc_ev_1) %>%
  left_join(header, by = "trans") %>%
  select(-a) %>%
  mutate_at(vars(ends_with("_ev")), "/", 1000) %>%
  rename_at(vars(ends_with("_ev")), str_replace, "_ev$", "_kev") %>%
  # only use energies less than  the highest strength beam used in XRF (ish)
  filter(direct_kev <= 60) %>%
  mutate(element = as_factor(element)) %>%
  arrange(element, trans_siegbahn) %>%
  mutate(element = as.character(element))
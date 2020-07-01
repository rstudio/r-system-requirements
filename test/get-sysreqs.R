# Gets a JSON list of CRAN packages with SystemRequirements

db <- tools::CRAN_package_db()
sysreqs <- db[!is.na(db$SystemRequirements), c("Package", "SystemRequirements")]

sysreqs_json <- sapply(seq_len(nrow(sysreqs)), function(i) {
  package <- sysreqs[i, "Package"]
  reqs <- sysreqs[i, "SystemRequirements"]

  # Remove line breaks and escape double-quotes
  reqs <- gsub("\n", " ", reqs)
  reqs <- gsub('"', '\\\\"', reqs)

  sprintf('  {
    "Package": "%s",
    "SystemRequirements": "%s"
  }', package, reqs)
})

sysreqs_json <- c("[", paste(sysreqs_json, collapse = ",\n"), "]")

writeLines(sysreqs_json)

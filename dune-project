(lang dune 2.8)

(name stanmerge)

(generate_opam_files true)

(source
 (github herbps10/stanmerge))

(authors "Herb Susmann")

(maintainers "Herb Susmann")

(license LICENSE)

(documentation https://github.com/herbps10/stanmerge)

(package
 (name stanmerge)
 (synopsis "Merge Stan files")
 (description "Tool for block-by-block merging of Stan source files.")
 (depends ocaml dune)
 (tags
  (topics "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project

#!/usr/bin/env bash

dune build && dune exec stanmerge -- --config examples/gaussian_process/config.json > examples/gaussian_process/full_model.stan

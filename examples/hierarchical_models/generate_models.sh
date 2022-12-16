#!/usr/bin/env bash

dune exec stanmerge \
  ./common_data.stan \
  ./no_pooling.stan \
  ./data_model.stan > model_no_pooling.stan

dune exec stanmerge \
  ./common_data.stan \
  ./partial_pooling.stan \
  ./data_model.stan  > model_partial_pooling.stan

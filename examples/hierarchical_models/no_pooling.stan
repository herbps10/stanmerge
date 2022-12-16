parameters {
  vector[G] beta;
}
model {
  beta ~ normal(0, 2);
}

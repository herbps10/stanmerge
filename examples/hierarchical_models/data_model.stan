parameters {
  real<lower=0> sigma;
}
model {
  sigma ~ inv_gamma(1, 1);
  y ~ normal(beta[group], sigma);
}

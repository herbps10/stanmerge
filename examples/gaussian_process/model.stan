data {
  int<lower=1> N;
  array[N] real x;
  vector[N] y;
}
parameters {
  vector[N] mu;
  vector[N] log_sigma;
}
transformed parameters {
  vector[N] sigma = exp(log_sigma);
}
model {
  y ~ normal(mu, sigma);
}
generated quantities {
  array[N] real y_pred = normal_rng(mu, sigma);
}
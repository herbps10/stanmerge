data {
  real<lower=0> nu;
}
model {
  y ~ student_t(nu, mu, sigma);
}

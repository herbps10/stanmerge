parameters {
  real beta_mu;
  real<lower=0> beta_tau;
  vector<offset=beta_mu, multiplier=beta_tau>[G] beta;
}
model {
  beta_mu ~ std_normal();
  beta_tau ~ std_normal();
  beta ~ normal(beta_mu, beta_tau);
}

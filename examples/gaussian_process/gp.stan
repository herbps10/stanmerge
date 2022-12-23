transformed data {
  vector[N] var_zeros = rep_vector(0, N);
}
parameters {
  real<lower=0> var_rho;
  real<lower=0> var_alpha;
}
transformed parameters {
  matrix[N, N] var_K_chol;
  {
    matrix[N, N] K = gp_exp_quad_cov(x, var_alpha, var_rho);
    for(i in 1:N) {
      K[i, i] += 1e-5;
    }
      
    var_K_chol = cholesky_decompose(K);
  }
}
model {
  var_alpha ~ std_normal();
  var_rho ~ std_normal();
  var ~ multi_normal_cholesky(var_zeros, var_K_chol);
}

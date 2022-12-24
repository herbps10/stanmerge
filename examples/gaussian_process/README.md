# Gaussian Process example

## Model
Suppose we have a dataset $(x_i, y_i)$ for $i = 1, \dots, N$. We assume the following model for the outcomes $y_i$:

$$
\begin{align}
  y_i &\sim N(\mu_i, \sigma_i^2), \\
  \mu_i &= f(x_i), \\
  \log \sigma_i &= h(x_i),
\end{align}
$$

where $f$ and $h$ are unknown functions to be estimated. We place separate Gaussian Process priors on $f$ and $h$:

$$
\begin{align}
f &\sim \mathcal{GP}(0, K_f), \\
h &\sim \mathcal{GP}(0, K_h),
\end{align}
$$

where $K_f$ and $K_h$ are [squared exponential](https://www.cs.toronto.edu/~duvenaud/cookbook/) covariance functions with variance and lengthscale parameters $(\alpha_f, \rho_f)$ and $(\alpha_h, \rho_h)$, respectively. 
Each of these parameters is assigned a half-normal prior distribution.

## Stan
The benefit of using `stanmerge` in this example comes from the fact that the Gaussian Process prior is used twice. 
We can write the Gaussian Process prior once, in its own file, and then merge it twice into the final model using variable rewriting to
target the right parameters each time.

To start, `model.stan` includes the core model structure:
```stan
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
```

Note that the parameters `mu` and `log_sigma` are the ones we want to apply Gaussian Process priors to.

Next, `gp.stan` contains a generic Gaussian Process prior structure, using `var` as a generic name for the parameter of interest:
```stan
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
```

The idea is that we will include `gp.stan` twice, the first time replacing `var` with `mu` and the second time replacing `var` with `log_sigma`. 
This is expressed in `config.json`:
```
{
  "examples/gaussian_process/gp.stan": {
    "var": "mu"
  },
  "examples/gaussian_process/gp.stan": {
    "var": "log_sigma"
  },
  "examples/gaussian_process/model.stan": {}
}
```

Next we run `stanmerge` to build an output file `full_model.stan`:
```sh
dune build && dune exec stanmerge -- 
  --config examples/gaussian_process/config.json 
  > examples/gaussian_process/full_model.stan
```

which results in the following `full_model.stan` file:
```stan
data {
  int<lower=1> N;
  array[N] real x;
  vector[N] y;
}
transformed data {
  vector[N] mu_zeros = rep_vector(0, N);
  vector[N] log_sigma_zeros = rep_vector(0, N);
}
parameters {
  real<lower=0> mu_rho;
  real<lower=0> mu_alpha;
  real<lower=0> log_sigma_rho;
  real<lower=0> log_sigma_alpha;
  
  vector[N] mu;
  vector[N] log_sigma;
}
transformed parameters {
  matrix[N, N] mu_K_chol;
  {
    matrix[N, N] K = gp_exp_quad_cov(x, mu_alpha, mu_rho);
    for (i in 1 : N) {
      K[i, i] += 1e-5;
    }
    
    mu_K_chol = cholesky_decompose(K);
  }
  matrix[N, N] log_sigma_K_chol;
  {
    matrix[N, N] K = gp_exp_quad_cov(x, log_sigma_alpha, log_sigma_rho);
    for (i in 1 : N) {
      K[i, i] += 1e-5;
    }
    
    log_sigma_K_chol = cholesky_decompose(K);
  }
  
  vector[N] sigma = exp(log_sigma);
}
model {
  mu_alpha ~ std_normal();
  mu_rho ~ std_normal();
  mu ~ multi_normal_cholesky(mu_zeros, mu_K_chol);
  log_sigma_alpha ~ std_normal();
  log_sigma_rho ~ std_normal();
  log_sigma ~ multi_normal_cholesky(log_sigma_zeros, log_sigma_K_chol);
  
  y ~ normal(mu, sigma);
}
generated quantities {
  array[N] real y_pred = normal_rng(mu, sigma);
}
```

## R code
The file `analysis.R` contains R code that builds `full_model.stan` and fits the model to simulated data.

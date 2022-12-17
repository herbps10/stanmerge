# stanmerge: syntax-aware merging of Stan programs

Utility for merging multiple Stan files into one in a way that respects Stan programs. 

The intended use case is to facilitate building multiple versions of related models. One way to approach this is to build one universal model that includes flags as data inputs to enable or disable model components (this is the approach taken by the optimized models found in `rstanarm`). The alternative workflow proposed with `stanmerge` is to refactor model components into separate files, which can then be combined into multiple versions of a complete model using `stanmerge`.
 
`stanmerge` relies on the `stanc3` compiler to generate an AST for each input file. The ASTs of each of the top-level blocks (`data`, `parameters`, `model`, ...) are then concatenated to form a new merged program.

## Installation
The main dependency of this project is [`stanc3`](https://mc-stan.org/stanc3), which is included as a Git submodule inside [`lib/`](lib/). As a first step, follow the  [Getting Started](https://mc-stan.org/stanc3/stanc/getting_started.html) for `stanc3`.

Next, rune `dune build` from the top level of the `stanmerge` project.

## Usage
The `stanmerge` executable expects to be given a list of Stan files as arguments:
```
stanmerge [model_file1.stan] [model_file2.stan] ...
```
The merged file will be output to `stdout`.

If using `dune,` run:
```
dune exec stanmerge [model_file1.stan] [model_file2.stan] ...
```

## Getting Started Example

This example can be found in [`examples/location_scale`](examples/location_scale). 

Suppose we have a set of observations $\{ y_i \}$ for $i = 1, \dots, N$. We have two competing models we would like to fit to estimate the location and scale of the observations. The first is a Normal model:

$$
\begin{align}
y_i &\sim \text{N}(\mu, \sigma), \\
\mu &\sim \text{N}(0, 1), \\
\sigma &\sim \text{Inverse-Gamma}(1, 1).
\end{align}
$$

The second option uses the Student-T distribution with degrees of freedom $\nu$:

$$
\begin{align}
y_i &\sim \text{Student-$t$}(\nu, \mu, \sigma), \\
\mu &\sim \text{N}(0, 1), \\
\sigma &\sim \text{Inverse-Gamma}(1, 1).
\end{align}
$$

To translate these into Stan using `stanmerge`, first we write the parts of the Stan model that are common to both the Normal and Student-T models in `model.stan`:
```stan
data {
  int N;
  vector[N] y;
}
parameters {
  real mu;
  real<lower=0> sigma;
}
model {
  mu ~ std_normal();
  sigma ~ inv_gamma(1, 1);
}
```

Then we write the Stan code that are specific to each of the two models into separate files. For the Normal model, we have `data_model_normal.stan`:
```stan
model {
  y ~ normal(mu, sigma);
}

```
And for the Student-T model, `data_model_robust.stan`:
```stan
data {
  real<lower=0> nu;
}
model {
  y ~ student_t(nu, mu, sigma);
}
```

Next, we use `stanmerge` to merge the files into two complete Stan models. For the Normal model, we run:
```stan
$ stanmerge examples/location_scale/model.stan examples/location_scale/data_model_normal.stan
data {                 
  int N;
  vector[N] y;
}
parameters {
  real mu;
  real<lower=0> sigma;
}
model {
  mu ~ std_normal();
  sigma ~ inv_gamma(1, 1);
  
  y ~ normal(mu, sigma);
}
```

And for the robust Student-T model:
```stan
$ stanmerge examples/location_scale/model.stan examples/location_scale/data_model_robust.stan
data {                 
  int N;
  vector[N] y;
  
  real<lower=0> nu;
}
parameters {
  real mu;
  real<lower=0> sigma;
}
model {
  mu ~ std_normal();
  sigma ~ inv_gamma(1, 1);
  
  y ~ student_t(nu, mu, sigma);
}
```

## More Examples

- [examples/hierarchical_models](/examples/hierarchical_models/): estimating group means with no pooling and with partial pooling towards an overall mean. Includes R code to fit the models output by `stanmerge`.


## Todo
- Comments are currently not included in the merged output because they are not
  stored in the AST (they are stored in a separate list), and more work is
  needed to figure out how to merge multiple comment lists.
- Add option to output to file instead of `stdout`

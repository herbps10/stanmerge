# stanmerge: syntax-aware merging of Stan models

[![Release](https://img.shields.io/github/v/release/herbps10/stanmerge)](https://github.com/herbps10/stanmerge/releases/latest)

Tool for transforming and merging multiple [Stan](https://mc-stan.org/) models in a way that respects Stan model syntax.

The intended use cases are to:
- facilitate building multiple versions of related models, and 
- make it easier to reuse complex model components.
 
`stanmerge` relies on the [`stanc3`](https://mc-stan.org/stanc3) compiler to generate an AST for each input file. The ASTs of each of the top-level blocks (`data`, `parameters`, `model`, ...) are then transformed and concatenated to form a new merged program.

> [!WARNING]
> This is experimental software, and breaking changes should be expected.

## Installation

### Option 1: Pre-built Binaries

Download the latest binary for your platform from the [Releases](../../releases/latest) page:

| Platform | Download |
|----------|----------|
| Linux (x86_64) | [stanmerge-linux-x86_64](../../releases/latest/download/stanmerge-linux-x86_64) |
| macOS (Apple Silicon ) | [stanmerge-macos-arm64](../../releases/latest/download/stanmerge-macos-arm64) |

On Linux/macOS, make the binary executable after downloading:
```bash
chmod +x stanmerge-*
```

### Option 2: Build from Source

The main dependency of this project is [`stanc3`](https://mc-stan.org/stanc3), which is included as a Git submodule inside [`lib/`](lib/). As a first step, follow the  [Getting Started](https://mc-stan.org/stanc3/stanc/getting_started.html) for `stanc3`.

Then, clone this repository and build:

```bash
git clone --recursive https://github.com/herbps10/stanmerge.git
cd stanmerge
opam install . --deps-only
dune build
```

The compiled binary will be at `_build/default/bin/main.exe`.

## Quick Start

Merge two Stan files:
```bash
stanmerge model.stan data_model.stan
```
The merged program is printed to `stdout`. Redirect to a file with:
```bash
stanmerge model.stan data_model.stan > merged.stan
```

## Usage
### Basic Merging
Pass any number of Stan files as arguments:
```
stanmerge [model_file1.stan] [model_file2.stan] ...
```
The merged file will be output to `stdout`.

If building from source, you can also use `dune`:
```
dune exec stanmerge [model_file1.stan] [model_file2.stan] ...
```

### Configuration File
A JSON configuration file can be used to specify input files along with variable name transformation rules.
```bash
stanmerge --config config.json
```

#### Format
The configuration file maps Stan model filenames to an associative array of variable rename rules:
```json
{
  "model_file1.stan": {
    "var": "alpha"
  },
  "model_file2.stan": {
    "var": "beta",
  }
}
```
In this example:
1. `model_file1.stan` is included, with all instances of `var` in variable names rewritten to `alpha`
2. `model_file2.stan` is included, with all instances of `var` in variable names rewritten to `beta`

See [examples/gaussian_process](/examples/gaussian_process/) for an example that uses variable name rewriting.

## Example: Location-Scale Models

*Full example in [`examples/location_scale`](examples/location_scale).* 

Suppose we have a set of observations $\{ y_i \}$ for $i = 1, \dots, N$ and two competing models for estimating their location and scale.

**Normal model:**

$$
\begin{align}
y_i &\sim \text{N}(\mu, \sigma), \\
\mu &\sim \text{N}(0, 1), \\
\sigma &\sim \text{Inverse-Gamma}(1, 1).
\end{align}
$$


**Student-T model:**

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

- [examples/hierarchical_models](/examples/hierarchical_models/): estimating group means with no pooling and with partial pooling. Includes R code.
- [examples/gaussian_process](/examples/gaussian_process/): using Gaussian Processes to estimate the mean and scale of a dataset. Provides an example of variable name rewriting. Includes R code.

## Limitations
- **Comments not preserved** in merged output. Comments are stored separately from the AST, and merging multiple comment lists is not yet supported.
- **Output is to `stdout` only.** Use shell redirection (`> output.stan`) to write to a file.

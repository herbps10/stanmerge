data {
  int<lower=0> N;
  int<lower=0> G;

  vector[N] y; 
  array[N] int<lower=1, upper=G> group; 
}

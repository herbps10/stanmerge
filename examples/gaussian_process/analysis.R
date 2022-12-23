library(tidyverse)
library(tidybayes)

simulate_data <- function(N) {
  index = 1:N
  x <- runif(N, 0, 1)
  
  mu <- x^2
  sigma <- exp(2 * x^2 - 2.5)
  y <- rnorm(N, mu, sigma)
  
  tibble(index, x, mu, sigma, y)
}

set.seed(2458)
data <- simulate_data(50)

ggplot(data, aes(x = x, y = y)) + geom_point()

#
# Build and fit model
#
model <- cmdstanr::cmdstan_model("full_model.stan")
fit <- model$sample(
  data = list(
    N = nrow(data),
    x = data$x,
    y = data$y
  ),
  parallel_chains = 4,
  iter_warmup = 500,
  iter_sampling = 1000,
  max_treedepth = 13
)

post <- fit %>% spread_draws(mu[i], log_sigma[i], y_pred[i]) %>%
  median_qi(.width = c(0.5, 0.8, 0.95)) %>%
  left_join(select(data, index, x), by = c(i = "index"))  %>%
  arrange(x)

# Plot mu
post %>%
  ggplot(aes(x = x, y = mu)) +
  geom_lineribbon(aes(ymin = mu.lower, ymax = mu.upper)) +
  geom_function(fun = function(x) x^2) +
  scale_fill_brewer()

# Plot log(sigma)
post %>%
  ggplot(aes(x = x, y = log_sigma)) +
  geom_lineribbon(aes(ymin = log_sigma.lower, ymax = log_sigma.upper)) +
  geom_function(fun = function(x) 2 * x^2 - 2.5) +
  scale_fill_brewer()

# Plot posterior predictive
post %>%
  ggplot(aes(x = x, y = y_pred)) +
  geom_lineribbon(aes(ymin = y_pred.lower, ymax = y_pred.upper)) +
  geom_point(data = data, aes(x, y)) +
  scale_fill_brewer()

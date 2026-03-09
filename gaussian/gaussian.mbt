///|
/// GaussianField: confidence/salience with uncertainty for scheduling (§3.3).
/// Represents expected relevance (mu) and uncertainty (sigma).
pub(all) struct GaussianField {
  mu : Double // expected relevance / priority
  sigma : Double // uncertainty / volatility
} derive(Eq, Show)

///|
/// Create a new GaussianField with default uninformative prior.
pub fn GaussianField::new() -> GaussianField {
  { mu: 0.0, sigma: 1.0 }
}

///|
/// Create a GaussianField with specific values.
pub fn GaussianField::of(mu : Double, sigma : Double) -> GaussianField {
  { mu, sigma }
}

///|
/// Scheduling decision: should expensive work be executed?
/// Policy-driven: require mu - k*sigma >= threshold.
pub fn GaussianField::should_execute(
  self : GaussianField,
  k : Double,
  threshold : Double,
) -> Bool {
  self.mu - k * self.sigma >= threshold
}

///|
/// Update the field with a new observation using simple online mean+variance.
/// Uses Welford's running formula for numerical stability.
/// `n` is the observation count BEFORE this update (0 for first observation).
pub fn GaussianField::update(
  self : GaussianField,
  observation : Double,
  n : Int,
) -> GaussianField {
  let count = n + 1
  let delta = observation - self.mu
  let new_mu = self.mu + delta / count.to_double()
  let new_sigma = if count < 2 {
    self.sigma // keep initial sigma until we have enough data
  } else {
    // simple exponential moving estimate of standard deviation
    let alpha = 1.0 / count.to_double()
    let diff = if observation > new_mu {
      observation - new_mu
    } else {
      new_mu - observation
    }
    self.sigma * (1.0 - alpha) + diff * alpha
  }
  { mu: new_mu, sigma: new_sigma }
}

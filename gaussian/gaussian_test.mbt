///|
test "GaussianField should_execute" {
  let g = @gaussian.GaussianField::of(5.0, 1.0)
  // mu=5, sigma=1, k=1 => 5-1=4 >= 3 => true
  assert_true(g.should_execute(1.0, 3.0))
  // mu=5, sigma=1, k=1 => 5-1=4 >= 5 => false
  assert_true(not(g.should_execute(1.0, 5.0)))
}

///|
test "GaussianField default" {
  let g = @gaussian.GaussianField::new()
  assert_eq(g.mu, 0.0)
  assert_eq(g.sigma, 1.0)
}

///|
test "GaussianField update shifts mu" {
  let g = @gaussian.GaussianField::new()
  let g2 = g.update(10.0, 0) // first observation: mu should shift toward 10
  assert_true(g2.mu > 0.0)
}

///|
test "GaussianField update boundary n=0" {
  let g = @gaussian.GaussianField::new() // mu: 0.0, sigma: 1.0
  let g2 = g.update(10.0, 0) // first observation
  assert_eq(g2.mu, 10.0)
  assert_eq(g2.sigma, 1.0) // sigma should remain unchanged when count < 2
}

///|
test "GaussianField update boundary n=1" {
  let g = @gaussian.GaussianField::of(10.0, 1.0)
  let g2 = g.update(20.0, 1) // second observation
  assert_eq(g2.mu, 15.0) // 10.0 + (20.0 - 10.0) / 2.0
  assert_eq(g2.sigma, 3.0) // 1.0 * 0.5 + 5.0 * 0.5
}

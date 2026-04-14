///|
test "GaussianField should_execute" {
  let g = @gaussian.GaussianField::of(5.0, 1.0)
  // mu=5, sigma=1, k=1 => 5-1=4 >= 3 => true
  assert_true(g.should_execute(1.0, 3.0))
  // mu=5, sigma=1, k=1 => 5-1=4 >= 5 => false
  assert_true(!g.should_execute(1.0, 5.0))
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

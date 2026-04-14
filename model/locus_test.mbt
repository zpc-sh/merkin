test "is_valid_locus_name" {
  assert_true!(is_valid_locus_name("valid-name_123"))
  assert_false!(is_valid_locus_name("invalid;name"))
  assert_false!(is_valid_locus_name("invalid name"))
  assert_false!(is_valid_locus_name("locus\$(id)"))
  assert_false!(is_valid_locus_name(""))
  assert_true!(is_valid_locus_name("A-B_c"))
}

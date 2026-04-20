///|
fn string_contains(haystack : String, needle : String) -> Bool {
  if needle == "" {
    return true
  }
  if needle.length() > haystack.length() {
    return false
  }
  let last = haystack.length() - needle.length()
  let mut i = 0
  while i <= last {
    let mut matched = true
    let mut j = 0
    while j < needle.length() {
      if haystack[i + j] != needle[j] {
        matched = false
        break
      }
      j = j + 1
    }
    if matched {
      return true
    }
    i = i + 1
  }
  false
}

///|
test "triad package emits contract with typed input" {
  @triad.seed_sparse_tree([["alpha", "doc"], ["beta", "doc"]], true)

  let pins = @triad.TriadRepoPins::new(
    "merkin-head", "mu-head", "lang-head", "main", "main", "main",
  )
  let input = @triad.TriadContractInput::new(
    ["alpha"],
    ["mu:abc", "lang:def"],
    @triad.abi_expected_exports(),
    "2026-04-14T12:00:00Z",
    "v0.1",
    pins,
  )
  let contract = @triad.emit_contract(input)

  assert_true(string_contains(contract, "\"kind\": \"merkin.triad.contract\""))
  assert_true(string_contains(contract, "\"status\": \"ok\""))
  assert_true(string_contains(contract, "\"refs_byte_clean\": true"))
}

///|
test "triad package ABI helper reports missing exports" {
  assert_eq(@triad.abi_status(@triad.abi_expected_exports()), "ok")
  assert_eq(
    @triad.abi_status(["plan_finger_wasm"]),
    "missing:plan_drift_commitment,triad_contract_wasm",
  )
}

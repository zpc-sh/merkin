## 2024-05-18 - String concatenation in loops
**Learning:** O(n^2) string concatenation (`+`) inside loops is a major performance bottleneck in MoonBit, leading to excessive allocations.
**Action:** Use `StringBuilder::new(size_hint=...)` for string building in loops. Do not use `@builtin.` prefix.

## 2024-05-18 - String optimization complete
**Learning:** Found string builders natively available via `StringBuilder::new()` without `@builtin` prefix, and native string slicing (e.g., `url[0:5].to_string()`) which replace expensive O(n^2) allocations.
**Action:** When manipulating strings in loops, always use `StringBuilder` or slice native syntax if substrings are needed.

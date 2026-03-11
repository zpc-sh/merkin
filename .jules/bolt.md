## 2024-05-24 - String Concatenation Performance
**Learning:** String concatenation using the `+` operator inside a loop has O(n²) time complexity because it allocates a new string object in each iteration.
**Action:** Always use `StringBuilder` (e.g. `StringBuilder::new()`) when building strings dynamically within loops to ensure O(n) performance. Alternatively, use native functions like `String::join` if available.

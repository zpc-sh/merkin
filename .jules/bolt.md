## 2024-03-15 - [MoonBit O(N²) String Concatenation Loop Anti-Pattern]
**Learning:** In MoonBit, doing `out = out + items[i]` inside a loop is an O(N²) anti-pattern that creates excessive intermediate string allocations and scales poorly.
**Action:** Use `StringBuilder::new()` to accumulate strings within a loop to achieve O(N) performance, especially for string `join` operations and other large building routines.

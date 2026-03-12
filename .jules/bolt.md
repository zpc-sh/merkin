## 2024-11-20 - Substring removal

**Learning:** In MoonBit, avoid using a loop with string concatenation (`+`) to remove a trailing character as it causes O(n^2) time complexity. `StringBuilder` works, but string slicing (`url[:url.length() - 1].to_string()`) is even cleaner and optimal.
**Action:** Use string slicing (`str[:].to_string()`) to manipulate substrings optimally.

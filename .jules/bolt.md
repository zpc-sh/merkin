## 2024-03-10 - Optimizing String Concatenation in Moonbit
**Learning:** Moonbit does not currently have a built-in `String::join` or `String::concat` for string arrays. The pattern of `out = out + items[i]` creates many intermediate strings and runs in O(N^2) time.
**Action:** Use `StringBuilder::new()` and `builder.write_string()` which runs in O(N) time for concatenating strings in loops in Moonbit.

## 2024-05-15 - Optimizing string_to_bytes
**Learning:** For performant UCS-4 string to bytes conversion, pre-allocate a `FixedArray` using `s.length() * 4` as an upper bound rather than using a double-loop. Handle surrogate pair over-allocation by checking if the final `pos < buf.length()` and copying the used portion into an exact-sized `FixedArray` before converting to `Bytes`. Also, manual bitwise masking (e.g., `& 0xFFU`) is unnecessary as `.to_byte()` inherently truncates to the lowest 8 bits.
**Action:** Always avoid iterating twice over a string just to compute required byte size if a fast upper bound approximation (like `s.length() * 4`) can be used and safely resized. Omit manual masking for `UInt` to `Byte` conversion.

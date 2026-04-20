# Testing and Benchmarking Framework

This repository now has two test layers:

- Package behavior tests in each package (`*_test.mbt` in `hash/`, `model/`, `store/`, `tree/`, etc.)
- Spec conformance tests in `conformance/`

## Conformance Profiles

`conformance/core_profile_test.mbt` validates implemented core invariants:
- canonical hash key format and digest width
- artifact hash verification determinism
- envelope encoding and subject-hash preference
- sealed-envelope immutability guard
- work-promise identity sensitivity to policy id
- anchor lifecycle metadata persistence
- store round-trips by id
- ingest/seal epoch progression

`conformance/optional_profiles_test.mbt` contains explicitly skipped placeholders for optional profiles that are not yet implemented in this repo:
- Semantic
- Proof
- Batch
- Offload

## Benchmark Suite

Benchmarks are defined in `conformance/conformance_bench_test.mbt` and run with MoonBit's bench runtime.

Included benchmarks:
- `hash.of_bytes.1k`
- `tree.ingest.flat`
- `tree.seal.128`
- `store.artifact.put_get`

## Commands

From module root:

```bash
moon test
moon bench -p zpc/merkin/conformance
moon bench
```

Recommended CI gating for now:
- Required: `moon test`
- Informational: `moon bench -p zpc/merkin/conformance`

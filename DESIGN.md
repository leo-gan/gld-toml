# TOML 1.1 serializer for Mojo (`mojo-toml`)

| Field | Value |
| --- | --- |
| **Author** | Leonid Ganeline |
| **Date** | 2026-09-30 |
| **Status** | Implemented |
| **License** | MIT, Copyright (c) 2026 Leonid Ganeline |
| **Mojo** | 1.1.0 |
| **Spec** | TOML 1.1.0 and toml-test v2.2.0 |

## Overview

`gld-toml` is a standalone Mojo library that encodes and decodes TOML 1.1.
The runtime does not link a C, C++, or Rust TOML library. Callers can use a
dynamic `TomlDoc` or generate structs from a JSON Schema subset.

## Decisions

1. The implementation is from-scratch Mojo. Python `tomllib` is an oracle for TOML 1.0 only.
2. The spec target is TOML 1.1.0, checked against the vendored toml-test 1.1 file list.
3. Both `TomlDoc` and `gld-tomlgen-mojo` ship in v1.
4. Integers that fit in Int64 are Int64. Larger integers are a decode error.
5. Floats are Float64, including inf, nan, and signed zero.
6. Offset datetime, local datetime, local date, and local time are `TomlDateTime` values. Fractional seconds are truncated to nanoseconds.
7. TOML has no null. Optional schema fields are `Optional[T]`.
8. Duplicate keys and table/array conflicts are errors.
9. A leading UTF-8 BOM is rejected.
10. The value tree is an arena of nodes and edges. The parser is one recursive descent.
11. Nesting of inline tables and arrays stops at 128.
12. Default encode uses `[table]` and `[[array of tables]]`, with scalar keys first so the text stays valid. `EncodeOptions.inline_tables` and `EncodeOptions.compact_arrays` change that layout. Comments are not round-tripped.
13. The schema subset matches the sibling JSON Schema subset, plus `datetime`, `datetime-local`, `date-local`, `time-local`, `x-toml-inline`, and `x-toml-compact`.
14. Unknown schema keywords are `KIND_SCHEMA`. Unknown instance keys are skipped on a normal object and rejected when choosing a union branch.
15. A required recursive field is a codegen error. An optional recursive field is emitted as `Optional[Box[T]]`. Mojo 1.1 still rejects compiling a struct that names itself; `tests/test_schema.mojo` checks the emitted source.
16. Package `mojo-toml`, import `toml`, CLI `gld-tomlgen-mojo`. Version starts at 0.1.0. One later bump publishes to prefix.dev.
17. `.env` and `temp/` are gitignored.
18. CI job names are `Mojo tests` and `Docs build`. Pages use Material for MkDocs. The channel is `https://prefix.dev/leo-gan/leo-gan`.
19. The microbench is local. There is no serializer-benchmark client.

## Layers

`wire` parses and writes. `runtime` holds errors, options, `Box`, and `TomlDatum`. `schema` reads the JSON Schema subset. `codegen` emits structs. `toml` re-exports the public names.

Precompile order: `wire`, `runtime`, `schema`, `toml`. The CLI is a separate binary.

## PR Plan

The library landed as the initial implementation. A follow-up bump moves `0.1.0` to `0.2.0` and publishes the conda package. Repo creation, branch protection, and the Pages site are rollout steps, not extra behavior.

| PR | Title | What it contains |
| --- | --- | --- |
| Library | TOML 1.1 parser, encoder, schema, codegen, tests, docs, CI | This tree at 0.1.0 |
| Publish | Bump version to 0.2.0 | `pixi.toml` and `conda.recipe/recipe.yaml` only |

## Open questions

None.

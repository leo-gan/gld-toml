# Test data

The files under `testdata/` are ordinary inputs for the unit tests and the
compliance suite. They are not a product schema.

## `testdata/toml-test/`

This tree is a copy of the files listed in toml-test v2.2.0
`tests/files-toml-1.1.0`. Valid cases are a `.toml` file and a `.json` file.
The JSON uses the tagged form `{"type": "...", "value": "..."}` for scalars.
Invalid cases are a `.toml` file that must be rejected.

`tests/test_suite.mojo` reads `files-toml-1.1.0` and checks both directions
for every `.toml` line. The list also names the `.json` siblings; the test
skips those lines because they are expectations, not TOML.

TOML 1.1 cases are in this tree because Python `tomllib` implements TOML 1.0
and rejects some 1.1 documents that are legal here.

## `testdata/schema/`

JSON Schema files for the code generator.

| File | What it defines |
| --- | --- |
| `benchmark_v2.json` | `Message`, `Document`, `Telemetry`, `Strings`, and `Event` |
| `longlist.json` | `LongList`, an optional self-reference |
| `union.json` | `Pet` as `Cat` or `Dog` |
| `when.json` | `When`, with an offset datetime |

`benchmark_v2.json` uses the same record shapes as the other Mojo serializers
in this family. The shapes are copied here so this repository does not depend
on another project.

## `testdata/golden/`

Small TOML 1.0 documents written by `scripts/gen_golden.py`. The script loads
each document with `tomllib` before writing it, so the bytes are texts that
the standard library accepts.

## `testdata/invalid-schema/`

`reject.json` is a schema that uses `minimum`. That keyword is outside the
subset, and `tests/test_schema.mojo` expects `KIND_SCHEMA`. The generator does
not read this directory.

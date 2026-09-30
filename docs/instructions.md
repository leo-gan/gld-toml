# Instructions

These steps install the library, decode a document, and generate Mojo from a
JSON Schema.

## Install the published package

The linux-64 package is `mojo-toml` on
[prefix.dev/leo-gan/leo-gan](https://prefix.dev/leo-gan/leo-gan).

```bash
pixi add --channel https://prefix.dev/leo-gan/leo-gan mojo-toml
```

That installs `toml.mojoc` together with `wire`, `runtime`, and `schema`, and
the `gld-tomlgen-mojo` command. It needs `mojo-compiler` 1.1.

## Build from a git checkout

```bash
git clone https://github.com/leo-gan/gld-toml.git
cd gld-toml
pixi install
pixi run test
```

If `pixi install` returns 401 on `conda.modular.com`, put `PREFIX_API_KEY` in
a local `.env` file and run `scripts/ci-setup.sh`. That file is gitignored.

Requires Mojo 1.1.0.

## Decode a document

```bash
pixi run mojo run -I src examples/encode_value.mojo
```

`decode_toml` returns a `TomlDoc`. The root is always a table. `encode_toml`
writes it back as text. The default layout uses standard table headers.

## Generate Mojo

Write a JSON Schema file. The accepted keywords are `type`, `properties`,
`required`, `items`, `$ref`, `$defs`, `definitions`, `enum`, `const`, `oneOf`,
`anyOf`, `$id`, `title`, `description`, and `$schema`. Two TOML extras are
`x-toml-inline` and `x-toml-compact`. Datetime fields use `"type": "datetime"`,
`"datetime-local"`, `"date-local"`, or `"time-local"`.

```bash
pixi run mojo run -I src src/codegen/cli.mojo -- \
  --schema testdata/schema/benchmark_v2.json \
  --out tests/generated
```

The installed command is the same tool:

```bash
gld-tomlgen-mojo --schema schema.json --out out/
```

A property that is not required becomes `Optional[T]`. A required field whose
type refers back to the same struct is rejected. An optional self-reference is
emitted as `Optional[Box[T]]`. Mojo 1.1 still refuses to compile a struct that
names itself, so that form is what the generator writes and what
`tests/test_schema.mojo` checks in the source.

## Tests

```bash
pixi run test
pixi run check-generated
pixi run precompile
```

`tests/test_suite.mojo` walks the vendored toml-test 1.1 files. Invalid files
must fail. Valid files must match the expected JSON, and encoding them must
decode to the same values. `conformance/run.sh` runs the official `toml-test`
binary when it is on `PATH`, and exits 0 when it is not.

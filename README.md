# mojo-toml

A from-scratch [TOML 1.1](https://toml.io/en/v1.1.0) implementation for
[Mojo](https://mojolang.org/). The runtime and the code generator are written
in Mojo. They do not wrap, link, or vendor tomli, toml-rs, BurntSushi/toml,
go-toml, or any other C, C++, or Rust TOML library.

Python `tomllib` is a **test oracle** for documents that are valid TOML 1.0.
It is not required to encode or decode at runtime. TOML 1.1 compliance uses
the vendored [toml-test](https://github.com/toml-lang/toml-test) v2.2.0 files.

This repository is a standalone library. It is not part of any other project.

Documentation: [leo-gan.github.io/gld-toml](https://leo-gan.github.io/gld-toml/).
That site has a TOML overview, the install steps, examples, encode and decode
notes, and test-data notes.

## Install

Published package (linux-64) on [prefix.dev/leo-gan/leo-gan](https://prefix.dev/leo-gan/leo-gan):

```bash
pixi add --channel https://prefix.dev/leo-gan/leo-gan mojo-toml
```

That installs `toml.mojoc` (plus `wire`, `runtime`, and `schema`) and
`gld-tomlgen-mojo`. It needs `mojo-compiler` 1.1.

From a git checkout:

```bash
git clone https://github.com/leo-gan/gld-toml.git
cd gld-toml
pixi install
pixi run test
```

If `pixi install` fails with 401 on `conda.modular.com`, set `PREFIX_API_KEY`
in a local `.env` (never commit that file) and run `scripts/ci-setup.sh`.

## Layout

```text
src/wire/       # parser, writer, TomlDoc arena
src/runtime/    # DecodeError, EncodeOptions, TomlDatum, Box
src/schema/     # JSON Schema subset
src/codegen/    # gld-tomlgen-mojo
src/toml/       # public facade (`from toml import …`)
```

## Develop

```bash
pixi run test
pixi run generate
pixi run precompile
```

Requires **Mojo 1.1.0**.

## License

MIT. Copyright (c) 2026 Leonid Ganeline.

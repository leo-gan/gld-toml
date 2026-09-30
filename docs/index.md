# mojo-toml

mojo-toml is a [TOML 1.1](https://toml.io/en/v1.1.0) serializer written in
[Mojo](https://www.modular.com/mojo). The runtime and the code generator are
Mojo. They do not wrap tomli, toml-rs, or any other C, C++, or Rust TOML
library.

<div class="grid cards" markdown="1">

-   __Why TOML__

    ---

    What a TOML document is, which types it has, and how tables, arrays of
    tables, and inline tables fit together.

    [:octicons-arrow-right-24: Read Why TOML](why-toml.md)

-   __Instructions__

    ---

    Install Mojo 1.1.0 with pixi, decode a document, generate Mojo from a
    JSON Schema, and run the tests.

    [:octicons-arrow-right-24: Open Instructions](instructions.md)

-   __Examples__

    ---

    Encode and decode a dynamic `TomlValue` and a generated struct.

    [:octicons-arrow-right-24: See Examples](examples.md)

-   __Techniques__

    ---

    How this library stores a document, why keys stay in order, and what the
    local microbench measures.

    [:octicons-arrow-right-24: Read Techniques](techniques.md)

-   __Test data__

    ---

    What lives under `testdata/` and which oracle each tree uses.

    [:octicons-arrow-right-24: Read Test data](test-data.md)

</div>

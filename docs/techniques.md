# Techniques

This page describes the code that ships. Each section names the problem, the
method this library uses, and the trade-off.

The timed paths are a generated `Message` and a small dynamic document. The
numbers below come from `benches/microbench.mojo` on one machine, 4000
iterations after a short warmup. They are a local compile-test loop. They are
not a ranking against serializers in other languages.

On that run, generated encode was about 3479 ns and generated decode about
5273 ns for a 120-byte `Message`. Dynamic decode of a three-key document was
about 2772 ns, and dynamic encode of that value was about 920 ns.

## One arena

`TomlDoc` is a list of nodes plus a list of edges. A table or array does not
own a separate child allocation for each value. The edge list records document
order.

**Problem.** A pointer tree of Mojo structs that contain `List[Self]` is hard
to form, and it scatters small allocations through the parse.

**What we do.** The parser appends nodes and links them. Lookup of a key walks
that table's edges. TOML tables in real files are small, so the walk stays short.

**Trade-off.** A huge table is a linear scan. The library does not build a hash
map.

## One pass

The parser is a recursive descent over the byte span. It builds the arena as
it reads. It does not keep a second event list.

**Problem.** A two-step parse copies every string twice and keeps the grammar
in two places.

**Trade-off.** The table-conflict rules (dotted keys, headers, and inline
tables) live in the same pass as the scanner. That function is long. The
toml-test files are the check that the rules match the spec.

## Depth cap

Nested arrays and inline tables stop at 128 levels.

**Problem.** A short file of the form `[[[[[[[[[[ ... ]]]]]]]]]]` can use a
lot of stack.

**Trade-off.** A document deeper than 128 levels is rejected. Real
configuration files are far shallower.

## Encode builds a second walk

`encode_toml` walks the arena and writes bytes into a `List[Byte]`. Generated
`encode_to` first fills an arena from the struct, then calls the same writer.

**Problem.** Writing straight into the output from the struct avoids the
arena. It also duplicates the header and inline-table rules.

**What we do.** One writer owns layout. Generated code only records values.
The microbench measures that path, including the arena fill.

**Trade-off.** The generated encode pays for a tree it throws away. The layout
stays consistent with `TomlDoc`.

## Key order and headers

Scalar keys of a table are written in definition order. Subtables are then
written as `[header]` blocks, also in definition order. An array of tables
becomes `[[header]]` unless `EncodeOptions.compact_arrays` is set.

**Problem.** A `[header]` ends the parent table in the TOML grammar. Emitting
a subtable between two scalar keys of the parent would make the later scalar
a child of the subtable.

**Trade-off.** The encoding is stable and legal. It does not preserve the
original mix of dotted keys, quotes, and comments.

## Integers and floats

Integers are accumulated in a `UInt64` with an overflow check against the
Int64 range. Floats are handed to `Float64` after underscores are removed.
`inf` and `nan` use the IEEE bit patterns directly.

**Trade-off.** The float text is whatever Mojo prints. toml-test compares
floats numerically, so that text is accepted when it is the same value.

## Compliance adapter

`conformance/decoder.mojo` prints the tagged JSON that toml-test expects.
Datetimes are printed in a canonical RFC 3339 form with seconds included.
The official tool compares datetimes and floats by value, and strings and
integers as text. `tests/test_suite.mojo` does the same comparison without
requiring the Go binary.

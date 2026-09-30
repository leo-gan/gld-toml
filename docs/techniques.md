# Techniques

This page describes the code that ships. Each section names the problem, the
method this library uses, and the trade-off.

The timed paths are a generated `Message` and a small dynamic document. The
numbers below come from `benches/microbench.mojo` on one machine, 4000
iterations after a short warmup. They are a local compile-test loop. They are
not a ranking against serializers in other languages.

On that run, after the encode path stopped building a temporary tree, a
120-byte `Message` encoded in about 760 ns and decoded in about 730 ns.
Before that change the same bench was about 3480 ns to encode and 5270 ns
to decode. A three-key dynamic document encoded in about 550 ns and decoded
in about 2000 ns; the earlier numbers were about 920 ns and 2770 ns. The
slower of two back-to-back runs is the one quoted here.

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

## Encode writes bytes directly

`encode_toml` walks the arena and appends bytes. Integers are written as
digits into that buffer. Generated `encode_to` does not build an arena first.
It writes the known keys itself. `encoded_len` is that same write, then the
length of the buffer.

**Problem.** The first generator filled a `TomlDoc` and then serialized it.
Every field paid for a node, a key string, and an edge, and the bytes were
copied again into the returned `String`.

**Trade-off.** The struct writer and the arena writer must agree on header
layout. `tests/test_generated.mojo` checks the struct path. The arena writer
still serves `TomlDoc`, including documents that have no schema.

A flat generated struct also decodes without an arena. `read_text` scans
`key = value` lines. A `[` or `{` in the text falls back to the full parser,
so nested tables still work. Structs that contain tables or arrays always use
the full parser.

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

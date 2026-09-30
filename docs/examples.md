# Examples

## A dynamic document

`examples/encode_value.mojo` builds nothing by hand. It decodes a short
document and encodes it again.

```mojo
from toml import decode_toml, encode_toml

def main() raises:
    var doc = decode_toml(String("name = \"Tom\"\nage = 42\n"))
    print(encode_toml(doc), end="")
```

The printed text is a TOML document. Key order follows the order the keys were
defined. Nested tables become `[header]` blocks after the scalar keys of
their parent.

## Inline tables and compact arrays

```mojo
from runtime.options import EncodeOptions
from toml import decode_toml, encode_toml

def main() raises:
    var doc = decode_toml(String("[point]\nx = 1\ny = 2\n"))
    print(encode_toml(doc, EncodeOptions(True, False)))
```

`EncodeOptions(True, False)` writes tables as inline tables.
`EncodeOptions(False, True)` writes an array of tables as one array of inline
tables. Scalar arrays are one line in every mode.

## A generated struct

`testdata/schema/benchmark_v2.json` is the schema for `Message`. After
`pixi run generate`:

```mojo
from Message import Message
from runtime.datum import decode_text, encode_text

def main() raises:
    var m = Message()
    m.f_bool = True
    m.f_int32 = Int64(42)
    m.f_string = String("hi")
    var back = decode_text[Message](encode_text(m))
    print(back.f_int32)
```

`Document` in the same schema has a nested `meta` table and an `items` array
of tables. The encoder writes those as `[meta]` and `[[items]]`.

# Why TOML

TOML is a configuration language. A file is one table. Keys are strings.
Values are strings, integers, floats, booleans, datetimes, arrays, or nested
tables. Comments start with `#` and do not change the table.

This library implements [TOML 1.1.0](https://toml.io/en/v1.1.0). That release
keeps the 1.0 types and adds three pieces of syntax:

| Addition | Example |
| --- | --- |
| Newlines and a trailing comma inside an inline table | `point = { x = 1, y = 2, }` |
| `\e` and `\xHH` in basic strings | `"\e[31m"` and `"\x61"` |
| Optional seconds on a time | `1979-05-27T07:32Z` and `07:32` |

## Types

TOML has no null. A key is either present or absent. In generated structs, a
property that is not in `required` is `Optional[T]`. A missing key is `None`.

Integers are signed 64-bit values. A number that does not fit, including a
hexadecimal or binary literal, is a decode error. Floats are IEEE-754 binary64,
including `inf`, `-inf`, `nan`, and `-0.0`. `+nan` and `-nan` are accepted and
stored as a quiet NaN.

Datetimes are four distinct kinds, not strings:

| Kind | Example |
| --- | --- |
| Offset datetime | `1979-05-27T07:32:00Z` |
| Local datetime | `1979-05-27T07:32:00` |
| Local date | `1979-05-27` |
| Local time | `07:32:00` |

Fractional seconds are kept up to nanoseconds. Extra digits are truncated, not
rounded. A space may separate the date and the time. `T` and `t`, and `Z` and
`z`, are both accepted.

## Tables

A header such as `[fruit.apple]` creates the tables along that path. Dotted
keys such as `fruit.apple.color = "red"` create the same shape. Defining the
same key twice is an error. An inline table is closed: keys cannot be added
to it later in the file.

An array of tables uses a double bracket:

```toml
[[product]]
name = "Hammer"

[[product]]
name = "Nail"
```

That value is an array of two tables. A later dotted key or header refers to
the most recently opened element.

The encoder's default style writes `[table]` headers and `[[array]]` headers.
`EncodeOptions` can ask for inline tables and for arrays of tables written as
`[ { ... }, { ... } ]`. Comments are accepted on input and are not written
back out.

from std.collections import List, Optional

from runtime.box import Box
from runtime.datum import TomlDatum
from runtime.error import DecodeError
from runtime.options import EncodeOptions
from wire.doc import (
    TK_ARRAY,
    TK_DATETIME,
    TK_FALSE,
    TK_FLOAT,
    TK_INT,
    TK_STRING,
    TK_TABLE,
    TK_TRUE,
    TomlDateTime,
    TomlDoc,
)
from wire.flat import parse_f64, parse_i64, parse_toml_str, span_is
from wire.reader import decode_toml
from wire.writer import append_ascii, append_bool, append_datetime, append_float, append_int, append_toml_str

struct Telemetry(Copyable, Movable, Defaultable, Deinitable, TomlDatum):
    var values: List[Float64]

    def __init__(out self):
        self.values = List[Float64]()

    def encoded_len(self, options: EncodeOptions) raises -> Int:
        var buf = List[Byte]()
        self.encode_to(buf, options)
        return len(buf)

    def encode_to(self, mut buf: List[Byte], options: EncodeOptions) raises:
        var start = len(buf)
        self._write(buf, options, True, String(), False)
        if len(buf) == start or Int(buf[len(buf) - 1]) != 10:
            buf.append(Byte(10))

    def _write(self, mut buf: List[Byte], options: EncodeOptions, root: Bool, prefix: String, inline: Bool) raises:
        if inline or ((not root) and options.inline_tables):
            self._write_inline(buf, options)
            return
        _ = prefix
        append_ascii(buf, "values")
        append_ascii(buf, " = [")
        var _i0 = 0
        while _i0 < len(self.values):
            if _i0 > 0:
                append_ascii(buf, ", ")
            append_float(buf, self.values[_i0])
            _i0 += 1
        append_ascii(buf, "]\n")

    def _write_inline(self, mut buf: List[Byte], options: EncodeOptions) raises:
        buf.append(Byte(123))
        var _first = True
        if not _first:
            append_ascii(buf, ", ")
        _first = False
        append_ascii(buf, "values")
        append_ascii(buf, " = ")
        buf.append(Byte(91))
        var _i = 0
        while _i < len(self.values):
            if _i > 0:
                append_ascii(buf, ", ")
            append_float(buf, self.values[_i])
            _i += 1
        buf.append(Byte(93))
        buf.append(Byte(125))

    def read_text(mut self, text: String) raises DecodeError:
        var doc = decode_toml(text)
        self.read_from(doc, doc.root)

    def read_from(mut self, doc: TomlDoc, node: Int) raises DecodeError:
        if doc.kind(node) != TK_TABLE:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        var _n0 = doc.find_key(node, "values")
        if _n0 < 0:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        self.values = List[Float64]()
        var _e = doc.first_edge(_n0)
        while _e >= 0:
            var _c = doc.edges[_e].child
            self.values.append(doc.float_at(_c))
            _e = doc.edges[_e].next

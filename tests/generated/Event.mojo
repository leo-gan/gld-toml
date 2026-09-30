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
from wire.flat import parse_f64, parse_i64, parse_toml_str, skip_tail, span_is, take_prefix, value_end
from wire.reader import decode_toml
from wire.writer import append_ascii, append_bool, append_datetime, append_float, append_int, append_toml_str
from EventAttr import EventAttr

struct Event(Copyable, Movable, Defaultable, Deinitable, TomlDatum):
    var ts: Int64
    var attrs: List[EventAttr]

    def __init__(out self):
        self.ts = Int64(0)
        self.attrs = List[EventAttr]()

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
        buf.append(Byte(116))
        buf.append(Byte(115))
        buf.append(Byte(32))
        buf.append(Byte(61))
        buf.append(Byte(32))
        append_int(buf, self.ts)
        buf.append(Byte(10))
        var _np1 = String("attrs")
        if prefix.byte_length() > 0:
            _np1 = prefix + ".attrs"
        var _i1 = 0
        if options.compact_arrays or options.inline_tables:
            append_ascii(buf, "attrs")
            append_ascii(buf, " = [")
            while _i1 < len(self.attrs):
                if _i1 > 0:
                    append_ascii(buf, ", ")
                self.attrs[_i1]._write(buf, options, False, _np1, True)
                _i1 += 1
            append_ascii(buf, "]\n")
        else:
            while _i1 < len(self.attrs):
                buf.append(Byte(10))
                append_ascii(buf, "[[")
                append_ascii(buf, _np1)
                append_ascii(buf, "]]\n")
                self.attrs[_i1]._write(buf, options, False, _np1, False)
                _i1 += 1

    def _write_inline(self, mut buf: List[Byte], options: EncodeOptions) raises:
        buf.append(Byte(123))
        var _first = True
        if not _first:
            append_ascii(buf, ", ")
        _first = False
        append_ascii(buf, "ts")
        append_ascii(buf, " = ")
        append_int(buf, self.ts)
        if not _first:
            append_ascii(buf, ", ")
        _first = False
        append_ascii(buf, "attrs")
        append_ascii(buf, " = ")
        buf.append(Byte(91))
        var _i = 0
        while _i < len(self.attrs):
            if _i > 0:
                append_ascii(buf, ", ")
            self.attrs[_i]._write(buf, options, False, String(), True)
            _i += 1
        buf.append(Byte(93))
        buf.append(Byte(125))

    def read_text(mut self, text: String) raises DecodeError:
        var doc = decode_toml(text)
        self.read_from(doc, doc.root)

    def read_from(mut self, doc: TomlDoc, node: Int) raises DecodeError:
        if doc.kind(node) != TK_TABLE:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        var _n0 = doc.find_key(node, "ts")
        if _n0 < 0:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        self.ts = doc.int_at(_n0)
        var _n1 = doc.find_key(node, "attrs")
        if _n1 < 0:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        self.attrs = List[EventAttr]()
        var _e = doc.first_edge(_n1)
        while _e >= 0:
            var _c = doc.edges[_e].child
            var _item = EventAttr()
            _item.read_from(doc, _c)
            self.attrs.append(_item^)
            _e = doc.edges[_e].next

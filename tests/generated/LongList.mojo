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

struct LongList(Copyable, Movable, Defaultable, Deinitable, TomlDatum):
    var value: Int64
    var next: Optional[Box[LongList]]

    def __init__(out self):
        self.value = Int64(0)
        self.next = Optional[Box[LongList]]()

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
        buf.append(Byte(118))
        buf.append(Byte(97))
        buf.append(Byte(108))
        buf.append(Byte(117))
        buf.append(Byte(101))
        buf.append(Byte(32))
        buf.append(Byte(61))
        buf.append(Byte(32))
        append_int(buf, self.value)
        buf.append(Byte(10))
        if self.next:
            var _in1 = self.next.value().copy()
            var _np1 = String("next")
            if prefix.byte_length() > 0:
                _np1 = prefix + ".next"
            if options.inline_tables:
                append_ascii(buf, "next")
                append_ascii(buf, " = ")
                _in1[]._write(buf, options, False, _np1, True)
                buf.append(Byte(10))
            else:
                buf.append(Byte(10))
                append_ascii(buf, "[")
                append_ascii(buf, _np1)
                append_ascii(buf, "]\n")
                _in1[]._write(buf, options, False, _np1, False)

    def _write_inline(self, mut buf: List[Byte], options: EncodeOptions) raises:
        buf.append(Byte(123))
        var _first = True
        if not _first:
            append_ascii(buf, ", ")
        _first = False
        append_ascii(buf, "value")
        append_ascii(buf, " = ")
        append_int(buf, self.value)
        if self.next:
            var _in1 = self.next.value().copy()
            if not _first:
                append_ascii(buf, ", ")
            _first = False
            append_ascii(buf, "next")
            append_ascii(buf, " = ")
            _in1[]._write(buf, options, False, String(), True)
        buf.append(Byte(125))

    def read_text(mut self, text: String) raises DecodeError:
        var doc = decode_toml(text)
        self.read_from(doc, doc.root)

    def read_from(mut self, doc: TomlDoc, node: Int) raises DecodeError:
        if doc.kind(node) != TK_TABLE:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        var _n0 = doc.find_key(node, "value")
        if _n0 < 0:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        self.value = doc.int_at(_n0)
        var _n1 = doc.find_key(node, "next")
        if _n1 < 0:
            self.next = Optional[Box[LongList]]()
        else:
            var _obj = LongList()
            _obj.read_from(doc, _n1)
            self.next = Optional[Box[LongList]](Box( _obj^))

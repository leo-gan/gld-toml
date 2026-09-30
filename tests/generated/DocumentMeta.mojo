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

struct DocumentMeta(Copyable, Movable, Defaultable, Deinitable, TomlDatum):
    var region: String
    var version: Int64

    def __init__(out self):
        self.region = String()
        self.version = Int64(0)

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
        append_ascii(buf, "region")
        append_ascii(buf, " = ")
        append_toml_str(buf, self.region)
        buf.append(Byte(10))
        append_ascii(buf, "version")
        append_ascii(buf, " = ")
        append_int(buf, self.version)
        buf.append(Byte(10))

    def _write_inline(self, mut buf: List[Byte], options: EncodeOptions) raises:
        buf.append(Byte(123))
        var _first = True
        if not _first:
            append_ascii(buf, ", ")
        _first = False
        append_ascii(buf, "region")
        append_ascii(buf, " = ")
        append_toml_str(buf, self.region)
        if not _first:
            append_ascii(buf, ", ")
        _first = False
        append_ascii(buf, "version")
        append_ascii(buf, " = ")
        append_int(buf, self.version)
        buf.append(Byte(125))

    def read_text(mut self, text: String) raises DecodeError:
        var raw = text.as_bytes()
        var n = len(raw)
        var i = 0
        while i < n:
            var c = Int(raw[i])
            if c == 91 or c == 92 or c == 123:
                var doc = decode_toml(text)
                self.read_from(doc, doc.root)
                return
            i += 1
        i = 0
        var _saw0 = False
        var _saw1 = False
        while i < n:
            var c = Int(raw[i])
            if c == 32 or c == 9 or c == 10 or c == 13:
                i += 1
                continue
            if c == 35:
                while i < n and Int(raw[i]) != 10:
                    i += 1
                continue
            var ks = i
            while i < n:
                c = Int(raw[i])
                if c == 32 or c == 9 or c == 61:
                    break
                i += 1
            var ke = i
            while i < n and (Int(raw[i]) == 32 or Int(raw[i]) == 9):
                i += 1
            if i >= n or Int(raw[i]) != 61:
                raise DecodeError(DecodeError.KIND_SYNTAX, i)
            i += 1
            while i < n and (Int(raw[i]) == 32 or Int(raw[i]) == 9):
                i += 1
            var vs = i
            if i < n and (Int(raw[i]) == 34 or Int(raw[i]) == 39):
                var q = Int(raw[i])
                i += 1
                while i < n and Int(raw[i]) != q:
                    if Int(raw[i]) == 92:
                        i += 1
                    if i < n:
                        i += 1
                if i < n:
                    i += 1
            else:
                while i < n and Int(raw[i]) != 10 and Int(raw[i]) != 35:
                    i += 1
            var ve = i
            while ve > vs and (Int(raw[ve - 1]) == 32 or Int(raw[ve - 1]) == 9):
                ve -= 1
            if span_is(raw, ks, ke, "region"):
                _saw0 = True
                self.region = parse_toml_str(raw, vs, ve)
            elif span_is(raw, ks, ke, "version"):
                _saw1 = True
                self.version = parse_i64(raw, vs, ve)
        if not _saw0:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        if not _saw1:
            raise DecodeError(DecodeError.KIND_TYPE, 0)

    def read_from(mut self, doc: TomlDoc, node: Int) raises DecodeError:
        if doc.kind(node) != TK_TABLE:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        var _n0 = doc.find_key(node, "region")
        if _n0 < 0:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        self.region = doc.text_at(_n0)
        var _n1 = doc.find_key(node, "version")
        if _n1 < 0:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        self.version = doc.int_at(_n1)

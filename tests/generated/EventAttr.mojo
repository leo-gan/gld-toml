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

struct EventAttr(Copyable, Movable, Defaultable, Deinitable, TomlDatum):
    var key: String
    var value: String

    def __init__(out self):
        self.key = String()
        self.value = String()

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
        buf.append(Byte(107))
        buf.append(Byte(101))
        buf.append(Byte(121))
        buf.append(Byte(32))
        buf.append(Byte(61))
        buf.append(Byte(32))
        append_toml_str(buf, self.key)
        buf.append(Byte(10))
        buf.append(Byte(118))
        buf.append(Byte(97))
        buf.append(Byte(108))
        buf.append(Byte(117))
        buf.append(Byte(101))
        buf.append(Byte(32))
        buf.append(Byte(61))
        buf.append(Byte(32))
        append_toml_str(buf, self.value)
        buf.append(Byte(10))

    def _write_inline(self, mut buf: List[Byte], options: EncodeOptions) raises:
        buf.append(Byte(123))
        var _first = True
        if not _first:
            append_ascii(buf, ", ")
        _first = False
        append_ascii(buf, "key")
        append_ascii(buf, " = ")
        append_toml_str(buf, self.key)
        if not _first:
            append_ascii(buf, ", ")
        _first = False
        append_ascii(buf, "value")
        append_ascii(buf, " = ")
        append_toml_str(buf, self.value)
        buf.append(Byte(125))

    def read_text(mut self, text: String) raises DecodeError:
        var raw = text.as_bytes()
        var n = len(raw)
        var _ord = 0
        if _ord >= 0:
            var _nx = take_prefix(raw, _ord, "key = ")
            if _nx < 0:
                _ord = -1
            else:
                var _ve = value_end(raw, _nx)
                var _esc = _nx
                while _esc < _ve and Int(raw[_esc]) != 92:
                    _esc += 1
                if _esc < _ve:
                    _ord = -1
                else:
                    self.key = parse_toml_str(raw, _nx, _ve)
                    _ord = skip_tail(raw, _ve)
        if _ord >= 0:
            var _nx = take_prefix(raw, _ord, "value = ")
            if _nx < 0:
                _ord = -1
            else:
                var _ve = value_end(raw, _nx)
                var _esc = _nx
                while _esc < _ve and Int(raw[_esc]) != 92:
                    _esc += 1
                if _esc < _ve:
                    _ord = -1
                else:
                    self.value = parse_toml_str(raw, _nx, _ve)
                    _ord = skip_tail(raw, _ve)
        if _ord >= 0:
            while _ord < n and (Int(raw[_ord]) == 32 or Int(raw[_ord]) == 9 or Int(raw[_ord]) == 10 or Int(raw[_ord]) == 13):
                _ord += 1
            if _ord == n:
                return
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
            if span_is(raw, ks, ke, "key"):
                _saw0 = True
                self.key = parse_toml_str(raw, vs, ve)
            elif span_is(raw, ks, ke, "value"):
                _saw1 = True
                self.value = parse_toml_str(raw, vs, ve)
        if not _saw0:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        if not _saw1:
            raise DecodeError(DecodeError.KIND_TYPE, 0)

    def read_from(mut self, doc: TomlDoc, node: Int) raises DecodeError:
        if doc.kind(node) != TK_TABLE:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        var _n0 = doc.find_key(node, "key")
        if _n0 < 0:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        self.key = doc.text_at(_n0)
        var _n1 = doc.find_key(node, "value")
        if _n1 < 0:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        self.value = doc.text_at(_n1)

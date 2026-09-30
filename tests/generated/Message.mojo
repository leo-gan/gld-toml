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

struct Message(Copyable, Movable, Defaultable, Deinitable, TomlDatum):
    var f_bool: Bool
    var f_int32: Int64
    var f_int64: Int64
    var f_float64: Float64
    var f_string: String
    var f_bool_2: Bool
    var f_int32_2: Int64
    var f_string_2: String

    def __init__(out self):
        self.f_bool = False
        self.f_int32 = Int64(0)
        self.f_int64 = Int64(0)
        self.f_float64 = Float64(0)
        self.f_string = String()
        self.f_bool_2 = False
        self.f_int32_2 = Int64(0)
        self.f_string_2 = String()

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
        buf.append(Byte(102))
        buf.append(Byte(95))
        buf.append(Byte(98))
        buf.append(Byte(111))
        buf.append(Byte(111))
        buf.append(Byte(108))
        buf.append(Byte(32))
        buf.append(Byte(61))
        buf.append(Byte(32))
        append_bool(buf, self.f_bool)
        buf.append(Byte(10))
        buf.append(Byte(102))
        buf.append(Byte(95))
        buf.append(Byte(105))
        buf.append(Byte(110))
        buf.append(Byte(116))
        buf.append(Byte(51))
        buf.append(Byte(50))
        buf.append(Byte(32))
        buf.append(Byte(61))
        buf.append(Byte(32))
        append_int(buf, self.f_int32)
        buf.append(Byte(10))
        buf.append(Byte(102))
        buf.append(Byte(95))
        buf.append(Byte(105))
        buf.append(Byte(110))
        buf.append(Byte(116))
        buf.append(Byte(54))
        buf.append(Byte(52))
        buf.append(Byte(32))
        buf.append(Byte(61))
        buf.append(Byte(32))
        append_int(buf, self.f_int64)
        buf.append(Byte(10))
        buf.append(Byte(102))
        buf.append(Byte(95))
        buf.append(Byte(102))
        buf.append(Byte(108))
        buf.append(Byte(111))
        buf.append(Byte(97))
        buf.append(Byte(116))
        buf.append(Byte(54))
        buf.append(Byte(52))
        buf.append(Byte(32))
        buf.append(Byte(61))
        buf.append(Byte(32))
        append_float(buf, self.f_float64)
        buf.append(Byte(10))
        buf.append(Byte(102))
        buf.append(Byte(95))
        buf.append(Byte(115))
        buf.append(Byte(116))
        buf.append(Byte(114))
        buf.append(Byte(105))
        buf.append(Byte(110))
        buf.append(Byte(103))
        buf.append(Byte(32))
        buf.append(Byte(61))
        buf.append(Byte(32))
        append_toml_str(buf, self.f_string)
        buf.append(Byte(10))
        buf.append(Byte(102))
        buf.append(Byte(95))
        buf.append(Byte(98))
        buf.append(Byte(111))
        buf.append(Byte(111))
        buf.append(Byte(108))
        buf.append(Byte(95))
        buf.append(Byte(50))
        buf.append(Byte(32))
        buf.append(Byte(61))
        buf.append(Byte(32))
        append_bool(buf, self.f_bool_2)
        buf.append(Byte(10))
        buf.append(Byte(102))
        buf.append(Byte(95))
        buf.append(Byte(105))
        buf.append(Byte(110))
        buf.append(Byte(116))
        buf.append(Byte(51))
        buf.append(Byte(50))
        buf.append(Byte(95))
        buf.append(Byte(50))
        buf.append(Byte(32))
        buf.append(Byte(61))
        buf.append(Byte(32))
        append_int(buf, self.f_int32_2)
        buf.append(Byte(10))
        buf.append(Byte(102))
        buf.append(Byte(95))
        buf.append(Byte(115))
        buf.append(Byte(116))
        buf.append(Byte(114))
        buf.append(Byte(105))
        buf.append(Byte(110))
        buf.append(Byte(103))
        buf.append(Byte(95))
        buf.append(Byte(50))
        buf.append(Byte(32))
        buf.append(Byte(61))
        buf.append(Byte(32))
        append_toml_str(buf, self.f_string_2)
        buf.append(Byte(10))

    def _write_inline(self, mut buf: List[Byte], options: EncodeOptions) raises:
        buf.append(Byte(123))
        var _first = True
        if not _first:
            append_ascii(buf, ", ")
        _first = False
        append_ascii(buf, "f_bool")
        append_ascii(buf, " = ")
        append_bool(buf, self.f_bool)
        if not _first:
            append_ascii(buf, ", ")
        _first = False
        append_ascii(buf, "f_int32")
        append_ascii(buf, " = ")
        append_int(buf, self.f_int32)
        if not _first:
            append_ascii(buf, ", ")
        _first = False
        append_ascii(buf, "f_int64")
        append_ascii(buf, " = ")
        append_int(buf, self.f_int64)
        if not _first:
            append_ascii(buf, ", ")
        _first = False
        append_ascii(buf, "f_float64")
        append_ascii(buf, " = ")
        append_float(buf, self.f_float64)
        if not _first:
            append_ascii(buf, ", ")
        _first = False
        append_ascii(buf, "f_string")
        append_ascii(buf, " = ")
        append_toml_str(buf, self.f_string)
        if not _first:
            append_ascii(buf, ", ")
        _first = False
        append_ascii(buf, "f_bool_2")
        append_ascii(buf, " = ")
        append_bool(buf, self.f_bool_2)
        if not _first:
            append_ascii(buf, ", ")
        _first = False
        append_ascii(buf, "f_int32_2")
        append_ascii(buf, " = ")
        append_int(buf, self.f_int32_2)
        if not _first:
            append_ascii(buf, ", ")
        _first = False
        append_ascii(buf, "f_string_2")
        append_ascii(buf, " = ")
        append_toml_str(buf, self.f_string_2)
        buf.append(Byte(125))

    def read_text(mut self, text: String) raises DecodeError:
        var raw = text.as_bytes()
        var n = len(raw)
        var _ord = 0
        if _ord >= 0:
            var _nx = take_prefix(raw, _ord, "f_bool = ")
            if _nx < 0:
                _ord = -1
            else:
                var _ve = value_end(raw, _nx)
                self.f_bool = span_is(raw, _nx, _ve, "true")
                if not self.f_bool and not span_is(raw, _nx, _ve, "false"):
                    _ord = -1
                else:
                    _ord = skip_tail(raw, _ve)
        if _ord >= 0:
            var _nx = take_prefix(raw, _ord, "f_int32 = ")
            if _nx < 0:
                _ord = -1
            else:
                var _ve = value_end(raw, _nx)
                self.f_int32 = parse_i64(raw, _nx, _ve)
                _ord = skip_tail(raw, _ve)
        if _ord >= 0:
            var _nx = take_prefix(raw, _ord, "f_int64 = ")
            if _nx < 0:
                _ord = -1
            else:
                var _ve = value_end(raw, _nx)
                self.f_int64 = parse_i64(raw, _nx, _ve)
                _ord = skip_tail(raw, _ve)
        if _ord >= 0:
            var _nx = take_prefix(raw, _ord, "f_float64 = ")
            if _nx < 0:
                _ord = -1
            else:
                var _ve = value_end(raw, _nx)
                self.f_float64 = parse_f64(raw, _nx, _ve)
                _ord = skip_tail(raw, _ve)
        if _ord >= 0:
            var _nx = take_prefix(raw, _ord, "f_string = ")
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
                    self.f_string = parse_toml_str(raw, _nx, _ve)
                    _ord = skip_tail(raw, _ve)
        if _ord >= 0:
            var _nx = take_prefix(raw, _ord, "f_bool_2 = ")
            if _nx < 0:
                _ord = -1
            else:
                var _ve = value_end(raw, _nx)
                self.f_bool_2 = span_is(raw, _nx, _ve, "true")
                if not self.f_bool_2 and not span_is(raw, _nx, _ve, "false"):
                    _ord = -1
                else:
                    _ord = skip_tail(raw, _ve)
        if _ord >= 0:
            var _nx = take_prefix(raw, _ord, "f_int32_2 = ")
            if _nx < 0:
                _ord = -1
            else:
                var _ve = value_end(raw, _nx)
                self.f_int32_2 = parse_i64(raw, _nx, _ve)
                _ord = skip_tail(raw, _ve)
        if _ord >= 0:
            var _nx = take_prefix(raw, _ord, "f_string_2 = ")
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
                    self.f_string_2 = parse_toml_str(raw, _nx, _ve)
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
        var _saw2 = False
        var _saw3 = False
        var _saw4 = False
        var _saw5 = False
        var _saw6 = False
        var _saw7 = False
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
            if span_is(raw, ks, ke, "f_bool"):
                _saw0 = True
                self.f_bool = span_is(raw, vs, ve, "true")
                if not self.f_bool and not span_is(raw, vs, ve, "false"):
                    raise DecodeError(DecodeError.KIND_SYNTAX, vs)
            elif span_is(raw, ks, ke, "f_int32"):
                _saw1 = True
                self.f_int32 = parse_i64(raw, vs, ve)
            elif span_is(raw, ks, ke, "f_int64"):
                _saw2 = True
                self.f_int64 = parse_i64(raw, vs, ve)
            elif span_is(raw, ks, ke, "f_float64"):
                _saw3 = True
                self.f_float64 = parse_f64(raw, vs, ve)
            elif span_is(raw, ks, ke, "f_string"):
                _saw4 = True
                self.f_string = parse_toml_str(raw, vs, ve)
            elif span_is(raw, ks, ke, "f_bool_2"):
                _saw5 = True
                self.f_bool_2 = span_is(raw, vs, ve, "true")
                if not self.f_bool_2 and not span_is(raw, vs, ve, "false"):
                    raise DecodeError(DecodeError.KIND_SYNTAX, vs)
            elif span_is(raw, ks, ke, "f_int32_2"):
                _saw6 = True
                self.f_int32_2 = parse_i64(raw, vs, ve)
            elif span_is(raw, ks, ke, "f_string_2"):
                _saw7 = True
                self.f_string_2 = parse_toml_str(raw, vs, ve)
        if not _saw0:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        if not _saw1:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        if not _saw2:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        if not _saw3:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        if not _saw4:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        if not _saw5:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        if not _saw6:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        if not _saw7:
            raise DecodeError(DecodeError.KIND_TYPE, 0)

    def read_from(mut self, doc: TomlDoc, node: Int) raises DecodeError:
        if doc.kind(node) != TK_TABLE:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        var _n0 = doc.find_key(node, "f_bool")
        if _n0 < 0:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        self.f_bool = doc.kind(_n0) == TK_TRUE
        var _n1 = doc.find_key(node, "f_int32")
        if _n1 < 0:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        self.f_int32 = doc.int_at(_n1)
        var _n2 = doc.find_key(node, "f_int64")
        if _n2 < 0:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        self.f_int64 = doc.int_at(_n2)
        var _n3 = doc.find_key(node, "f_float64")
        if _n3 < 0:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        self.f_float64 = doc.float_at(_n3)
        var _n4 = doc.find_key(node, "f_string")
        if _n4 < 0:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        self.f_string = doc.text_at(_n4)
        var _n5 = doc.find_key(node, "f_bool_2")
        if _n5 < 0:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        self.f_bool_2 = doc.kind(_n5) == TK_TRUE
        var _n6 = doc.find_key(node, "f_int32_2")
        if _n6 < 0:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        self.f_int32_2 = doc.int_at(_n6)
        var _n7 = doc.find_key(node, "f_string_2")
        if _n7 < 0:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        self.f_string_2 = doc.text_at(_n7)

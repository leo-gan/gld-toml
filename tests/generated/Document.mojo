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
from DocumentMeta import DocumentMeta
from DocumentItem import DocumentItem

struct Document(Copyable, Movable, Defaultable, Deinitable, TomlDatum):
    var id: String
    var status: Int64
    var meta: DocumentMeta
    var items: List[DocumentItem]

    def __init__(out self):
        self.id = String()
        self.status = Int64(0)
        self.meta = DocumentMeta()
        self.items = List[DocumentItem]()

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
        buf.append(Byte(105))
        buf.append(Byte(100))
        buf.append(Byte(32))
        buf.append(Byte(61))
        buf.append(Byte(32))
        append_toml_str(buf, self.id)
        buf.append(Byte(10))
        buf.append(Byte(115))
        buf.append(Byte(116))
        buf.append(Byte(97))
        buf.append(Byte(116))
        buf.append(Byte(117))
        buf.append(Byte(115))
        buf.append(Byte(32))
        buf.append(Byte(61))
        buf.append(Byte(32))
        append_int(buf, self.status)
        buf.append(Byte(10))
        var _np2 = String("meta")
        if prefix.byte_length() > 0:
            _np2 = prefix + ".meta"
        if options.inline_tables:
            append_ascii(buf, "meta")
            append_ascii(buf, " = ")
            self.meta._write(buf, options, False, _np2, True)
            buf.append(Byte(10))
        else:
            buf.append(Byte(10))
            append_ascii(buf, "[")
            append_ascii(buf, _np2)
            append_ascii(buf, "]\n")
            self.meta._write(buf, options, False, _np2, False)
        var _np3 = String("items")
        if prefix.byte_length() > 0:
            _np3 = prefix + ".items"
        var _i3 = 0
        if options.compact_arrays or options.inline_tables:
            append_ascii(buf, "items")
            append_ascii(buf, " = [")
            while _i3 < len(self.items):
                if _i3 > 0:
                    append_ascii(buf, ", ")
                self.items[_i3]._write(buf, options, False, _np3, True)
                _i3 += 1
            append_ascii(buf, "]\n")
        else:
            while _i3 < len(self.items):
                buf.append(Byte(10))
                append_ascii(buf, "[[")
                append_ascii(buf, _np3)
                append_ascii(buf, "]]\n")
                self.items[_i3]._write(buf, options, False, _np3, False)
                _i3 += 1

    def _write_inline(self, mut buf: List[Byte], options: EncodeOptions) raises:
        buf.append(Byte(123))
        var _first = True
        if not _first:
            append_ascii(buf, ", ")
        _first = False
        append_ascii(buf, "id")
        append_ascii(buf, " = ")
        append_toml_str(buf, self.id)
        if not _first:
            append_ascii(buf, ", ")
        _first = False
        append_ascii(buf, "status")
        append_ascii(buf, " = ")
        append_int(buf, self.status)
        if not _first:
            append_ascii(buf, ", ")
        _first = False
        append_ascii(buf, "meta")
        append_ascii(buf, " = ")
        self.meta._write(buf, options, False, String(), True)
        if not _first:
            append_ascii(buf, ", ")
        _first = False
        append_ascii(buf, "items")
        append_ascii(buf, " = ")
        buf.append(Byte(91))
        var _i = 0
        while _i < len(self.items):
            if _i > 0:
                append_ascii(buf, ", ")
            self.items[_i]._write(buf, options, False, String(), True)
            _i += 1
        buf.append(Byte(93))
        buf.append(Byte(125))

    def read_text(mut self, text: String) raises DecodeError:
        var doc = decode_toml(text)
        self.read_from(doc, doc.root)

    def read_from(mut self, doc: TomlDoc, node: Int) raises DecodeError:
        if doc.kind(node) != TK_TABLE:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        var _n0 = doc.find_key(node, "id")
        if _n0 < 0:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        self.id = doc.text_at(_n0)
        var _n1 = doc.find_key(node, "status")
        if _n1 < 0:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        self.status = doc.int_at(_n1)
        var _n2 = doc.find_key(node, "meta")
        if _n2 < 0:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        var _obj = DocumentMeta()
        _obj.read_from(doc, _n2)
        self.meta = _obj^
        var _n3 = doc.find_key(node, "items")
        if _n3 < 0:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        self.items = List[DocumentItem]()
        var _e = doc.first_edge(_n3)
        while _e >= 0:
            var _c = doc.edges[_e].child
            var _item = DocumentItem()
            _item.read_from(doc, _c)
            self.items.append(_item^)
            _e = doc.edges[_e].next

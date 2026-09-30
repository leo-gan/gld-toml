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

struct When(Copyable, Movable, Defaultable, Deinitable, TomlDatum):
    var at: TomlDateTime
    var note: Optional[String]

    def __init__(out self):
        self.at = TomlDateTime()
        self.note = Optional[String]()

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
        append_ascii(buf, "at")
        append_ascii(buf, " = ")
        append_datetime(buf, self.at)
        buf.append(Byte(10))
        if self.note:
            var _in1 = self.note.value().copy()
            append_ascii(buf, "note")
            append_ascii(buf, " = ")
            append_toml_str(buf, _in1)
            buf.append(Byte(10))

    def _write_inline(self, mut buf: List[Byte], options: EncodeOptions) raises:
        buf.append(Byte(123))
        var _first = True
        if not _first:
            append_ascii(buf, ", ")
        _first = False
        append_ascii(buf, "at")
        append_ascii(buf, " = ")
        append_datetime(buf, self.at)
        if self.note:
            var _in1 = self.note.value().copy()
            if not _first:
                append_ascii(buf, ", ")
            _first = False
            append_ascii(buf, "note")
            append_ascii(buf, " = ")
            append_toml_str(buf, _in1)
        buf.append(Byte(125))

    def read_text(mut self, text: String) raises DecodeError:
        var doc = decode_toml(text)
        self.read_from(doc, doc.root)

    def read_from(mut self, doc: TomlDoc, node: Int) raises DecodeError:
        if doc.kind(node) != TK_TABLE:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        var _n0 = doc.find_key(node, "at")
        if _n0 < 0:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        self.at = doc.date_at(_n0)
        var _n1 = doc.find_key(node, "note")
        if _n1 < 0:
            self.note = Optional[String]()
        else:
            self.note = doc.text_at(_n1)

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
from wire.writer import encode_toml

struct EventAttr(Copyable, Movable, Defaultable, Deinitable, TomlDatum):
    var key: String
    var value: String

    def __init__(out self):
        self.key = String()
        self.value = String()

    def encoded_len(self, options: EncodeOptions) raises -> Int:
        var doc = self._to_doc()
        var text = encode_toml(doc, options)
        return text.byte_length()

    def encode_to(self, mut buf: List[Byte], options: EncodeOptions) raises:
        var doc = self._to_doc()
        var text = encode_toml(doc, options)
        var raw = text.as_bytes()
        var i = 0
        while i < len(raw):
            buf.append(raw[i])
            i += 1

    def _to_doc(self) raises -> TomlDoc:
        var doc = TomlDoc()
        self._fill(doc, doc.root)
        return doc^

    def _fill(self, mut doc: TomlDoc, node: Int) raises:
        var _k0 = doc.add_text(String("key"))
        doc.append_child(node, _k0, doc.make_string(String(self.key), node))
        var _k1 = doc.add_text(String("value"))
        doc.append_child(node, _k1, doc.make_string(String(self.value), node))

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

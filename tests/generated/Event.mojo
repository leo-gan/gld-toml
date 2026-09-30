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
from EventAttr import EventAttr

struct Event(Copyable, Movable, Defaultable, Deinitable, TomlDatum):
    var ts: Int64
    var attrs: List[EventAttr]

    def __init__(out self):
        self.ts = Int64(0)
        self.attrs = List[EventAttr]()

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
        var _k0 = doc.add_text(String("ts"))
        doc.append_child(node, _k0, doc.make_int(self.ts, node))
        var _k1 = doc.add_text(String("attrs"))
        var _arr = doc.make_array(node)
        var _i = 0
        while _i < len(self.attrs):
            var _el = doc.make_table(_arr)
            self.attrs[_i]._fill(doc, _el)
            doc.append_child(_arr, -1, _el)
            _i += 1
        doc.append_child(node, _k1, _arr)

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

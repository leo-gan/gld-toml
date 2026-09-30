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
        var _k0 = doc.add_text(String("id"))
        doc.append_child(node, _k0, doc.make_string(String(self.id), node))
        var _k1 = doc.add_text(String("status"))
        doc.append_child(node, _k1, doc.make_int(self.status, node))
        var _k2 = doc.add_text(String("meta"))
        var _child = doc.make_table(node)
        self.meta._fill(doc, _child)
        doc.append_child(node, _k2, _child)
        var _k3 = doc.add_text(String("items"))
        var _arr = doc.make_array(node)
        var _i = 0
        while _i < len(self.items):
            var _el = doc.make_table(_arr)
            self.items[_i]._fill(doc, _el)
            doc.append_child(_arr, -1, _el)
            _i += 1
        doc.append_child(node, _k3, _arr)

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

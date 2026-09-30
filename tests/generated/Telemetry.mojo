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

struct Telemetry(Copyable, Movable, Defaultable, Deinitable, TomlDatum):
    var values: List[Float64]

    def __init__(out self):
        self.values = List[Float64]()

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
        var _k0 = doc.add_text(String("values"))
        var _arr = doc.make_array(node)
        var _i = 0
        while _i < len(self.values):
            doc.append_child(_arr, -1, doc.make_float(UInt64((self.values[_i]).to_bits()), _arr))
            _i += 1
        doc.append_child(node, _k0, _arr)

    def read_from(mut self, doc: TomlDoc, node: Int) raises DecodeError:
        if doc.kind(node) != TK_TABLE:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        var _n0 = doc.find_key(node, "values")
        if _n0 < 0:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        self.values = List[Float64]()
        var _e = doc.first_edge(_n0)
        while _e >= 0:
            var _c = doc.edges[_e].child
            self.values.append(doc.float_at(_c))
            _e = doc.edges[_e].next

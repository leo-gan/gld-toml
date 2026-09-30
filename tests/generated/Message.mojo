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
        var _k0 = doc.add_text(String("f_bool"))
        doc.append_child(node, _k0, doc.make_bool(self.f_bool, node))
        var _k1 = doc.add_text(String("f_int32"))
        doc.append_child(node, _k1, doc.make_int(self.f_int32, node))
        var _k2 = doc.add_text(String("f_int64"))
        doc.append_child(node, _k2, doc.make_int(self.f_int64, node))
        var _k3 = doc.add_text(String("f_float64"))
        doc.append_child(node, _k3, doc.make_float(UInt64((self.f_float64).to_bits()), node))
        var _k4 = doc.add_text(String("f_string"))
        doc.append_child(node, _k4, doc.make_string(String(self.f_string), node))
        var _k5 = doc.add_text(String("f_bool_2"))
        doc.append_child(node, _k5, doc.make_bool(self.f_bool_2, node))
        var _k6 = doc.add_text(String("f_int32_2"))
        doc.append_child(node, _k6, doc.make_int(self.f_int32_2, node))
        var _k7 = doc.add_text(String("f_string_2"))
        doc.append_child(node, _k7, doc.make_string(String(self.f_string_2), node))

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

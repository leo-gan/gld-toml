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
from Cat import Cat
from Dog import Dog

struct Pet(Copyable, Movable, Defaultable, Deinitable, TomlDatum):
    var tag: Int
    var Cat: Optional[Cat]
    var Dog: Optional[Dog]

    def __init__(out self):
        self.tag = 0
        self.Cat = Optional[Cat]()
        self.Dog = Optional[Dog]()

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
        _ = node
        if self.tag == 0 and self.Cat:
            self.Cat.value()._fill(doc, node)
        if self.tag == 1 and self.Dog:
            self.Dog.value()._fill(doc, node)

    def read_from(mut self, doc: TomlDoc, node: Int) raises DecodeError:
        if doc.kind(node) != TK_TABLE:
            raise DecodeError(DecodeError.KIND_TYPE, 0)
        var _ok0 = True
        if doc.find_key(node, "lives") < 0:
            _ok0 = False
        if _ok0:
            var _b = Cat()
            _b.read_from(doc, node)
            self.tag = 0
            self.Cat = Optional[Cat](_b^)
            return
        var _ok1 = True
        if doc.find_key(node, "breed") < 0:
            _ok1 = False
        if _ok1:
            var _b = Dog()
            _b.read_from(doc, node)
            self.tag = 1
            self.Dog = Optional[Dog](_b^)
            return
        raise DecodeError(DecodeError.KIND_TYPE, 0)

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
        _ = root
        _ = inline
        if self.tag == 0 and self.Cat:
            self.Cat.value()._write(buf, options, True, prefix, False)
            return
        if self.tag == 1 and self.Dog:
            self.Dog.value()._write(buf, options, True, prefix, False)
            return

    def _write_inline(self, mut buf: List[Byte], options: EncodeOptions) raises:
        _ = options
        if self.tag == 0 and self.Cat:
            self.Cat.value()._write_inline(buf, options)
            return
        if self.tag == 1 and self.Dog:
            self.Dog.value()._write_inline(buf, options)
            return
        buf.append(Byte(123))
        buf.append(Byte(125))

    def read_text(mut self, text: String) raises DecodeError:
        var doc = decode_toml(text)
        self.read_from(doc, doc.root)

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

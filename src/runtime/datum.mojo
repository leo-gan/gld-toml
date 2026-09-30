from std.collections import List

from runtime.error import DecodeError
from runtime.options import EncodeOptions
from wire.doc import TomlDoc
from wire.reader import decode_toml


trait TomlDatum(Copyable, Movable, Defaultable, Deinitable):
    def encoded_len(self, options: EncodeOptions) raises -> Int:
        ...

    def encode_to(self, mut buf: List[Byte], options: EncodeOptions) raises:
        ...

    def read_from(mut self, doc: TomlDoc, node: Int) raises DecodeError:
        ...


def encode_text[
    T: TomlDatum
](value: T, options: EncodeOptions = EncodeOptions.standard) raises -> String:
    var buf = List[Byte]()
    value.encode_to(buf, options)
    try:
        return String(from_utf8=buf)
    except _:
        return String()


def decode_text[
    T: TomlDatum
](text: String, options: EncodeOptions = EncodeOptions.standard) raises DecodeError -> T:
    _ = options
    var doc = decode_toml(text)
    var msg = T()
    msg.read_from(doc, doc.root)
    return msg^



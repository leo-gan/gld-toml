from std.collections import List

from runtime.error import DecodeError
from runtime.options import EncodeOptions
from wire.doc import TomlDoc


trait TomlDatum(Copyable, Movable, Defaultable, Deinitable):
    def encoded_len(self, options: EncodeOptions) raises -> Int:
        ...

    def encode_to(self, mut buf: List[Byte], options: EncodeOptions) raises:
        ...

    def read_from(mut self, doc: TomlDoc, node: Int) raises DecodeError:
        ...

    def read_text(mut self, text: String) raises DecodeError:
        ...


def encode_text[
    T: TomlDatum
](value: T, options: EncodeOptions = EncodeOptions.standard) raises -> String:
    var buf = List[Byte](capacity=128)
    value.encode_to(buf, options)
    return String(unsafe_from_utf8=buf)


def decode_text[
    T: TomlDatum
](text: String, options: EncodeOptions = EncodeOptions.standard) raises DecodeError -> T:
    _ = options
    var msg = T()
    msg.read_text(text)
    return msg^



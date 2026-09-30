from std.collections import List, Span

from runtime.error import DecodeError


def string_from_utf8[
    origin: ImmOrigin
](span: Span[Byte, origin], offset: Int, field: Int = 0) raises DecodeError -> String:
    try:
        return String(from_utf8=span)
    except _:
        raise DecodeError(DecodeError.KIND_UTF8, offset, field)


def string_from_bytes(buf: List[Byte], offset: Int) raises DecodeError -> String:
    try:
        return String(from_utf8=buf)
    except _:
        raise DecodeError(DecodeError.KIND_UTF8, offset)


def append_scalar(mut buf: List[Byte], cp: Int, offset: Int) raises DecodeError:
    if cp < 0 or cp > 0x10FFFF or (cp >= 0xD800 and cp <= 0xDFFF):
        raise DecodeError(DecodeError.KIND_ESCAPE, offset)
    if cp < 0x80:
        buf.append(Byte(cp))
        return
    if cp < 0x800:
        buf.append(Byte(0xC0 | (cp >> 6)))
        buf.append(Byte(0x80 | (cp & 0x3F)))
        return
    if cp < 0x10000:
        buf.append(Byte(0xE0 | (cp >> 12)))
        buf.append(Byte(0x80 | ((cp >> 6) & 0x3F)))
        buf.append(Byte(0x80 | (cp & 0x3F)))
        return
    buf.append(Byte(0xF0 | (cp >> 18)))
    buf.append(Byte(0x80 | ((cp >> 12) & 0x3F)))
    buf.append(Byte(0x80 | ((cp >> 6) & 0x3F)))
    buf.append(Byte(0x80 | (cp & 0x3F)))

from std.collections import List, Span

from runtime.error import DecodeError
from wire.utf8 import string_from_bytes


def span_is[
    origin: ImmOrigin
](raw: Span[Byte, origin], start: Int, end: Int, lit: String) -> Bool:
    var b = lit.as_bytes()
    if end - start != len(b):
        return False
    var i = 0
    while i < len(b):
        if raw[start + i] != b[i]:
            return False
        i += 1
    return True


def parse_i64[
    origin: ImmOrigin
](raw: Span[Byte, origin], start: Int, end: Int) raises DecodeError -> Int64:
    if start >= end:
        raise DecodeError(DecodeError.KIND_SYNTAX, start)
    var i = start
    var neg = False
    if Int(raw[i]) == 45:
        neg = True
        i += 1
    elif Int(raw[i]) == 43:
        i += 1
    if i >= end:
        raise DecodeError(DecodeError.KIND_SYNTAX, start)
    var acc = UInt64(0)
    var limit = UInt64(9223372036854775807)
    if neg:
        limit = limit + UInt64(1)
    while i < end:
        var c = Int(raw[i])
        if c == 95:
            i += 1
            continue
        if c < 48 or c > 57:
            raise DecodeError(DecodeError.KIND_SYNTAX, i)
        var d = UInt64(c - 48)
        if acc > (limit - d) // UInt64(10):
            raise DecodeError(DecodeError.KIND_RANGE, i)
        acc = acc * UInt64(10) + d
        i += 1
    if neg:
        if acc == UInt64(9223372036854775808):
            return Int64.MIN
        return Int64(0) - Int64(acc)
    return Int64(acc)


def parse_f64[
    origin: ImmOrigin
](raw: Span[Byte, origin], start: Int, end: Int) raises DecodeError -> Float64:
    try:
        return Float64(String(from_utf8=raw[start:end]))
    except _:
        raise DecodeError(DecodeError.KIND_SYNTAX, start)


def parse_toml_str[
    origin: ImmOrigin
](raw: Span[Byte, origin], start: Int, end: Int) raises DecodeError -> String:
    if start >= end:
        raise DecodeError(DecodeError.KIND_SYNTAX, start)
    var q = Int(raw[start])
    if q != 34 and q != 39:
        raise DecodeError(DecodeError.KIND_SYNTAX, start)
    var buf = List[Byte]()
    var i = start + 1
    while i < end and Int(raw[i]) != q:
        var c = Int(raw[i])
        if c == 92 and q == 34:
            i += 1
            if i >= end:
                raise DecodeError(DecodeError.KIND_ESCAPE, i)
            var e = Int(raw[i])
            if e == 110:
                buf.append(Byte(10))
            elif e == 116:
                buf.append(Byte(9))
            elif e == 114:
                buf.append(Byte(13))
            elif e == 92 or e == 34:
                buf.append(Byte(e))
            else:
                buf.append(Byte(e))
        else:
            buf.append(Byte(c))
        i += 1
    return string_from_bytes(buf^, start)

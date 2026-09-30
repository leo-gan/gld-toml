from std.time import perf_counter_ns

from runtime.datum import decode_text, encode_text
from wire.reader import decode_toml
from wire.writer import encode_toml

from Message import Message


def _sample() -> Message:
    var m = Message()
    m.f_bool = True
    m.f_int32 = Int64(1)
    m.f_int64 = Int64(150)
    m.f_float64 = Float64(1.5)
    m.f_string = String("hi")
    m.f_bool_2 = False
    m.f_int32_2 = Int64(2)
    m.f_string_2 = String("z")
    return m^


def main() raises:
    var n = 4000
    var m = _sample()
    var i = 0
    while i < 100:
        _ = encode_text(m)
        i += 1
    var t0 = perf_counter_ns()
    i = 0
    while i < n:
        _ = encode_text(m)
        i += 1
    var enc = Int(perf_counter_ns() - t0) // n
    var text = encode_text(m)
    i = 0
    while i < 100:
        _ = decode_text[Message](text)
        i += 1
    t0 = perf_counter_ns()
    i = 0
    while i < n:
        _ = decode_text[Message](text)
        i += 1
    var dec = Int(perf_counter_ns() - t0) // n
    var raw = String("name = \"Tom\"\nage = 42\nnums = [1, 2, 3]\n")
    i = 0
    while i < 100:
        _ = decode_toml(raw)
        i += 1
    t0 = perf_counter_ns()
    i = 0
    while i < n:
        _ = decode_toml(raw)
        i += 1
    var dyn_dec = Int(perf_counter_ns() - t0) // n
    var doc = decode_toml(raw)
    i = 0
    while i < 100:
        _ = encode_toml(doc)
        i += 1
    t0 = perf_counter_ns()
    i = 0
    while i < n:
        _ = encode_toml(doc)
        i += 1
    var dyn_enc = Int(perf_counter_ns() - t0) // n
    print("generated_encode_ns", enc)
    print("generated_decode_ns", dec)
    print("value_encode_ns", dyn_enc)
    print("value_decode_ns", dyn_dec)
    print("generated_bytes", text.byte_length())

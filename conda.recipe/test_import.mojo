from toml import DecodeError, decode_toml


def main() raises:
    var doc = decode_toml(String("answer = 42\n"))
    var n = doc.find_key(doc.root, "answer")
    if doc.int_at(n) != Int64(42):
        raise Error("import decode failed")
    print("toml import ok", DecodeError.KIND_EOF)

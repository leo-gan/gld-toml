from runtime.error import DecodeError
from wire.tagged import doc_from_tagged
from wire.writer import encode_toml


def main() raises:
    try:
        var f = open("/dev/stdin", "r")
        var text = f.read()
        f.close()
        var doc = doc_from_tagged(text)
        print(encode_toml(doc), end="")
    except e:
        print(e)
        raise e

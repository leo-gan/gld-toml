from runtime.error import DecodeError
from wire.reader import decode_toml
from wire.tagged import tagged_json


def _stdin() raises -> String:
    var f = open("/dev/stdin", "r")
    var text = f.read()
    f.close()
    return text^


def main() raises:
    try:
        var text = _stdin()
        var doc = decode_toml(text)
        print(tagged_json(doc), end="")
    except e:
        print(e)
        raise e

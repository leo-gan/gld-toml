from runtime.error import DecodeError
from wire.doc import DT_OFFSET, TK_INT, TK_STRING, TK_TABLE
from wire.reader import decode_toml


def fail(msg: String) raises:
    raise Error(msg)


def main() raises:
    var doc = decode_toml(String("name = \"Tom\"\nage = 42\n"))
    if doc.kind(doc.root) != TK_TABLE:
        fail("root")
    var name = doc.find_key(doc.root, "name")
    if doc.kind(name) != TK_STRING or doc.text_at(name) != "Tom":
        fail("name")
    var age = doc.find_key(doc.root, "age")
    if doc.kind(age) != TK_INT or doc.int_at(age) != Int64(42):
        fail("age")

    var nested = decode_toml(String("fruit.apple.color = \"red\"\nfruit.orange = 2\n"))
    var fruit = nested.find_key(nested.root, "fruit")
    var apple = nested.find_key(fruit, "apple")
    var color = nested.find_key(apple, "color")
    if nested.text_at(color) != "red":
        fail("color")
    var orange = nested.find_key(fruit, "orange")
    if nested.int_at(orange) != Int64(2):
        fail("orange")

    var dt = decode_toml(String("odt = 1979-05-27T07:32:00Z\n"))
    var node = dt.find_key(dt.root, "odt")
    if dt.date_at(node).sub != DT_OFFSET:
        fail("dt")

    var bad = False
    try:
        _ = decode_toml(String("a = 1\na = 2\n"))
    except e:
        bad = True
        if e.kind != DecodeError.KIND_DUP_KEY:
            fail("dup kind")
    if not bad:
        fail("dup should fail")
    print("ok")

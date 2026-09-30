from std.collections import List

from runtime.error import DecodeError
from schema.json_read import ReadValue, decode_json
from wire.doc import TK_ARRAY, TK_DATETIME, TK_FALSE, TK_FLOAT, TK_INT, TK_STRING, TK_TABLE, TK_TRUE, TomlDoc
from runtime.options import EncodeOptions
from wire.reader import decode_toml
from wire.writer import encode_toml


def fail(msg: String) raises DecodeError:
    print(msg)
    raise DecodeError(DecodeError.KIND_TYPE, 0)


def read_file(path: String) raises DecodeError -> String:
    try:
        var f = open(path, "r")
        var text = f.read()
        f.close()
        return text^
    except _:
        raise DecodeError(DecodeError.KIND_SYNTAX, 0)


def is_tagged(jv: ReadValue) raises DecodeError -> Bool:
    if not jv.is_object() or jv.count() != 2:
        return False
    var saw_type = False
    var saw_value = False
    var i = 0
    while i < jv.count():
        var pair = jv.pair(i)
        if pair[0] == "type":
            saw_type = True
        elif pair[0] == "value":
            saw_value = True
        i += 1
    return saw_type and saw_value


def tagged(jv: ReadValue, key: String) raises DecodeError -> String:
    var i = 0
    while i < jv.count():
        var pair = jv.pair(i)
        if pair[0] == key:
            return pair[1].as_str()
        i += 1
    fail("missing " + key)
    return String()


def same_float(a: Float64, text: String) raises DecodeError -> Bool:
    if text == "nan" or text == "+nan" or text == "-nan" or text == "NaN":
        return a != a
    try:
        var b = Float64(text)
        if a != a or b != b:
            return False
        return a == b
    except _:
        return False


def int_text(v: Int64) -> String:
    if v == Int64(0):
        return String("0")
    if v == Int64.MIN:
        return String("-9223372036854775808")
    var neg = v < Int64(0)
    var x = v
    if neg:
        x = Int64(0) - v
    var buf = List[Byte]()
    while x > Int64(0):
        var d = Int(x % Int64(10))
        buf.append(Byte(48 + d))
        x = x // Int64(10)
    var out = List[Byte]()
    if neg:
        out.append(Byte(45))
    var i = len(buf) - 1
    while i >= 0:
        out.append(buf[i])
        i -= 1
    try:
        return String(from_utf8=out)
    except _:
        return String("?")


def same(doc: TomlDoc, node: Int, jv: ReadValue, path: String) raises DecodeError:
    if jv.is_array():
        if doc.kind(node) != TK_ARRAY:
            fail(path + " expected array")
        if doc.child_count(node) != jv.count():
            fail(path + " array len")
        var e = doc.first_edge(node)
        var i = 0
        while i < jv.count():
            if e < 0:
                fail(path + " short array")
            same(doc, doc.edges[e].child, jv.at(i), path + "[]")
            e = doc.edges[e].next
            i += 1
        return
    if jv.is_object() and is_tagged(jv):
        var ty = tagged(jv, "type")
        var val = tagged(jv, "value")
        var k = doc.kind(node)
        if ty == "string":
            if k != TK_STRING or doc.text_at(node) != val:
                fail(path + " string")
        elif ty == "integer":
            if k != TK_INT or int_text(doc.int_at(node)) != val:
                fail(path + " integer got " + int_text(doc.int_at(node)) + " want " + val)
        elif ty == "float":
            if k != TK_FLOAT or not same_float(doc.float_at(node), val):
                fail(path + " float")
        elif ty == "bool":
            if val == "true":
                if k != TK_TRUE:
                    fail(path + " bool")
            elif val == "false":
                if k != TK_FALSE:
                    fail(path + " bool")
            else:
                fail(path + " bool token")
        elif ty == "datetime" or ty == "datetime-local" or ty == "date-local" or ty == "time-local":
            if k != TK_DATETIME:
                fail(path + " datetime kind")
            var wrapped = String("v = ") + val + String("\n")
            var again = decode_toml(wrapped)
            var w = again.find_key(again.root, "v")
            var a = doc.date_at(node)
            var b = again.date_at(w)
            if a.sub != b.sub or a.year != b.year or a.month != b.month or a.day != b.day:
                fail(path + " date")
            if a.hour != b.hour or a.minute != b.minute or a.second != b.second or a.nanos != b.nanos:
                fail(path + " time")
            if a.offset_z != b.offset_z or a.offset_minutes != b.offset_minutes:
                fail(path + " offset")
        else:
            fail(path + " unknown type " + ty)
        return
    if jv.is_object():
        if doc.kind(node) != TK_TABLE:
            fail(path + " expected table")
        if doc.child_count(node) != jv.count():
            fail(path + " table len")
        var i = 0
        while i < jv.count():
            var pair = jv.pair(i)
            var child = doc.find_key(node, pair[0])
            if child < 0:
                fail(path + " missing key " + pair[0])
            same(doc, child, pair[1], path + "." + pair[0])
            i += 1
        return
    fail(path + " bad json")


def main() raises:
    var list_text = read_file("testdata/toml-test/files-toml-1.1.0")
    var raw = list_text.as_bytes()
    var failed = 0
    var checked = 0
    var start = 0
    var i = 0
    while i <= len(raw):
        var end = i == len(raw) or Int(raw[i]) == 10
        if end:
            if i > start:
                var line = String(from_utf8=raw[start:i])
                if line.byte_length() > 5 and line.endswith(".toml"):
                    checked += 1
                    var path = String("testdata/toml-test/") + line
                    var invalid = line.startswith("invalid/")
                    try:
                        var text = read_file(path)
                        if invalid:
                            var bad = False
                            try:
                                _ = decode_toml(text)
                            except _:
                                bad = True
                            if not bad:
                                failed += 1
                                if failed <= 50:
                                    print("SHOULD FAIL", line)
                        else:
                            var doc = decode_toml(text)
                            var stem = line[byte=0 : line.byte_length() - 5]
                            var jpath = String("testdata/toml-test/") + stem + ".json"
                            var jtext = read_file(jpath)
                            var jv = decode_json(jtext.as_bytes())
                            same(doc, doc.root, jv, line)
                            var encoded = encode_toml(doc, EncodeOptions.standard)
                            var again = decode_toml(encoded)
                            same(again, again.root, jv, line)
                    except e:
                        if invalid:
                            pass
                        else:
                            failed += 1
                            if failed <= 50:
                                print("FAIL", line)
                                print(e)
            start = i + 1
        i += 1
    print("checked", checked, "failed", failed)
    if failed != 0:
        raise Error("suite failures")

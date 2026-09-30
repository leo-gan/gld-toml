from runtime.error import DecodeError
from schema.parse import parse_schema_file
from codegen.emit import emit_all


def main() raises:
    var bad = False
    try:
        _ = parse_schema_file("testdata/schema/benchmark_v2.json")
    except e:
        raise Error(String(e))
    var doc = parse_schema_file("testdata/schema/longlist.json")
    var files = emit_all(doc)
    var saw = False
    var i = 0
    while i + 1 < len(files):
        if files[i] == "LongList":
            var body = files[i + 1]
            if body.find("Optional[Box[LongList]]") >= 0:
                saw = True
        i += 2
    if not saw:
        raise Error("LongList should name itself through Box")
    try:
        _ = parse_schema_file("testdata/invalid-schema/reject.json")
    except e:
        bad = True
        if e.kind != DecodeError.KIND_SCHEMA:
            raise Error("expected schema error")
    if not bad:
        raise Error("minimum should be rejected")
    print("schema ok")

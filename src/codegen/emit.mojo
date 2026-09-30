from std.collections import List

from codegen.names import mojo_ident
from runtime.error import DecodeError
from schema.model import (
    ST_ARRAY,
    ST_BOOL,
    ST_CONST,
    ST_ENUM,
    ST_INT,
    ST_NUMBER,
    ST_OBJECT,
    ST_OPTIONAL,
    ST_REF,
    ST_STRING,
    ST_TIMESTAMP,
    ST_UNION,
    SchemaDoc,
    SchemaType,
)
from schema.scc import scc_ids


def emit_all(doc: SchemaDoc) raises DecodeError -> List[String]:
    var files = List[String]()
    var seen = List[String]()
    _emit_named(doc, doc.root, files, seen)
    var i = 0
    while i < len(doc.def_types):
        _emit_named(doc, doc.def_types[i], files, seen)
        i += 1
    return files^


def _unwrap(doc: SchemaDoc, tid: Int) -> SchemaType:
    var t = doc.types[tid].copy()
    while t.kind == ST_REF or t.kind == ST_OPTIONAL or t.kind == ST_ENUM or t.kind == ST_CONST:
        if t.inner < 0:
            break
        t = doc.types[t.inner].copy()
    return t^


def _emit_named(
    doc: SchemaDoc, tid: Int, mut files: List[String], mut seen: List[String]
) raises DecodeError:
    var ty = _unwrap(doc, tid).copy()
    if ty.kind != ST_OBJECT and ty.kind != ST_UNION:
        return
    var name = mojo_ident(ty.name)
    if name.byte_length() == 0:
        name = String("Root")
    var i = 0
    while i < len(seen):
        if seen[i] == name:
            return
        i += 1
    seen.append(name)
    if ty.kind == ST_OBJECT:
        var p = 0
        while p < len(ty.props):
            _emit_named(doc, ty.props[p].type_id, files, seen)
            p += 1
    else:
        var b = 0
        while b < len(ty.branch_ids):
            _emit_named(doc, ty.branch_ids[b], files, seen)
            b += 1
    files.append(name)
    files.append(_emit_struct(doc, ty, name, tid))


def _type_name(doc: SchemaDoc, tid: Int, scc: List[Int], self_id: Int) raises DecodeError -> String:
    var t = doc.types[tid].copy()
    if t.kind == ST_OPTIONAL:
        return "Optional[" + _type_name(doc, t.inner, scc, self_id) + "]"
    if t.kind == ST_ARRAY:
        return "List[" + _type_name(doc, t.inner, scc, self_id) + "]"
    if t.kind == ST_REF or t.kind == ST_ENUM or t.kind == ST_CONST:
        return _type_name(doc, t.inner, scc, self_id)
    if t.kind == ST_BOOL:
        return String("Bool")
    if t.kind == ST_INT:
        return String("Int64")
    if t.kind == ST_NUMBER:
        return String("Float64")
    if t.kind == ST_STRING:
        return String("String")
    if t.kind == ST_TIMESTAMP:
        return String("TomlDateTime")
    if t.kind == ST_OBJECT or t.kind == ST_UNION:
        var n = mojo_ident(t.name)
        if self_id >= 0 and tid < len(scc) and self_id < len(scc) and scc[tid] == scc[self_id]:
            return "Box[" + n + "]"
        return n
    raise DecodeError(DecodeError.KIND_SCHEMA, 0)


def _in_scc(doc: SchemaDoc, tid: Int, scc: List[Int], self_id: Int) -> Bool:
    var t = _unwrap(doc, tid).copy()
    if t.kind != ST_OBJECT and t.kind != ST_UNION:
        return False
    var id = tid
    var cur = doc.types[tid].copy()
    while cur.kind == ST_REF or cur.kind == ST_OPTIONAL:
        if cur.inner < 0:
            break
        id = cur.inner
        cur = doc.types[id].copy()
    if id >= len(scc) or self_id >= len(scc):
        return False
    return scc[id] == scc[self_id]


def _emit_struct(doc: SchemaDoc, ty: SchemaType, name: String, self_id: Int) raises DecodeError -> String:
    var scc = scc_ids(doc)
    var refs = List[String]()
    _collect_refs(doc, ty, name, refs)
    var out = String("from std.collections import List, Optional\n\n")
    out += "from runtime.box import Box\n"
    out += "from runtime.datum import TomlDatum\n"
    out += "from runtime.error import DecodeError\n"
    out += "from runtime.options import EncodeOptions\n"
    out += "from wire.doc import (\n"
    out += "    TK_ARRAY,\n    TK_DATETIME,\n    TK_FALSE,\n    TK_FLOAT,\n    TK_INT,\n"
    out += "    TK_STRING,\n    TK_TABLE,\n    TK_TRUE,\n    TomlDateTime,\n    TomlDoc,\n)\n"
    out += "from wire.writer import encode_toml\n"
    var i = 0
    while i < len(refs):
        out += "from " + refs[i] + " import " + refs[i] + "\n"
        i += 1
    out += "\nstruct " + name + "(Copyable, Movable, Defaultable, Deinitable, TomlDatum):\n"
    if ty.kind == ST_UNION:
        out += "    var tag: Int\n"
        i = 0
        while i < len(ty.branch_ids):
            var bn = mojo_ident(_unwrap(doc, ty.branch_ids[i]).name)
            var field = mojo_ident(bn)
            out += "    var " + field + ": Optional[" + bn + "]\n"
            i += 1
    else:
        i = 0
        while i < len(ty.props):
            var p = ty.props[i].copy()
            if p.required and _in_scc(doc, p.type_id, scc, self_id):
                raise DecodeError(DecodeError.KIND_SCHEMA, 0)
            var fty = _type_name(doc, p.type_id, scc, self_id)
            out += "    var " + mojo_ident(p.name) + ": " + fty + "\n"
            i += 1
    out += "\n    def __init__(out self):\n"
    if ty.kind == ST_UNION:
        out += "        self.tag = 0\n"
        i = 0
        while i < len(ty.branch_ids):
            var bn = mojo_ident(_unwrap(doc, ty.branch_ids[i]).name)
            out += "        self." + mojo_ident(bn) + " = Optional[" + bn + "]()\n"
            i += 1
    else:
        i = 0
        while i < len(ty.props):
            var p = ty.props[i].copy()
            var fname = mojo_ident(p.name)
            var fty = _type_name(doc, p.type_id, scc, self_id)
            out += "        self." + fname + " = " + _zero(fty) + "\n"
            i += 1
    out += "\n    def encoded_len(self, options: EncodeOptions) raises -> Int:\n"
    out += "        var doc = self._to_doc()\n"
    out += "        var text = encode_toml(doc, options)\n"
    out += "        return text.byte_length()\n\n"
    out += "    def encode_to(self, mut buf: List[Byte], options: EncodeOptions) raises:\n"
    out += "        var doc = self._to_doc()\n"
    out += "        var text = encode_toml(doc, options)\n"
    out += "        var raw = text.as_bytes()\n"
    out += "        var i = 0\n"
    out += "        while i < len(raw):\n"
    out += "            buf.append(raw[i])\n"
    out += "            i += 1\n\n"
    out += "    def _to_doc(self) raises -> TomlDoc:\n"
    out += "        var doc = TomlDoc()\n"
    out += "        self._fill(doc, doc.root)\n"
    out += "        return doc^\n\n"
    out += "    def _fill(self, mut doc: TomlDoc, node: Int) raises:\n"
    if ty.kind == ST_UNION:
        out += _emit_union_fill(doc, ty)
    else:
        out += _emit_fill(doc, ty, scc, self_id)
    out += "\n    def read_from(mut self, doc: TomlDoc, node: Int) raises DecodeError:\n"
    if ty.kind == ST_UNION:
        out += _emit_union_read(doc, ty)
    else:
        out += _emit_read(doc, ty, scc, self_id)
    return out


def _zero(fty: String) -> String:
    if fty == "Bool":
        return String("False")
    if fty == "Int64":
        return String("Int64(0)")
    if fty == "Float64":
        return String("Float64(0)")
    if fty == "String":
        return String("String()")
    if fty == "TomlDateTime":
        return String("TomlDateTime()")
    if fty.startswith("Optional["):
        return fty + "()"
    if fty.startswith("List["):
        return fty + "()"
    return fty + "()"


def _collect_refs(doc: SchemaDoc, ty: SchemaType, self_name: String, mut out: List[String]):
    if ty.kind == ST_OBJECT:
        var i = 0
        while i < len(ty.props):
            _collect_tid(doc, ty.props[i].type_id, self_name, out)
            i += 1
    else:
        var i = 0
        while i < len(ty.branch_ids):
            _collect_tid(doc, ty.branch_ids[i], self_name, out)
            i += 1


def _collect_tid(doc: SchemaDoc, tid: Int, self_name: String, mut out: List[String]):
    var t = doc.types[tid].copy()
    if t.kind == ST_OPTIONAL or t.kind == ST_ARRAY or t.kind == ST_REF or t.kind == ST_ENUM or t.kind == ST_CONST:
        if t.inner >= 0:
            _collect_tid(doc, t.inner, self_name, out)
        return
    if t.kind != ST_OBJECT and t.kind != ST_UNION:
        return
    var n = mojo_ident(t.name)
    if n == self_name or n.byte_length() == 0:
        return
    var j = 0
    while j < len(out):
        if out[j] == n:
            return
        j += 1
    out.append(n)


def _emit_fill(doc: SchemaDoc, ty: SchemaType, scc: List[Int], self_id: Int) raises DecodeError -> String:
    var out = String("")
    var i = 0
    while i < len(ty.props):
        var p = ty.props[i].copy()
        var fname = mojo_ident(p.name)
        var key = p.name
        out += "        var _k" + String(i) + " = doc.add_text(String(\"" + key + "\"))\n"
        out += _fill_expr(doc, "self." + fname, p.type_id, "_k" + String(i), scc, self_id, 8)
        i += 1
    if len(ty.props) == 0:
        out += "        _ = node\n"
    return out


def _fill_expr(
    doc: SchemaDoc,
    expr: String,
    tid: Int,
    keyvar: String,
    scc: List[Int],
    self_id: Int,
    pad: Int,
) raises DecodeError -> String:
    _ = scc
    _ = self_id
    var ind = String("        ")
    var t = doc.types[tid].copy()
    if t.kind == ST_OPTIONAL:
        var inner = _unwrap(doc, t.inner).copy()
        var body = String("")
        body += ind + "if " + expr + ":\n"
        body += ind + "    var _inner = " + expr + ".value().copy()\n"
        if inner.kind == ST_OBJECT or inner.kind == ST_UNION:
            var use = "_inner"
            if _in_scc(doc, t.inner, scc, self_id):
                use = "_inner[]"
            body += ind + "    var _child = doc.make_table(node)\n"
            body += ind + "    " + use + "._fill(doc, _child)\n"
            body += ind + "    doc.append_child(node, " + keyvar + ", _child)\n"
        else:
            body += _store_scalar(doc, "_inner", t.inner, keyvar, "    ")
        return body
    var u = _unwrap(doc, tid).copy()
    if u.kind == ST_OBJECT or u.kind == ST_UNION:
        var use = expr
        if _in_scc(doc, tid, scc, self_id):
            use = expr + "[]"
        var body = String("")
        body += ind + "var _child = doc.make_table(node)\n"
        body += ind + use + "._fill(doc, _child)\n"
        body += ind + "doc.append_child(node, " + keyvar + ", _child)\n"
        return body
    if u.kind == ST_ARRAY:
        return _fill_array(doc, expr, u, keyvar, scc, self_id)
    return _store_scalar(doc, expr, tid, keyvar, "")


def _store_scalar(doc: SchemaDoc, expr: String, tid: Int, keyvar: String, extra: String) -> String:
    var u = _unwrap(doc, tid).copy()
    var ind = String("        ") + extra
    if u.kind == ST_BOOL:
        return ind + "doc.append_child(node, " + keyvar + ", doc.make_bool(" + expr + ", node))\n"
    if u.kind == ST_INT:
        return ind + "doc.append_child(node, " + keyvar + ", doc.make_int(" + expr + ", node))\n"
    if u.kind == ST_NUMBER:
        return ind + "doc.append_child(node, " + keyvar + ", doc.make_float(UInt64((" + expr + ").to_bits()), node))\n"
    if u.kind == ST_STRING:
        return ind + "doc.append_child(node, " + keyvar + ", doc.make_string(String(" + expr + "), node))\n"
    if u.kind == ST_TIMESTAMP:
        return ind + "doc.append_child(node, " + keyvar + ", doc.make_datetime(" + expr + ", node))\n"
    return ind + "_ = " + expr + "\n"


def _fill_array(
    doc: SchemaDoc, expr: String, arr: SchemaType, keyvar: String, scc: List[Int], self_id: Int
) raises DecodeError -> String:
    _ = scc
    _ = self_id
    var inner = _unwrap(doc, arr.inner).copy()
    var out = String("        var _arr = doc.make_array(node)\n")
    out += "        var _i = 0\n"
    out += "        while _i < len(" + expr + "):\n"
    if inner.kind == ST_OBJECT or inner.kind == ST_UNION:
        out += "            var _el = doc.make_table(_arr)\n"
        out += "            " + expr + "[_i]._fill(doc, _el)\n"
        out += "            doc.append_child(_arr, -1, _el)\n"
    elif inner.kind == ST_INT:
        out += "            doc.append_child(_arr, -1, doc.make_int(" + expr + "[_i], _arr))\n"
    elif inner.kind == ST_NUMBER:
        out += "            doc.append_child(_arr, -1, doc.make_float(UInt64((" + expr + "[_i]).to_bits()), _arr))\n"
    elif inner.kind == ST_STRING:
        out += "            doc.append_child(_arr, -1, doc.make_string(String(" + expr + "[_i]), _arr))\n"
    elif inner.kind == ST_BOOL:
        out += "            doc.append_child(_arr, -1, doc.make_bool(" + expr + "[_i], _arr))\n"
    else:
        out += "            _ = _i\n"
    out += "            _i += 1\n"
    out += "        doc.append_child(node, " + keyvar + ", _arr)\n"
    return out


def _emit_read(doc: SchemaDoc, ty: SchemaType, scc: List[Int], self_id: Int) raises DecodeError -> String:
    var out = String("        if doc.kind(node) != TK_TABLE:\n")
    out += "            raise DecodeError(DecodeError.KIND_TYPE, 0)\n"
    var i = 0
    while i < len(ty.props):
        var p = ty.props[i].copy()
        var fname = mojo_ident(p.name)
        out += "        var _n" + String(i) + " = doc.find_key(node, \"" + p.name + "\")\n"
        if p.required:
            out += "        if _n" + String(i) + " < 0:\n"
            out += "            raise DecodeError(DecodeError.KIND_TYPE, 0)\n"
            out += _read_into(doc, "self." + fname, p.type_id, "_n" + String(i), scc, self_id, False)
        else:
            out += "        if _n" + String(i) + " < 0:\n"
            out += "            self." + fname + " = " + _zero(_type_name(doc, p.type_id, scc, self_id)) + "\n"
            out += "        else:\n"
            out += _read_into(doc, "self." + fname, p.type_id, "_n" + String(i), scc, self_id, True)
        i += 1
    if len(ty.props) == 0:
        out += "        _ = doc\n"
    return out


def _read_into(
    doc: SchemaDoc,
    dest: String,
    tid: Int,
    nvar: String,
    scc: List[Int],
    self_id: Int,
    optional: Bool,
) raises DecodeError -> String:
    var u = _unwrap(doc, tid).copy()
    var ind = String("        ")
    if optional:
        ind += "    "
    if u.kind == ST_BOOL:
        return ind + dest + " = doc.kind(" + nvar + ") == TK_TRUE\n"
    if u.kind == ST_INT:
        return ind + dest + " = doc.int_at(" + nvar + ")\n"
    if u.kind == ST_NUMBER:
        return ind + dest + " = doc.float_at(" + nvar + ")\n"
    if u.kind == ST_STRING:
        return ind + dest + " = doc.text_at(" + nvar + ")\n"
    if u.kind == ST_TIMESTAMP:
        return ind + dest + " = doc.date_at(" + nvar + ")\n"
    if u.kind == ST_ARRAY:
        return _read_array(doc, dest, u, nvar, optional)
    if u.kind == ST_OBJECT or u.kind == ST_UNION:
        var n = mojo_ident(u.name)
        var boxed = _in_scc(doc, tid, scc, self_id)
        var body = String("")
        body += ind + "var _obj = " + n + "()\n"
        body += ind + "_obj.read_from(doc, " + nvar + ")\n"
        if optional and boxed:
            body += ind + dest + " = Optional[Box[" + n + "]](Box( _obj^))\n"
        elif optional:
            body += ind + dest + " = Optional[" + n + "](_obj^)\n"
        elif boxed:
            body += ind + dest + " = Box(_obj^)\n"
        else:
            body += ind + dest + " = _obj^\n"
        return body
    return ind + "_ = " + nvar + "\n"


def _read_array(doc: SchemaDoc, dest: String, arr: SchemaType, nvar: String, optional: Bool) -> String:
    var inner = _unwrap(doc, arr.inner).copy()
    var ind = String("        ")
    if optional:
        ind += "    "
    var elem = String("Int64")
    if inner.kind == ST_BOOL:
        elem = String("Bool")
    elif inner.kind == ST_NUMBER:
        elem = String("Float64")
    elif inner.kind == ST_STRING:
        elem = String("String")
    elif inner.kind == ST_OBJECT or inner.kind == ST_UNION:
        elem = mojo_ident(inner.name)
    var out = ind + dest + " = List[" + elem + "]()\n"
    out += ind + "var _e = doc.first_edge(" + nvar + ")\n"
    out += ind + "while _e >= 0:\n"
    out += ind + "    var _c = doc.edges[_e].child\n"
    if inner.kind == ST_OBJECT or inner.kind == ST_UNION:
        out += ind + "    var _item = " + elem + "()\n"
        out += ind + "    _item.read_from(doc, _c)\n"
        out += ind + "    " + dest + ".append(_item^)\n"
    elif inner.kind == ST_INT:
        out += ind + "    " + dest + ".append(doc.int_at(_c))\n"
    elif inner.kind == ST_NUMBER:
        out += ind + "    " + dest + ".append(doc.float_at(_c))\n"
    elif inner.kind == ST_STRING:
        out += ind + "    " + dest + ".append(doc.text_at(_c))\n"
    elif inner.kind == ST_BOOL:
        out += ind + "    " + dest + ".append(doc.kind(_c) == TK_TRUE)\n"
    out += ind + "    _e = doc.edges[_e].next\n"
    return out


def _emit_union_fill(doc: SchemaDoc, ty: SchemaType) -> String:
    var out = String("        _ = node\n")
    var i = 0
    while i < len(ty.branch_ids):
        var bn = mojo_ident(_unwrap(doc, ty.branch_ids[i]).name)
        var field = mojo_ident(bn)
        out += "        if self.tag == " + String(i) + " and self." + field + ":\n"
        out += "            self." + field + ".value()._fill(doc, node)\n"
        i += 1
    return out


def _emit_union_read(doc: SchemaDoc, ty: SchemaType) -> String:
    var out = String("        if doc.kind(node) != TK_TABLE:\n")
    out += "            raise DecodeError(DecodeError.KIND_TYPE, 0)\n"
    var i = 0
    while i < len(ty.branch_ids):
        var branch = _unwrap(doc, ty.branch_ids[i]).copy()
        var bn = mojo_ident(branch.name)
        var field = mojo_ident(bn)
        out += "        var _ok" + String(i) + " = True\n"
        var p = 0
        while p < len(branch.props):
            var prop = branch.props[p].copy()
            if prop.required:
                out += "        if doc.find_key(node, \"" + prop.name + "\") < 0:\n"
                out += "            _ok" + String(i) + " = False\n"
            p += 1
        out += "        if _ok" + String(i) + ":\n"
        out += "            var _b = " + bn + "()\n"
        out += "            _b.read_from(doc, node)\n"
        out += "            self.tag = " + String(i) + "\n"
        out += "            self." + field + " = Optional[" + bn + "](_b^)\n"
        out += "            return\n"
        i += 1
    out += "        raise DecodeError(DecodeError.KIND_TYPE, 0)\n"
    return out

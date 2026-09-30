from Cat import Cat
from Document import Document
from DocumentItem import DocumentItem
from Message import Message
from Pet import Pet
from When import When
from runtime.datum import decode_text, encode_text
from wire.doc import DT_OFFSET


def main() raises:
    var m = Message()
    m.f_bool = True
    m.f_int32 = Int64(42)
    m.f_int64 = Int64(99)
    m.f_float64 = Float64(1.5)
    m.f_string = String("hi")
    m.f_bool_2 = False
    m.f_int32_2 = Int64(7)
    m.f_string_2 = String("yo")
    var back = decode_text[Message](encode_text(m))
    if back.f_int32 != Int64(42) or back.f_string != "hi" or not back.f_bool:
        raise Error("message")

    var doc = Document()
    doc.id = String("d1")
    doc.status = Int64(1)
    doc.meta.region = String("us")
    doc.meta.version = Int64(3)
    var item = DocumentItem()
    item.sku = String("a")
    item.qty = Int64(2)
    item.price_minor = Int64(50)
    doc.items.append(item^)
    var d2 = decode_text[Document](encode_text(doc))
    if d2.items[0].sku != "a" or d2.meta.region != "us":
        raise Error("document")

    var pet = Pet()
    var cat = Cat()
    cat.lives = Int64(9)
    pet.tag = 0
    pet.Cat = Optional[Cat](cat^)
    var pet2 = decode_text[Pet](encode_text(pet))
    if pet2.tag != 0 or not pet2.Cat or pet2.Cat.value().lives != Int64(9):
        raise Error("pet")

    var w = When()
    w.at.sub = DT_OFFSET
    w.at.year = 1979
    w.at.month = 5
    w.at.day = 27
    w.at.hour = 7
    w.at.minute = 32
    w.at.second = 0
    w.at.has_second = True
    w.at.offset_z = True
    var w2 = decode_text[When](encode_text(w))
    if w2.at.year != 1979 or not w2.at.offset_z:
        raise Error("when")
    print("codegen ok")

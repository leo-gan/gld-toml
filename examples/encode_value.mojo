from toml import decode_toml, encode_toml


def main() raises:
    var doc = decode_toml(
        String(
            "name = \"Tom\"\nage = 42\n\n[point]\nx = 1\ny = 2\n"
        )
    )
    print(encode_toml(doc), end="")

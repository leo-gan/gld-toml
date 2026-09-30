#!/usr/bin/env python3
"""Write a few TOML 1.0 documents and check them with tomllib.

The files are ordinary test data. tomllib is a test oracle for documents that
are valid TOML 1.0. It is not a runtime dependency and it does not accept
TOML 1.1-only syntax. The 1.1 suite is testdata/toml-test/.
"""

from __future__ import annotations

import pathlib
import tomllib

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / "testdata" / "golden"

DOCS = {
    "scalars.toml": 'name = "Tom"\nage = 42\npi = 3.14\nok = true\n',
    "table.toml": '[fruit]\napple = "red"\n\n[fruit.physical]\ncolor = "red"\n',
    "array.toml": "nums = [1, 2, 3]\n",
}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, text in DOCS.items():
        tomllib.loads(text)
        (OUT / name).write_text(text, encoding="utf-8")
        print("wrote", OUT / name)


if __name__ == "__main__":
    main()

import os
import re
import sys

DEFAULT_INPUT = "Hasel λ🐿 2.0"


def ascii_printable(value: str) -> str:
    out = []
    for ch in value:
        code = ord(ch)
        if ch == " " or 33 <= code <= 126:
            out.append(ch)
        else:
            out.append("?")
    return "".join(out)


def resolve_input() -> str:
    env_value = os.environ.get("HASEL_INPUT")
    if env_value:
        return env_value
    arg_value = " ".join(sys.argv[1:]).strip()
    return arg_value or DEFAULT_INPUT


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
    input_value = resolve_input()
    tokens = ",".join(input_value.lower().split())
    codepoints = ",".join(f"U+{ord(ch):04X}" for ch in input_value)
    rows = [
        ("input", input_value),
        ("everything", f"*{input_value}*"),
        ("regex", f".*{re.escape(input_value)}.*"),
        ("ascii_printable", ascii_printable(input_value)),
        ("contains_non_ascii", str(any(ord(ch) > 0x7F for ch in input_value)).lower()),
        ("tokens", tokens),
        ("codepoints", codepoints),
    ]
    for key, value in rows:
        print(f"{key}\t{value}")


if __name__ == "__main__":
    main()

"""Write the supported-watch list into README.md from landing/install/devices.json.

Run from anywhere:  python3 -I .github/readme/src/watch_list.py
It replaces the text between <!-- watches:start --> and <!-- watches:end -->.
"""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
DEVICES = ROOT / "landing" / "install" / "devices.json"
README = ROOT / "README.md"
START, END = "<!-- watches:start -->", "<!-- watches:end -->"

# (heading, name prefixes); the last group takes everything else.
GROUPS = [
    ("Forerunner", ("Forerunner",)),
    ("fēnix · epix · Enduro", ("fēnix", "epix", "Enduro")),
    ("Venu", ("Venu",)),
    ("vívoactive", ("vívoactive",)),
    ("Instinct", ("Instinct",)),
    ("MARQ", ("MARQ",)),
    ("D2 · Descent · Approach · Legacy editions", ()),
]


def natural(name):
    return [int(p) if p.isdigit() else p.casefold() for p in re.split(r"(\d+)", name)]


def build(devices):
    # One collapsible block per watch family, so a reader opens only their own.
    devices = sorted(devices, key=lambda d: natural(d["name"]))
    buckets = {title: [] for title, _ in GROUPS}
    for device in devices:
        for title, prefixes in GROUPS:
            if not prefixes or device["name"].startswith(prefixes):
                buckets[title].append(device)
                break
    lines = [START]
    for title, _ in GROUPS:
        group = buckets[title]
        if not group:
            continue
        lines += [
            "<details>",
            f"<summary><b>{title}</b> · {len(group)} models</summary>",
            "",
        ]
        for device in group:
            note = "" if device.get("glance") else " <sub>no glance</sub>"
            lines.append(f"- {device['name']}{note}")
        lines += ["", "</details>", ""]
    no_glance = sum(1 for d in devices if not d.get("glance"))
    lines += [
        f"The glance needs Connect IQ 4.0 or newer. On the {no_glance} watches marked <sub>no glance</sub>, "
        f"open the app from the apps list instead. The watch face and the app work on all {len(devices)}.",
        END,
    ]
    return "\n".join(lines)


def main():
    devices = json.loads(DEVICES.read_text(encoding="utf-8"))
    text = README.read_text(encoding="utf-8")
    pattern = re.compile(re.escape(START) + r".*?" + re.escape(END), re.S)
    if not pattern.search(text):
        raise SystemExit(f"Markers {START} ... {END} not found in {README}")
    README.write_text(pattern.sub(lambda _: build(devices), text), encoding="utf-8")
    print(f"{README}: {len(devices)} watches")


if __name__ == "__main__":
    main()

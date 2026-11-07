"""Rewrite the <iq:products> list in manifest.xml from the devices installed by SDK Manager.

A device is included when it supports watch apps, runs Connect IQ 3.0 or newer,
and has a color screen (at least 8 bits per pixel), so the logo looks right.
"""
import json
import os
import re
import sys

MIN_CIQ = (3, 0, 0)
MIN_BITS_PER_PIXEL = 8


def version(text):
    return tuple(int(part) for part in text.split("."))


def main(devices_dir, manifest_path):
    included, skipped = [], []
    for device_id in sorted(os.listdir(devices_dir)):
        path = os.path.join(devices_dir, device_id, "compiler.json")
        if not os.path.isfile(path):
            continue
        with open(path) as f:
            info = json.load(f)
        supports_app = any(a.get("type") == "watchApp" for a in info.get("appTypes", []))
        versions = [version(p["connectIQVersion"]) for p in info.get("partNumbers", []) if p.get("connectIQVersion")]
        new_enough = bool(versions) and max(versions) >= MIN_CIQ
        color = info.get("bitsPerPixel", 0) >= MIN_BITS_PER_PIXEL
        if supports_app and new_enough and color:
            included.append(device_id)
        elif supports_app:
            skipped.append(device_id)

    with open(manifest_path) as f:
        manifest = f.read()
    products = "\n".join('            <iq:product id="%s"/>' % d for d in included)
    manifest = re.sub(
        r"<iq:products>.*?</iq:products>",
        "<iq:products>\n%s\n        </iq:products>" % products,
        manifest,
        flags=re.S,
    )
    with open(manifest_path, "w") as f:
        f.write(manifest)
    print("included %d devices" % len(included))
    print("skipped (old or not enough colors): %s" % ", ".join(skipped))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])

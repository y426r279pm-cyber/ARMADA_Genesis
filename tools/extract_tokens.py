#!/usr/bin/env python3
"""
Tokens -> Theme.swift + Colors.xcassets

The prototype's :root block carries this comment:

    TOKENS: the single source of truth the SwiftUI, Compose, and React
    versions will share

This script takes that literally. Colours become asset-catalog colour sets so
the system can resolve them per-appearance later; metrics and fonts become
plain Swift constants.
"""

import json, os, re, sys
sys.path.insert(0, os.path.dirname(__file__))
from lib.jsscan import read_source, swift_string, banner

OUT_SWIFT = "Bridge/Sources/BridgeKit/Theme/Theme.swift"
OUT_ASSETS = "Bridge/Sources/BridgeKit/Resources/Colors.xcassets"

# Tokens that are colours; everything else is a metric or a font stack.
COLOR_TOKENS = {"bg", "surface", "surface-2", "input", "line", "text", "text-2",
                "muted", "accent", "led", "power", "warn", "crit", "info"}

# What each colour is for, so the generated file reads as documentation.
PURPOSE = {
    "bg": "The page ground behind every screen.",
    "surface": "Cards, the sidebar, raised panels.",
    "surface-2": "A panel raised above a card; table header rows.",
    "input": "Text fields, selects, the inside of a control.",
    "line": "Hairlines, card borders, table rules.",
    "text": "Primary copy.",
    "text-2": "Secondary copy; labels above values.",
    "muted": "Tertiary copy; captions, timestamps, disabled states.",
    "accent": "The deep green behind primary buttons.",
    "led": "The live green: healthy status, links, focus rings, most icons.",
    "power": "The lime power path: energy, the spine, the Bridge mark.",
    "warn": "Amber: a clock running down, a node too warm.",
    "crit": "Red: a broken seal, a node down, a failed check.",
    "info": "Blue: informational chips, neutral annotations.",
}


def camel(name):
    head, *rest = name.split("-")
    return head + "".join(p.capitalize() for p in rest)


def parse_root(css):
    block = re.search(r":root\s*\{(.*?)\}", css, re.S)
    if not block:
        raise ValueError("no :root token block found")
    tokens = []
    for line in block.group(1).splitlines():
        m = re.match(r"\s*--([a-z0-9-]+)\s*:\s*(.+?)\s*;", line)
        if m:
            tokens.append((m.group(1), m.group(2)))
    return tokens


def hex_components(value):
    h = value.lstrip("#")
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    return [f"0x{h[i:i+2].upper()}" for i in (0, 2, 4)]


def write_colorset(root, name, value):
    d = os.path.join(root, f"{name}.colorset")
    os.makedirs(d, exist_ok=True)
    r, g, b = hex_components(value)
    payload = {
        "colors": [{
            "idiom": "universal",
            "color": {
                "color-space": "srgb",
                "components": {"red": r, "green": g, "blue": b, "alpha": "1.000"},
            },
        }],
        "info": {"author": "tools/extract_tokens.py", "version": 1},
    }
    with open(os.path.join(d, "Contents.json"), "w") as fh:
        json.dump(payload, fh, indent=2)


def main():
    src = read_source()
    css = src[src.index("<style>") : src.index("</style>")]
    tokens = parse_root(css)
    colors = [(k, v) for k, v in tokens if k in COLOR_TOKENS]
    others = [(k, v) for k, v in tokens if k not in COLOR_TOKENS]

    missing = COLOR_TOKENS - {k for k, _ in colors}
    if missing:
        raise SystemExit(f"token block is missing expected colours: {sorted(missing)}")

    os.makedirs(OUT_ASSETS, exist_ok=True)
    with open(os.path.join(OUT_ASSETS, "Contents.json"), "w") as fh:
        json.dump({"info": {"author": "tools/extract_tokens.py", "version": 1}}, fh, indent=2)
    for name, value in colors:
        write_colorset(OUT_ASSETS, camel(name), value)

    radius = {k: v for k, v in others}
    L = []
    L.append(banner("tools/extract_tokens.py"))
    L.append("import SwiftUI\n")
    L.append("/// The Bridge palette, generated from the prototype's `:root` block.")
    L.append("///")
    L.append("/// Every colour resolves through the asset catalog rather than a literal, so")
    L.append("/// a future light appearance is a catalog change and not a code change.")
    L.append("public enum Theme {")
    L.append("    // MARK: Colour\n")
    for name, value in colors:
        L.append(f"    /// {PURPOSE.get(name, '')}  `{value}`")
        L.append(f"    public static let {camel(name)} = Color({swift_string(camel(name))}, bundle: .module)")
        L.append("")
    L.append("    // MARK: Metrics\n")
    for name, value in others:
        if name.startswith("radius") or name == "gap":
            num = re.match(r"([\d.]+)px", value)
            if num:
                L.append(f"    /// `{value}` in the prototype.")
                L.append(f"    public static let {camel(name)}: CGFloat = {num.group(1)}")
                L.append("")
    L.append("    // MARK: Type\n")
    L.append("    /// The prototype's body size. Treated as the Dynamic Type base rather than a fixed")
    L.append("    /// point size — see the conversion plan, section 7.")
    L.append("    public static let bodyPointSize: CGFloat = 15")
    L.append("")
    L.append("    /// The prototype's `--mono` stack resolves to SF Mono on Apple platforms.")
    L.append("    public static let mono = Font.system(.body, design: .monospaced)")
    L.append("}")

    os.makedirs(os.path.dirname(OUT_SWIFT), exist_ok=True)
    with open(OUT_SWIFT, "w") as fh:
        fh.write("\n".join(L) + "\n")

    print(f"tokens: {len(colors)} colours -> {OUT_ASSETS}")
    print(f"        {len([k for k,_ in others])} metrics/fonts -> {OUT_SWIFT}")
    for k, v in colors:
        print(f"          --{k:<10} {v}")


if __name__ == "__main__":
    main()

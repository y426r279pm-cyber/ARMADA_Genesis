#!/usr/bin/env python3
"""
ICONS -> Icons.swift

The 21 route glyphs are a deliberate monoline family and carry the branding, so
they are ported as geometry rather than swapped for SF Symbols. Each becomes a
SwiftUI View built from Path, with `var(--led)` resolving to `Theme.led` — so
the icons stay themeable, which an SVG in an asset catalog would not.
"""

import os, re, sys
sys.path.insert(0, os.path.dirname(__file__))
from lib.jsscan import read_source, strip_comments, find_block, banner

OUT = "Bridge/Sources/BridgeKit/Icons/Icons.swift"

NUM = re.compile(r"[-+]?(?:\d*\.\d+|\d+)(?:[eE][-+]?\d+)?")


def camel(name):
    head, *rest = name.split("-")
    return head + "".join(p.capitalize() for p in rest)


def token(value):
    """`var(--led)` -> `Theme.led`; `none` -> nil."""
    if not value or value == "none":
        return None
    m = re.match(r"var\(--([a-z0-9-]+)\)", value)
    if m:
        return f"Theme.{camel(m.group(1))}"
    if value.startswith("#"):
        return f'Color(hex: "{value}")'
    if value == "currentColor":
        return "Theme.text"
    raise ValueError(f"unrecognised colour {value!r}")


def attrs(tag):
    return dict(re.findall(r'([a-zA-Z-]+)="([^"]*)"', tag))


def numbers(d):
    return [float(x) for x in NUM.findall(d)]


def path_commands(d):
    """Split SVG path data into (command, [numbers]) pairs."""
    out = []
    for m in re.finditer(r"([MmLlHhVvCcSsQqTtAaZz])([^MmLlHhVvCcSsQqTtAaZz]*)", d):
        out.append((m.group(1), numbers(m.group(2))))
    return out


def emit_path(d, indent="        "):
    """SVG path data -> SwiftUI Path drawing statements.

    Only the subset the icons use is supported, and anything else raises rather
    than drawing the wrong shape quietly."""
    lines, cur, start = [], (0.0, 0.0), (0.0, 0.0)
    for cmd, n in path_commands(d):
        up = cmd.upper()
        rel = cmd.islower()
        if up == "M":
            for k in range(0, len(n), 2):
                x, y = n[k], n[k + 1]
                if rel:
                    x, y = cur[0] + x, cur[1] + y
                if k == 0:
                    lines.append(f"{indent}p.move(to: CGPoint(x: {x:g}, y: {y:g}))")
                    start = (x, y)
                else:
                    lines.append(f"{indent}p.addLine(to: CGPoint(x: {x:g}, y: {y:g}))")
                cur = (x, y)
        elif up == "L":
            for k in range(0, len(n), 2):
                x, y = n[k], n[k + 1]
                if rel:
                    x, y = cur[0] + x, cur[1] + y
                lines.append(f"{indent}p.addLine(to: CGPoint(x: {x:g}, y: {y:g}))")
                cur = (x, y)
        elif up == "H":
            for x in n:
                x = cur[0] + x if rel else x
                lines.append(f"{indent}p.addLine(to: CGPoint(x: {x:g}, y: {cur[1]:g}))")
                cur = (x, cur[1])
        elif up == "V":
            for y in n:
                y = cur[1] + y if rel else y
                lines.append(f"{indent}p.addLine(to: CGPoint(x: {cur[0]:g}, y: {y:g}))")
                cur = (cur[0], y)
        elif up == "C":
            for k in range(0, len(n), 6):
                pts = n[k : k + 6]
                if rel:
                    pts = [cur[i % 2] + v for i, v in enumerate(pts)]
                lines.append(
                    f"{indent}p.addCurve(to: CGPoint(x: {pts[4]:g}, y: {pts[5]:g}), "
                    f"control1: CGPoint(x: {pts[0]:g}, y: {pts[1]:g}), "
                    f"control2: CGPoint(x: {pts[2]:g}, y: {pts[3]:g}))")
                cur = (pts[4], pts[5])
        elif up == "Q":
            for k in range(0, len(n), 4):
                pts = n[k : k + 4]
                if rel:
                    pts = [cur[i % 2] + v for i, v in enumerate(pts)]
                lines.append(
                    f"{indent}p.addQuadCurve(to: CGPoint(x: {pts[2]:g}, y: {pts[3]:g}), "
                    f"control: CGPoint(x: {pts[0]:g}, y: {pts[1]:g}))")
                cur = (pts[2], pts[3])
        elif up == "A":
            # The icons use arcs only as circular caps (rx == ry). SwiftUI has no
            # direct elliptical-arc-to, so these are emitted as an explicit helper
            # and flagged, rather than approximated silently.
            for k in range(0, len(n), 7):
                rx, ry, rot, large, sweep, x, y = n[k : k + 7]
                if rel:
                    x, y = cur[0] + x, cur[1] + y
                lines.append(
                    f"{indent}p.addSVGArc(from: CGPoint(x: {cur[0]:g}, y: {cur[1]:g}), "
                    f"to: CGPoint(x: {x:g}, y: {y:g}), rx: {rx:g}, ry: {ry:g}, "
                    f"rotation: {rot:g}, largeArc: {str(bool(large)).lower()}, sweep: {str(bool(sweep)).lower()})")
                cur = (x, y)
        elif up == "Z":
            lines.append(f"{indent}p.closeSubpath()")
            cur = start
        else:
            raise ValueError(f"unsupported path command {cmd!r}")
    return lines


def emit_shape(tag_name, a, indent="        "):
    """A non-path SVG primitive -> SwiftUI Path statements."""
    f = lambda k, d=0.0: float(a.get(k, d))
    if tag_name == "circle":
        cx, cy, r = f("cx"), f("cy"), f("r")
        return [f"{indent}p.addEllipse(in: CGRect(x: {cx-r:g}, y: {cy-r:g}, "
                f"width: {2*r:g}, height: {2*r:g}))"]
    if tag_name == "ellipse":
        cx, cy, rx, ry = f("cx"), f("cy"), f("rx"), f("ry")
        return [f"{indent}p.addEllipse(in: CGRect(x: {cx-rx:g}, y: {cy-ry:g}, "
                f"width: {2*rx:g}, height: {2*ry:g}))"]
    if tag_name == "rect":
        x, y, w, h = f("x"), f("y"), f("width"), f("height")
        rx = f("rx", 0.0)
        rect = f"CGRect(x: {x:g}, y: {y:g}, width: {w:g}, height: {h:g})"
        if rx:
            return [f"{indent}p.addRoundedRect(in: {rect}, cornerSize: CGSize(width: {rx:g}, height: {rx:g}))"]
        return [f"{indent}p.addRect({rect})"]
    if tag_name == "line":
        return [f"{indent}p.move(to: CGPoint(x: {f('x1'):g}, y: {f('y1'):g}))",
                f"{indent}p.addLine(to: CGPoint(x: {f('x2'):g}, y: {f('y2'):g}))"]
    raise ValueError(f"unsupported element <{tag_name}>")


def parse_icon(svg):
    """An <svg> literal -> (viewBox side, [layer]) where each layer is one stroke or fill."""
    root = attrs(re.match(r"<svg([^>]*)>", svg).group(1))
    vb = [float(x) for x in root.get("viewBox", "0 0 48 48").split()]
    side = vb[2]
    layers = []
    for m in re.finditer(r"<(circle|ellipse|rect|line|path)\b([^>]*?)/?>", svg):
        tag_name, a = m.group(1), attrs(m.group(2))
        body = emit_path(a["d"]) if tag_name == "path" else emit_shape(tag_name, a)
        layers.append({
            "draw": body,
            "stroke": token(a.get("stroke")),
            "fill": token(a.get("fill")),
            "width": float(a.get("stroke-width", 1)),
            "cap": a.get("stroke-linecap", "butt"),
            "join": a.get("stroke-linejoin", "miter"),
        })
    return side, layers


def parse_mark(js, name):
    """A standalone brand mark: `const NAME = (size = n) => `<svg .../>`;`"""
    from lib.jsscan import read_string_end
    i = js.find("const " + name)
    if i < 0:
        raise ValueError(f"{name} not found")
    j = js.index("`", i)
    return parse_icon(js[j + 1 : read_string_end(js, j) - 1])


def main():
    js = strip_comments(read_source())
    block = find_block(js, "const ICONS")

    icons, unsupported = {}, []
    for m in re.finditer(r"\n  ([a-z][A-Za-z0-9_]*):\s*\(\)\s*=>\s*", block):
        name = m.group(1)
        tail = block[m.end():]
        if not tail.lstrip().startswith("`"):
            unsupported.append((name, tail.strip().split("\n")[0][:50]))
            continue
        svg = tail[tail.index("`") + 1 : tail.index("`", tail.index("`") + 1)]
        try:
            icons[name] = parse_icon(svg)
        except ValueError as err:
            unsupported.append((name, str(err)))

    L = [banner("tools/extract_icons.py"), ""]
    L.append("import SwiftUI\n")
    L.append("/// The route glyphs, ported as geometry.")
    L.append("///")
    L.append("/// These are a deliberate monoline family and carry the branding, so they are")
    L.append("/// not swapped for SF Symbols. Drawn as paths rather than shipped as SVG assets")
    L.append("/// so that `var(--led)` stays `Theme.led` and the set follows the palette.")
    L.append("public struct BridgeIcon: View {")
    L.append("    public let screen: Screen")
    L.append("    public var size: CGFloat = 40\n")
    L.append("    public init(_ screen: Screen, size: CGFloat = 40) {")
    L.append("        self.screen = screen")
    L.append("        self.size = size")
    L.append("    }\n")
    L.append("    public var body: some View {")
    L.append("        Canvas { context, bounds in")
    L.append("            let geometry = Self.geometry(for: screen)")
    L.append("            let s = min(bounds.width, bounds.height) / geometry.side")
    L.append("            let transform = CGAffineTransform(scaleX: s, y: s)")
    L.append("            for layer in geometry.layers {")
    L.append("                let path = layer.path.applying(transform)")
    L.append("                if let fill = layer.fill {")
    L.append("                    context.fill(path, with: .color(fill))")
    L.append("                }")
    L.append("                if let stroke = layer.stroke {")
    L.append("                    context.stroke(path, with: .color(stroke),")
    L.append("                                   style: StrokeStyle(lineWidth: layer.width * s,")
    L.append("                                                      lineCap: layer.cap,")
    L.append("                                                      lineJoin: layer.join))")
    L.append("                }")
    L.append("            }")
    L.append("        }")
    L.append("        .frame(width: size, height: size)")
    L.append("        .accessibilityHidden(true)")
    L.append("    }\n")

    L.append("    struct Layer {")
    L.append("        var path: Path")
    L.append("        var stroke: Color?")
    L.append("        var fill: Color?")
    L.append("        var width: CGFloat")
    L.append("        var cap: CGLineCap = .butt")
    L.append("        var join: CGLineJoin = .miter")
    L.append("    }\n")
    L.append("    /// The glyphs are drawn on a 48-unit square; the marks on 64.")
    L.append("    static func geometry(for screen: Screen) -> (side: CGFloat, layers: [Layer]) {")
    L.append("        switch screen {")

    CAP = {"butt": ".butt", "round": ".round", "square": ".square"}
    JOIN = {"miter": ".miter", "round": ".round", "bevel": ".bevel"}
    for name, (side, layers) in icons.items():
        L.append(f"        case .{name}: ({side:g}, [")
        for layer in layers:
            L.append("            Layer(path: Path { p in")
            for line in layer["draw"]:
                L.append("    " + line)
            L.append("            },")
            L.append(f"                  stroke: {layer['stroke'] or 'nil'},")
            L.append(f"                  fill: {layer['fill'] or 'nil'},")
            L.append(f"                  width: {layer['width']:g},")
            L.append(f"                  cap: {CAP.get(layer['cap'], '.butt')},")
            L.append(f"                  join: {JOIN.get(layer['join'], '.miter')}),")
        L.append("        ])")
    L.append("        case .chat: (TaylorMark.side, TaylorMark.layers)")
    L.append("        }")
    L.append("    }")
    L.append("}\n")
    for view, mark in (("BridgeMark", "BRIDGE_MARK"), ("TaylorMark", "TAYLOR_MARK")):
        side, layers = parse_mark(js, mark)
        L.append(f"/// The {'Bridge' if view == 'BridgeMark' else 'Taylor'} mark, from `{mark}` in the prototype.")
        L.append(f"public struct {view}: View {{")
        L.append("    public var size: CGFloat = 40")
        L.append("    public init(size: CGFloat = 40) { self.size = size }\n")
        L.append("    public var body: some View {")
        L.append("        Canvas { context, bounds in")
        L.append("            let s = min(bounds.width, bounds.height) / Self.side")
        L.append("            let transform = CGAffineTransform(scaleX: s, y: s)")
        L.append("            for layer in Self.layers {")
        L.append("                let path = layer.path.applying(transform)")
        L.append("                if let fill = layer.fill { context.fill(path, with: .color(fill)) }")
        L.append("                if let stroke = layer.stroke {")
        L.append("                    context.stroke(path, with: .color(stroke),")
        L.append("                                   style: StrokeStyle(lineWidth: layer.width * s,")
        L.append("                                                      lineCap: layer.cap,")
        L.append("                                                      lineJoin: layer.join))")
        L.append("                }")
        L.append("            }")
        L.append("        }")
        L.append("        .frame(width: size, height: size)")
        L.append(f'        .accessibilityLabel("{"Bridge" if view == "BridgeMark" else "Taylor"}")')
        L.append("    }\n")
        L.append(f"    static let side: CGFloat = {side:g}")
        L.append("    typealias Layer = BridgeIcon.Layer")
        L.append("    static let layers: [Layer] = [")
        for layer in layers:
            L.append("        Layer(path: Path { p in")
            for line in layer["draw"]:
                L.append(line)
            L.append("        },")
            L.append(f"              stroke: {layer['stroke'] or 'nil'},")
            L.append(f"              fill: {layer['fill'] or 'nil'},")
            L.append(f"              width: {layer['width']:g},")
            L.append(f"              cap: {CAP.get(layer['cap'], '.butt')},")
            L.append(f"              join: {JOIN.get(layer['join'], '.miter')}),")
        L.append("    ]")
        L.append("}\n")
    L.append("extension Path {")
    L.append("    /// SVG's elliptical arc, which SwiftUI has no direct equivalent for.")
    L.append("    ///")
    L.append("    /// Implemented by centre-parameterisation per the SVG specification, appendix")
    L.append("    /// F.6. The prototype uses it for the storage cylinder and the chain links.")
    L.append("    mutating func addSVGArc(from: CGPoint, to: CGPoint, rx: CGFloat, ry: CGFloat,")
    L.append("                            rotation: CGFloat, largeArc: Bool, sweep: Bool) {")
    L.append("        guard rx != 0, ry != 0 else { addLine(to: to); return }")
    L.append("        let phi = rotation * .pi / 180")
    L.append("        let dx2 = (from.x - to.x) / 2, dy2 = (from.y - to.y) / 2")
    L.append("        let x1 =  cos(phi) * dx2 + sin(phi) * dy2")
    L.append("        let y1 = -sin(phi) * dx2 + cos(phi) * dy2")
    L.append("        var rx = abs(rx), ry = abs(ry)")
    L.append("        let lambda = (x1 * x1) / (rx * rx) + (y1 * y1) / (ry * ry)")
    L.append("        if lambda > 1 { rx *= sqrt(lambda); ry *= sqrt(lambda) }")
    L.append("        let sign: CGFloat = largeArc == sweep ? -1 : 1")
    L.append("        let num = max(0, rx*rx * ry*ry - rx*rx * y1*y1 - ry*ry * x1*x1)")
    L.append("        let den = rx*rx * y1*y1 + ry*ry * x1*x1")
    L.append("        let coef = sign * sqrt(den == 0 ? 0 : num / den)")
    L.append("        let cx1 =  coef * rx * y1 / ry")
    L.append("        let cy1 = -coef * ry * x1 / rx")
    L.append("        let cx = cos(phi) * cx1 - sin(phi) * cy1 + (from.x + to.x) / 2")
    L.append("        let cy = sin(phi) * cx1 + cos(phi) * cy1 + (from.y + to.y) / 2")
    L.append("        let start = atan2((y1 - cy1) / ry, (x1 - cx1) / rx)")
    L.append("        let end   = atan2((-y1 - cy1) / ry, (-x1 - cx1) / rx)")
    L.append("        var delta = end - start")
    L.append("        if !sweep && delta > 0 { delta -= 2 * .pi }")
    L.append("        if sweep && delta < 0 { delta += 2 * .pi }")
    L.append("        var transform = CGAffineTransform(translationX: cx, y: cy)")
    L.append("            .rotated(by: phi)")
    L.append("            .scaledBy(x: rx, y: ry)")
    L.append("        addArc(center: .zero, radius: 1, startAngle: .radians(start),")
    L.append("               endAngle: .radians(start + delta), clockwise: delta < 0,")
    L.append("               transform: transform)")
    L.append("    }")
    L.append("}")

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write("\n".join(L) + "\n")

    total_layers = sum(len(v[1]) for v in icons.values())
    print(f"icons: {len(icons)} glyphs, {total_layers} layers -> {OUT}")
    print(f"       plus BridgeMark and TaylorMark; chat routes to TaylorMark")
    leftover = [u for u in unsupported if u[0] != "chat"]
    if leftover:
        print(f"       {len(leftover)} not ported as geometry:")
        for name, why in leftover:
            print(f"         {name}: {why}")


if __name__ == "__main__":
    main()

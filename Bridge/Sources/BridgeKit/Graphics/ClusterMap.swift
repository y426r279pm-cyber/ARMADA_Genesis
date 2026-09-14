import SwiftUI

/// The cluster health map.
///
/// Three summary rings, then the octets: each node a tile carrying its status
/// colour, a temperature bar and a memory bar. Tapping a tile opens that node.
///
/// The prototype draws this as one 800-unit SVG with everything placed by
/// coordinate. Here the tiles are real views in a grid, so they are focusable,
/// tappable and legible to VoiceOver — a diagram nobody can select is a picture
/// of a cluster rather than a way into one.
struct ClusterMap: View {
    var nodes: [ClusterNode]
    var onOpen: (String) -> Void

    /// The admin node is the one with a bare `N<digits>` id; everything else
    /// groups by the first letter of its id.
    private var admin: ClusterNode? {
        nodes.first { $0.id.range(of: #"^N\d+$"#, options: .regularExpression) != nil }
    }

    private var octets: [(key: String, nodes: [ClusterNode])] {
        var groups: [String: [ClusterNode]] = [:]
        var order: [String] = []
        for node in nodes where node.id != admin?.id {
            let key = String(node.id.prefix(1))
            if groups[key] == nil { order.append(key) }
            groups[key, default: []].append(node)
        }
        return order.map { ($0, groups[$0] ?? []) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            summaryRings
            ForEach(octets, id: \.key) { octet in
                let caption = Self.label(for: octet.key, nodes: octet.nodes)
                VStack(alignment: .leading, spacing: 8) {
                    Text(caption.title).font(.footnote.bold()).foregroundStyle(Theme.text2)
                    tiles(octet.nodes)
                    Text(caption.subtitle).font(.caption2).foregroundStyle(Theme.muted)
                }
            }
            if let admin {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(admin.id) · \(L("admin + spare"))")
                        .font(.footnote.bold()).foregroundStyle(Theme.text2)
                    HStack(spacing: 10) {
                        NodeTile(node: admin, onOpen: onOpen)
                        Text(admin.role).font(.caption2).foregroundStyle(Theme.muted)
                    }
                }
            }
            legend
        }
    }

    private func tiles(_ nodes: [ClusterNode]) -> some View {
        // Wraps rather than overflowing: eight tiles fit a Mac window and rewrap
        // on an iPad in portrait.
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 56, maximum: 62), spacing: 6)],
                  alignment: .leading, spacing: 6) {
            ForEach(nodes, id: \.id) { NodeTile(node: $0, onOpen: onOpen) }
        }
    }

    private var summaryRings: some View {
        let online = nodes.filter { $0.status != "down" }.count
        let avgTemp = nodes.isEmpty ? 0
            : Int((Double(nodes.reduce(0) { $0 + $1.tempC }) / Double(nodes.count)).rounded())
        let avgMem = nodes.isEmpty ? 0
            : Int((Double(nodes.reduce(0) { $0 + $1.memGB }) / Double(nodes.count) / 256 * 100).rounded())
        return HStack(spacing: 18) {
            SummaryRing(share: nodes.isEmpty ? 0 : Double(online) / Double(nodes.count),
                        color: online == nodes.count ? Theme.led : Theme.warn,
                        value: "\(online)/\(nodes.count)", caption: L("online"))
            SummaryRing(share: Double(avgTemp) / 100,
                        color: avgTemp >= 75 ? Theme.warn : Theme.led,
                        value: "\(avgTemp)°", caption: L("avg temp"))
            SummaryRing(share: Double(avgMem) / 100,
                        color: avgMem > 90 ? Theme.warn : Theme.info,
                        value: "\(avgMem)%", caption: L("memory"))
        }
    }

    private var legend: some View {
        HStack(spacing: 16) {
            legendItem(Theme.led, L("temperature bar"), square: true)
            legendItem(Theme.info, L("memory bar"), square: true)
            legendItem(Theme.led, "ok")
            legendItem(Theme.warn, L("warm or draining"))
            legendItem(Theme.crit, L("down"))
        }
        .font(.caption2).foregroundStyle(Theme.muted)
    }

    private func legendItem(_ color: Color, _ text: String, square: Bool = false) -> some View {
        HStack(spacing: 5) {
            Group {
                if square { RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 8, height: 10) }
                else { Circle().fill(color).frame(width: 7, height: 7) }
            }
            Text(text)
        }
    }

    /// What an octet is called, and what it is for.
    ///
    /// Kimi is one instance sharded across eight; Llama is eight independent
    /// instances. The difference matters operationally and the map says so.
    static func label(for key: String, nodes: [ClusterNode]) -> (title: String, subtitle: String) {
        let role = nodes.first?.role ?? ""
        if key == "K" || role.range(of: "kimi", options: .caseInsensitive) != nil {
            return (L("Kimi octet · one instance sharded across 8"), L("escalation brain"))
        }
        if key == "L" || role.range(of: "llama", options: .caseInsensitive) != nil {
            return (L("Llama octet · 8 independent instances"), L("staff GPT and routine agents"))
        }
        if role.range(of: "replica", options: .caseInsensitive) != nil {
            return (L("Replica nodes"), L("recovery copy"))
        }
        return ("\(L("Octet")) \(key)", role)
    }
}

/// One node in the map.
struct NodeTile: View {
    var node: ClusterNode
    var onOpen: (String) -> Void

    var body: some View {
        Button { onOpen(node.id) } label: {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text(node.id).font(.caption.bold()).foregroundStyle(Theme.text)
                    Circle().fill(node.statusColor).frame(width: 7, height: 7)
                }
                HStack(alignment: .bottom, spacing: 4) {
                    bar(share: Gfx.clamp((Double(node.tempC) - 30) / 60, 0, 1), color: tempColor)
                    bar(share: Gfx.clamp(Double(node.memGB) / 256, 0, 1), color: Theme.info)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(node.tempC)°")
                        Text("\(node.memGB)G")
                    }
                    .font(.system(size: 8)).foregroundStyle(Theme.muted)
                }
                .frame(height: 32)
            }
            .padding(6)
            .frame(width: 56, height: 64)
            .background(Theme.surface2, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8)
                .stroke(node.statusColor, lineWidth: node.status == "ok" ? 1 : 2))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(L("Node")) \(node.id)")
        .accessibilityValue("\(node.role), \(node.tempC) °C, \(node.memGB) GB, \(node.status)")
        .accessibilityHint(L("Opens the node"))
    }

    private var tempColor: Color {
        node.tempC >= 80 ? Theme.crit : node.tempC >= 70 ? Theme.warn : Theme.led
    }

    private func bar(share: Double, color: Color) -> some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 2).fill(Theme.bg).frame(width: 8, height: 32)
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 8, height: 32 * share)
        }
    }
}

/// One of the three rings above the map.
struct SummaryRing: View {
    var share: Double
    var color: Color
    var value: String
    var caption: String

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Canvas { context, _ in
                    Gfx.ring(context, cx: 30, cy: 30, r: 24, width: 7,
                             share: max(share, 0.001), color: color)
                }
                .frame(width: 60, height: 60)
                Text(value).font(.footnote.bold()).foregroundStyle(Theme.text)
            }
            Text(caption).font(.caption2).foregroundStyle(Theme.muted)
        }
        .accessibilityElement()
        .accessibilityLabel(caption)
        .accessibilityValue(value)
    }
}

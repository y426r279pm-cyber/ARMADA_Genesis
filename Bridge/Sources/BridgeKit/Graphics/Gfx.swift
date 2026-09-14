import SwiftUI

/// The prototype's `Gfx` module, drawn with `Canvas` instead of SVG.
///
/// These were already parametric drawing functions — `arc(cx, cy, r, a0, a1)`,
/// `battery(pct)`, `thermo(tempC)` — so they translate closely. Two differences
/// are deliberate: colour comes from `Theme` rather than a CSS variable, so the
/// set follows the palette; and text is laid out by SwiftUI rather than placed
/// at an SVG coordinate, so it respects Dynamic Type.
///
/// Each view draws on the prototype's own viewBox and scales, so the geometry
/// below can be compared against the source line by line.
enum Gfx {

    /// Degrees, clockwise, zero at three o'clock — the SVG convention the
    /// prototype's `arc` uses. SwiftUI's `Angle` agrees, which spares a
    /// conversion that would be easy to get wrong in only some places.
    static func arc(_ path: inout Path, cx: Double, cy: Double, r: Double,
                    from a0: Double, to a1: Double) {
        path.addArc(center: CGPoint(x: cx, y: cy), radius: r,
                    startAngle: .degrees(a0), endAngle: .degrees(a1), clockwise: false)
    }

    static func clamp(_ n: Double, _ lo: Double, _ hi: Double) -> Double { min(hi, max(lo, n)) }

    /// A ring that fills clockwise from twelve o'clock.
    static func ring(_ context: GraphicsContext, cx: Double, cy: Double, r: Double,
                     width: Double, share: Double, color: Color, track: Color = Theme.surface2) {
        var back = Path()
        back.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        context.stroke(back, with: .color(track), style: StrokeStyle(lineWidth: width))
        guard share > 0 else { return }
        var front = Path()
        arc(&front, cx: cx, cy: cy, r: r, from: -90, to: -90 + 359.9 * clamp(share, 0, 1))
        context.stroke(front, with: .color(color),
                       style: StrokeStyle(lineWidth: width, lineCap: .round))
    }
}

// MARK: - Energy

/// The solar array: a sun over a half-circle gauge sweeping to the array's peak.
struct SolarGauge: View {
    var kW: Double
    var peakKW: Double = Energy.peakKW

    var body: some View {
        let share = Gfx.clamp(kW / peakKW, 0, 1)
        VStack(spacing: 2) {
            Canvas { context, _ in
                var track = Path()
                Gfx.arc(&track, cx: 60, cy: 62, r: 46, from: 180, to: 360)
                context.stroke(track, with: .color(Theme.surface2),
                               style: StrokeStyle(lineWidth: 8, lineCap: .round))

                if share > 0 {
                    var fill = Path()
                    Gfx.arc(&fill, cx: 60, cy: 62, r: 46, from: 180, to: 180 + 180 * share)
                    context.stroke(fill, with: .color(Theme.power),
                                   style: StrokeStyle(lineWidth: 8, lineCap: .round))
                }

                var rays = Path()
                for i in 0..<8 {
                    let a = Double(i) * 45 * .pi / 180
                    rays.move(to: CGPoint(x: 60 + 17 * cos(a), y: 44 + 17 * sin(a)))
                    rays.addLine(to: CGPoint(x: 60 + 23 * cos(a), y: 44 + 23 * sin(a)))
                }
                context.stroke(rays, with: .color(Theme.power),
                               style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

                var disc = Path()
                disc.addEllipse(in: CGRect(x: 49, y: 33, width: 22, height: 22))
                context.fill(disc, with: .color(Theme.power))
            }
            .frame(width: 120, height: 70)

            HStack {
                Text("0")
                Spacer()
                Text("\(peakKW, specifier: "%.1f") kW")
            }
            .font(.caption2).foregroundStyle(Theme.muted)
            .frame(width: 110)
        }
        .accessibilityElement()
        .accessibilityLabel(L("Solar"))
        .accessibilityValue("\(String(format: "%.1f", kW)) kW")
    }
}

/// The bank: a cell that fills to the percentage, with a tick at the reserve floor.
struct BatteryGauge: View {
    var percent: Int
    var reservePercent: Int = 20

    var color: Color {
        let p = Double(percent)
        return p <= Double(reservePercent) ? Theme.crit : p < 40 ? Theme.warn : Theme.led
    }

    var body: some View {
        let p = Gfx.clamp(Double(percent), 0, 100)
        let tickX = 18 + 84 * Gfx.clamp(Double(reservePercent), 0, 100) / 100
        VStack(spacing: 2) {
            Canvas { context, _ in
                let shell = Path(roundedRect: CGRect(x: 16, y: 26, width: 88, height: 34),
                                 cornerRadius: 6)
                context.stroke(shell, with: .color(Theme.text2), style: StrokeStyle(lineWidth: 2.5))

                let cap = Path(roundedRect: CGRect(x: 104, y: 36, width: 6, height: 14), cornerRadius: 2)
                context.fill(cap, with: .color(Theme.text2))

                if p > 0 {
                    let fill = Path(roundedRect: CGRect(x: 18, y: 28, width: 84 * p / 100, height: 30),
                                    cornerRadius: 4)
                    context.fill(fill, with: .color(color))
                }

                var tick = Path()
                tick.move(to: CGPoint(x: tickX, y: 22))
                tick.addLine(to: CGPoint(x: tickX, y: 64))
                context.stroke(tick, with: .color(Theme.warn),
                               style: StrokeStyle(lineWidth: 2, dash: [3, 2]))
            }
            .frame(width: 120, height: 66)

            Text("\(L("floor")) \(reservePercent)%")
                .font(.caption2).foregroundStyle(Theme.warn)
        }
        .accessibilityElement()
        .accessibilityLabel(L("Battery"))
        .accessibilityValue("\(percent)%")
    }
}

/// The grid tie: a pylon, the rack, and the switch between them.
struct GridGauge: View {
    /// `standby`, `importing`, or `islanded`.
    var state: String

    var body: some View {
        let islanded = state == "islanded"
        let importing = state == "importing"
        VStack(spacing: 2) {
            Canvas { context, _ in
                var pylon = Path()
                pylon.move(to: CGPoint(x: 14, y: 66))
                pylon.addLine(to: CGPoint(x: 22, y: 18))
                pylon.addLine(to: CGPoint(x: 30, y: 18))
                pylon.addLine(to: CGPoint(x: 38, y: 66))
                for (y, x0, x1) in [(34.0, 12.0, 40.0), (48.0, 15.0, 37.0), (24.0, 18.0, 34.0)] {
                    pylon.move(to: CGPoint(x: x0, y: y))
                    pylon.addLine(to: CGPoint(x: x1, y: y))
                }
                context.stroke(pylon, with: .color(Theme.text2),
                               style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

                let rack = Path(roundedRect: CGRect(x: 86, y: 26, width: 24, height: 40), cornerRadius: 4)
                context.stroke(rack, with: .color(Theme.text2), style: StrokeStyle(lineWidth: 2.5))
                for y in [32.0, 41.0, 50.0] {
                    context.fill(Path(roundedRect: CGRect(x: 91, y: y, width: 14, height: 5),
                                      cornerRadius: 1), with: .color(Theme.led))
                }

                if islanded {
                    var open = Path()
                    open.move(to: CGPoint(x: 40, y: 46)); open.addLine(to: CGPoint(x: 60, y: 46))
                    open.move(to: CGPoint(x: 60, y: 46)); open.addLine(to: CGPoint(x: 76, y: 32))
                    open.move(to: CGPoint(x: 78, y: 46)); open.addLine(to: CGPoint(x: 86, y: 46))
                    context.stroke(open, with: .color(Theme.warn),
                                   style: StrokeStyle(lineWidth: 3, lineCap: .round))
                } else {
                    var line = Path()
                    line.move(to: CGPoint(x: 40, y: 46)); line.addLine(to: CGPoint(x: 86, y: 46))
                    context.stroke(line, with: .color(importing ? Theme.led : Theme.muted),
                                   style: StrokeStyle(lineWidth: importing ? 3 : 2.5,
                                                      lineCap: .round,
                                                      dash: importing ? [] : [4, 4]))
                }
            }
            .frame(width: 120, height: 66)

            Text(caption)
                .font(.caption2)
                .foregroundStyle(islanded ? Theme.warn : Theme.muted)
        }
        .accessibilityElement()
        .accessibilityLabel(L("Grid"))
        .accessibilityValue(caption)
    }

    private var caption: String {
        switch state {
        case "islanded": L("switch open")
        case "importing": L("importing")
        default: L("connected, unused")
        }
    }
}

/// The UPS: minutes of bridge remaining, with a bolt.
struct UPSGauge: View {
    var minutes: Int
    var ratedMinutes: Double = Energy.upsRatedMin

    var body: some View {
        let share = Gfx.clamp(Double(minutes) / ratedMinutes, 0, 1)
        let color: Color = share < 0.34 ? Theme.crit : share < 0.67 ? Theme.warn : Theme.led
        VStack(spacing: 2) {
            Canvas { context, _ in
                Gfx.ring(context, cx: 60, cy: 42, r: 28, width: 7, share: share, color: color)
                var bolt = Path()
                bolt.move(to: CGPoint(x: 63, y: 26))
                for point in [(52.0, 45.0), (60.0, 45.0), (57.0, 58.0), (69.0, 38.0), (61.0, 38.0)] {
                    bolt.addLine(to: CGPoint(x: point.0, y: point.1))
                }
                bolt.closeSubpath()
                context.fill(bolt, with: .color(color))
            }
            .frame(width: 120, height: 72)

            Text("\(minutes) / \(Int(ratedMinutes)) min")
                .font(.caption2).foregroundStyle(Theme.muted)
        }
        .accessibilityElement()
        .accessibilityLabel("UPS")
        .accessibilityValue("\(minutes) min")
    }
}

/// The power spine: solar to bank to rack, with the grid switch at the end.
struct PowerSpine: View {
    var power: PowerReading

    var body: some View {
        HStack(spacing: 0) {
            node(label: String(format: "%.1f kW", power.solarKW)) {
                Circle().fill(Theme.power).frame(width: 18, height: 18)
            }
            connector(Theme.power, dashed: false)
            node(label: "\(power.batteryPct)%") {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Theme.text2, lineWidth: 2).frame(width: 36, height: 16)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.led)
                        .frame(width: 32 * Gfx.clamp(Double(power.batteryPct), 0, 100) / 100, height: 12)
                        .padding(.leading, 2)
                }
                .frame(width: 36, height: 16)
            }
            connector(Theme.led, dashed: false)
            node(label: "rack") {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Theme.text2, lineWidth: 2).frame(width: 26, height: 24)
            }
            connector(power.islanded ? Theme.warn : Theme.muted, dashed: !power.islanded)
            node(label: power.islanded ? L("grid open") : L("grid standby"),
                 tint: power.islanded ? Theme.warn : Theme.muted) {
                Image(systemName: power.islanded ? "bolt.horizontal.circle" : "bolt.horizontal")
                    .foregroundStyle(power.islanded ? Theme.warn : Theme.muted)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L("Power spine"))
    }

    private func node(label: String, tint: Color = Theme.muted,
                      @ViewBuilder glyph: () -> some View) -> some View {
        VStack(spacing: 6) {
            glyph().frame(height: 24)
            Text(label).font(.caption2).foregroundStyle(tint).fixedSize()
        }
    }

    private func connector(_ color: Color, dashed: Bool) -> some View {
        HorizontalRule()
            .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round,
                                              dash: dashed ? [4, 4] : []))
            .frame(height: 3)
            .frame(minWidth: 24, maxWidth: .infinity)
            .padding(.bottom, 18)   // sits level with the glyphs, above their labels
    }
}

/// A line across whatever width it is given.
struct HorizontalRule: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

// MARK: - Node glyphs

/// A thermometer that fills with the temperature.
struct Thermometer: View {
    var celsius: Int

    var body: some View {
        let share = Gfx.clamp((Double(celsius) - 30) / 60, 0, 1)
        let color: Color = celsius >= 80 ? Theme.crit : celsius >= 70 ? Theme.warn : Theme.led
        Canvas { context, _ in
            let stem = Path(roundedRect: CGRect(x: 19, y: 6, width: 10, height: 26), cornerRadius: 5)
            context.stroke(stem, with: .color(Theme.text2), style: StrokeStyle(lineWidth: 2.5))
            var bulb = Path()
            bulb.addEllipse(in: CGRect(x: 17, y: 30, width: 14, height: 14))
            context.fill(bulb, with: .color(color))
            let fill = Path(CGRect(x: 22, y: 30 - 22 * share, width: 4, height: 22 * share + 2))
            context.fill(fill, with: .color(color))
        }
        .frame(width: 40, height: 48)
        .accessibilityLabel("\(celsius) °C")
    }
}

/// A ring showing the share of memory in use.
struct MemoryRing: View {
    var usedGB: Int
    var totalGB: Int = 256

    var body: some View {
        let share = Gfx.clamp(Double(usedGB) / Double(totalGB), 0, 1)
        let color: Color = share > 0.92 ? Theme.crit : share > 0.85 ? Theme.warn : Theme.info
        ZStack {
            Canvas { context, _ in
                Gfx.ring(context, cx: 24, cy: 24, r: 17, width: 6, share: share, color: color)
            }
            Text("\(Int((share * 100).rounded()))")
                .font(.caption.bold()).foregroundStyle(Theme.text)
        }
        .frame(width: 48, height: 48)
        .accessibilityLabel(L("Memory"))
        .accessibilityValue("\(Int((share * 100).rounded()))%")
    }
}

/// A ring showing the used share of cluster storage.
struct StorageRing: View {
    var percent: Double

    var body: some View {
        let share = Gfx.clamp(percent, 0, 100) / 100
        let color: Color = share > 0.85 ? Theme.crit : share > 0.7 ? Theme.warn : Theme.led
        Canvas { context, _ in
            Gfx.ring(context, cx: 40, cy: 40, r: 30, width: 9, share: share, color: color)
            var cyl = Path()
            cyl.addEllipse(in: CGRect(x: 29, y: 30, width: 22, height: 8))
            cyl.move(to: CGPoint(x: 29, y: 34))
            cyl.addLine(to: CGPoint(x: 29, y: 46))
            cyl.move(to: CGPoint(x: 51, y: 34))
            cyl.addLine(to: CGPoint(x: 51, y: 46))
            context.stroke(cyl, with: .color(Theme.text2), style: StrokeStyle(lineWidth: 2.5))
        }
        .frame(width: 72, height: 72)
        .accessibilityLabel(L("Storage"))
        .accessibilityValue("\(Int(percent.rounded()))%")
    }
}

/// The status colour a node carries everywhere it appears.
extension ClusterNode {
    var statusColor: Color {
        switch status {
        case "down": Theme.crit
        case "warn", "draining": Theme.warn
        default: Theme.led
        }
    }
}

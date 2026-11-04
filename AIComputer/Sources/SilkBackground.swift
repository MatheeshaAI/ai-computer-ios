import SwiftUI

/// One flowing "silk" ribbon: many thin lines that fold over each other.
struct Ribbon {
    var y: Double, a: Double, f: Double, s: Double, p: Double
    var a2: Double, f2: Double, w: Double, tf: Double, ts: Double
    var rot: Double, hue: Double, alpha: Double, n: Int
}

enum SilkPreset {
    static let welcome: [Ribbon] = [
        Ribbon(y: 0.36, a: 0.16, f: 3.2, s: 0.18, p: 0, a2: 0.05, f2: 6, w: 0.24, tf: 2.4, ts: 0.22, rot: -0.75, hue: 168, alpha: 0.05, n: 46),
        Ribbon(y: 0.62, a: 0.12, f: 2.4, s: -0.14, p: 2, a2: 0.04, f2: 5, w: 0.16, tf: 3, ts: 0.18, rot: 0.35, hue: 175, alpha: 0.04, n: 36),
    ]
    static let desktop: [Ribbon] = [
        Ribbon(y: 0.5, a: 0.18, f: 2.6, s: 0.16, p: 1, a2: 0.05, f2: 5, w: 0.26, tf: 2.2, ts: 0.2, rot: -1.0, hue: 170, alpha: 0.05, n: 44),
        Ribbon(y: 0.7, a: 0.1, f: 3.4, s: -0.12, p: 3, a2: 0.03, f2: 7, w: 0.14, tf: 3.2, ts: 0.16, rot: -0.2, hue: 176, alpha: 0.035, n: 30),
    ]
}

struct SilkBackground: View {
    var ribbons: [Ribbon]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let t = reduceMotion ? 8.0 : timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600)
                SilkBackground.draw(in: &context, size: size, t: t, ribbons: ribbons)
            }
        }
        .background(
            RadialGradient(colors: [Color(hex: 0x0C2422), Color(hex: 0x071312), Color(hex: 0x030606)],
                           center: UnitPoint(x: 0.62, y: 0.4), startRadius: 0, endRadius: 700)
        )
        .overlay(
            RadialGradient(colors: [.clear, .black.opacity(0.55)], center: .center, startRadius: 150, endRadius: 650)
        )
        .allowsHitTesting(false)
    }

    static func draw(in context: inout GraphicsContext, size: CGSize, t: Double, ribbons: [Ribbon]) {
        let L = Double(hypot(size.width, size.height))
        guard L > 0 else { return }
        let step = max(8.0, L / 90.0)
        context.blendMode = .plusLighter

        for r in ribbons {
            var g = context
            g.translateBy(x: size.width / 2, y: size.height / 2)
            g.rotate(by: .radians(r.rot))
            g.translateBy(x: -L / 2, y: -L / 2)

            func base(_ nx: Double) -> Double {
                r.y + r.a * sin(nx * r.f + t * r.s + r.p) + r.a2 * sin(nx * r.f2 - t * r.s * 0.7 + r.p)
            }

            // soft glow under the ribbon
            var glow = Path()
            var x = 0.0
            while x <= L + step {
                let y = (0.5 + (base(x / L) - 0.5) * 0.9) * L * 0.62 + L * 0.19
                if x == 0 { glow.move(to: CGPoint(x: x, y: y)) } else { glow.addLine(to: CGPoint(x: x, y: y)) }
                x += step
            }
            g.stroke(glow, with: .color(Color(hue: r.hue / 360, saturation: 0.8, brightness: 0.6).opacity(r.alpha * 0.8)), lineWidth: L * 0.05)

            for i in 0..<r.n {
                let u = Double(i) / Double(r.n - 1) - 0.5
                var path = Path()
                var x = 0.0
                while x <= L + step {
                    let nx = x / L
                    let twist = sin(nx * r.tf + t * r.ts + r.p * 1.3)
                    let y = (0.5 + (base(nx) - 0.5) * 0.9 + u * r.w * twist) * L * 0.62 + L * 0.19
                    if x == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
                    x += step
                }
                let edge = abs(u) * 2
                let color = Color(hue: (r.hue + u * 14) / 360, saturation: 0.75, brightness: min(1, 0.7 + edge * 0.25))
                g.stroke(path, with: .color(color.opacity(min(1, r.alpha * 2.9 * (0.4 + edge * 1.2)))), lineWidth: 1.5)
            }
        }
    }
}

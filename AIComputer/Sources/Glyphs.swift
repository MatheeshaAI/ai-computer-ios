import SwiftUI

/// Colourful app icons used on Home, Desktop and the MCP list (generic shapes, no brand logos).
enum Glyph {
    case folder, globe, terminal, code, trash, gear, grid, logo, robot
    case repo, filesystem, web, database, page
}

struct GlyphView: View {
    var glyph: Glyph
    var size: CGFloat = 44

    var body: some View {
        Group {
            switch glyph {
            case .folder:
                Image(systemName: "folder.fill")
                    .font(.system(size: size * 0.82))
                    .foregroundStyle(LinearGradient(colors: [Color(hex: 0x5CC8FF), Color(hex: 0x1E8CF0)], startPoint: .top, endPoint: .bottom))
            case .globe:
                ZStack {
                    Circle().fill(RadialGradient(colors: [Color(hex: 0x5FB6FF), Color(hex: 0x2172E0), Color(hex: 0x0F3F9A)], center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: size * 0.6))
                    Image(systemName: "globe")
                        .font(.system(size: size * 0.86, weight: .light))
                        .foregroundStyle(Color(hex: 0xDFF1FF).opacity(0.9))
                }
                .frame(width: size * 0.86, height: size * 0.86)
            case .terminal:
                RoundedRectangle(cornerRadius: size * 0.2, style: .continuous)
                    .fill(Color(hex: 0x0B0F10))
                    .overlay(RoundedRectangle(cornerRadius: size * 0.2, style: .continuous).stroke(Color(hex: 0xA9B4B6), lineWidth: 1.4))
                    .overlay(alignment: .center) {
                        Text(">_").font(.system(size: size * 0.38, weight: .bold, design: .monospaced)).foregroundStyle(.white)
                    }
                    .frame(width: size * 0.84, height: size * 0.76)
            case .code:
                tile(LinearGradient(colors: [Color(hex: 0x3BB0F5), Color(hex: 0x0B62B8)], startPoint: .topLeading, endPoint: .bottomTrailing),
                     symbol: "chevron.left.forwardslash.chevron.right", color: .white, scale: 0.4)
            case .trash:
                Image(systemName: "trash.fill")
                    .font(.system(size: size * 0.72))
                    .foregroundStyle(LinearGradient(colors: [Color(hex: 0xE3E9EA), Color(hex: 0x8B9799)], startPoint: .top, endPoint: .bottom))
            case .gear:
                tile(LinearGradient(colors: [Color(hex: 0x2A3D47), Color(hex: 0x18242B)], startPoint: .top, endPoint: .bottom),
                     symbol: "gearshape", color: Color(hex: 0x86D0EE), scale: 0.5)
            case .grid:
                tile(LinearGradient(colors: [Color(hex: 0x173A43), Color(hex: 0x173A43)], startPoint: .top, endPoint: .bottom),
                     symbol: "square.grid.2x2.fill", color: Color(hex: 0x3FCBE0), scale: 0.48)
            case .logo:
                tile(LinearGradient(colors: [Color(hex: 0x16514B), Color(hex: 0x0A1D1C)], startPoint: .topLeading, endPoint: .bottomTrailing),
                     symbol: "sparkle", color: Color(hex: 0x5FF0D6), scale: 0.46)
            case .robot:
                RobotGlyph(size: size)
            case .repo:
                ZStack {
                    Circle().fill(Color(hex: 0xF5F7F7))
                    Image(systemName: "arrow.triangle.branch").font(.system(size: size * 0.42, weight: .bold)).foregroundStyle(Color(hex: 0x111111))
                }
                .frame(width: size * 0.84, height: size * 0.84)
            case .filesystem:
                Image(systemName: "folder.fill")
                    .font(.system(size: size * 0.78))
                    .foregroundStyle(Color(hex: 0xFBC53A))
            case .web:
                ZStack {
                    Circle().fill(Color(hex: 0x26313A))
                    Circle().stroke(Color(hex: 0xF3A83B), lineWidth: size * 0.1).padding(size * 0.1)
                    Circle().fill(Color(hex: 0x5BB4F5)).padding(size * 0.26)
                }
                .frame(width: size * 0.84, height: size * 0.84)
            case .database:
                tile(LinearGradient(colors: [Color(hex: 0x8B6CF6), Color(hex: 0x5636C9)], startPoint: .topLeading, endPoint: .bottomTrailing),
                     symbol: "cylinder.split.1x2", color: Color(hex: 0xEFEAFF), scale: 0.46)
            case .page:
                tile(LinearGradient(colors: [Color(hex: 0xF5F6F6), Color(hex: 0xF5F6F6)], startPoint: .top, endPoint: .bottom),
                     symbol: "doc.text", color: Color(hex: 0x1B1B1B), scale: 0.5)
            }
        }
        .frame(width: size, height: size)
    }

    private func tile(_ fill: LinearGradient, symbol: String, color: Color, scale: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
            .fill(fill)
            .overlay(Image(systemName: symbol).font(.system(size: size * scale, weight: .semibold)).foregroundStyle(color))
            .frame(width: size * 0.84, height: size * 0.84)
    }
}

private struct RobotGlyph: View {
    var size: CGFloat
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0x1D3442)).frame(width: size * 0.78, height: size * 0.78).offset(y: size * 0.04)
            RoundedRectangle(cornerRadius: size * 0.14).fill(Color(hex: 0x7FB3CF))
                .frame(width: size * 0.52, height: size * 0.42).offset(y: size * 0.06)
            RoundedRectangle(cornerRadius: size * 0.09).fill(Color(hex: 0x12222C))
                .frame(width: size * 0.36, height: size * 0.23).offset(y: size * 0.06)
            HStack(spacing: size * 0.1) {
                Circle().fill(Color(hex: 0x43D6F0)).frame(width: size * 0.09)
                Circle().fill(Color(hex: 0x43D6F0)).frame(width: size * 0.09)
            }
            .offset(y: size * 0.06)
            Capsule().fill(Color(hex: 0x7FB3CF)).frame(width: size * 0.04, height: size * 0.12).offset(y: -size * 0.2)
            Circle().fill(Color(hex: 0x43D6F0)).frame(width: size * 0.1).offset(y: -size * 0.28)
        }
    }
}

/// Letter badge used for agents and providers (e.g. "CC" for Claude Code).
struct MonoBadge: View {
    var style: MonoBadgeStyle
    var size: CGFloat = 42

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: style.round ? size / 2 : 12, style: .continuous)
        shape
            .fill(style.background)
            .overlay(shape.stroke(style.border ?? .clear, lineWidth: 1.5))
            .overlay(Text(style.text).font(.system(size: size * 0.36, weight: .bold)).foregroundStyle(style.foreground))
            .frame(width: size, height: size)
    }
}

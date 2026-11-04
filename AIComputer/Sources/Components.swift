import SwiftUI

struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 0) { content }
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.line, lineWidth: 1))
    }
}

struct RowDivider: View {
    var body: some View { Rectangle().fill(Theme.line).frame(height: 1) }
}

struct SectionTitle: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.system(size: 16.5, weight: .semibold))
            .foregroundStyle(Theme.fg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 18)
            .padding(.bottom, 10)
    }
}

struct StatusBadge: View {
    var text: String
    var body: some View {
        let added = text == "Added"
        Text(text)
            .font(.system(size: 12.5, weight: .medium))
            .foregroundStyle(added ? Theme.muted : Theme.ok)
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background(Capsule().fill(added ? Theme.surface3 : Theme.ok.opacity(0.14)))
            .overlay(Capsule().stroke(added ? Theme.line2 : Theme.ok.opacity(0.28), lineWidth: 1))
    }
}

struct OnlinePill: View {
    var text: String
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(Theme.ok).frame(width: 7, height: 7)
            Text(text).font(.system(size: 12.5, weight: .medium))
        }
        .foregroundStyle(Theme.ok)
        .padding(.horizontal, 11)
        .padding(.vertical, 5)
        .background(Capsule().fill(Theme.ok.opacity(0.14)))
        .overlay(Capsule().stroke(Theme.ok.opacity(0.28), lineWidth: 1))
    }
}

struct Avatar: View {
    var size: CGFloat = 36
    var body: some View {
        Circle()
            .fill(LinearGradient(colors: [Theme.teal, Color(hex: 0x0E5D6B)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(Text("MS").font(.system(size: size * 0.36, weight: .semibold)).foregroundStyle(Color(hex: 0x04110F)))
            .overlay(Circle().stroke(Theme.teal.opacity(0.5), lineWidth: 1.5).padding(-3))
            .frame(width: size, height: size)
    }
}

struct WideButton: View {
    var title: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "plus").font(.system(size: 15, weight: .bold))
                Text(title).font(.system(size: 15.5, weight: .semibold))
            }
            .foregroundStyle(Theme.fg)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.wideButton))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.teal.opacity(0.16), lineWidth: 1))
        }
        .buttonStyle(PressStyle())
        .padding(.top, 16)
    }
}

struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .brightness(configuration.isPressed ? 0.05 : 0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct IconButton: View {
    var systemName: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(Theme.fg)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressStyle())
    }
}

/// Top bar: optional back button, title, optional trailing content.
struct TopBar<Trailing: View>: View {
    var title: String
    var centered = false
    var onBack: (() -> Void)? = nil
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 12) {
            if let onBack { IconButton(systemName: "arrow.left", action: onBack) }
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
            trailing
            if centered && onBack != nil { Color.clear.frame(width: 36, height: 36) }
        }
        .foregroundStyle(Theme.fg)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 14)
        .frame(minHeight: 44)
    }
}

extension TopBar where Trailing == EmptyView {
    init(title: String, centered: Bool = false, onBack: (() -> Void)? = nil) {
        self.init(title: title, centered: centered, onBack: onBack) { EmptyView() }
    }
}

/// Pill-shaped segmented control matching the mockup.
struct SegmentBar: View {
    var items: [String]
    @Binding var selection: String
    var onTap: ((String) -> Void)? = nil

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items, id: \.self) { item in
                Button {
                    if let onTap { onTap(item) } else { selection = item }
                } label: {
                    Text(item)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(item == selection ? Theme.fg : Theme.fg2)
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(item == selection ? AnyShapeStyle(Theme.selected) : AnyShapeStyle(Color.clear))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.line, lineWidth: 1))
        .padding(.horizontal, 20)
        .padding(.bottom, 18)
    }
}

struct ToastView: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundStyle(Theme.fg)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface3))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line2, lineWidth: 1))
    }
}

struct MainTabBar: View {
    @EnvironmentObject var state: AppState

    private struct Tab: Identifiable { let route: Route; let symbol: String; let title: String; var id: String { title } }
    private let tabs: [Tab] = [
        Tab(route: .home, symbol: "house", title: "Home"),
        Tab(route: .desktop, symbol: "desktopcomputer", title: "Desktop"),
        Tab(route: .agents, symbol: "gearshape.2", title: "Agents"),
        Tab(route: .mcp, symbol: "powerplug", title: "MCP"),
        Tab(route: .settings, symbol: "gearshape", title: "Settings"),
    ]

    var body: some View {
        HStack {
            ForEach(tabs) { tab in
                let active = state.route == tab.route
                Button { state.go(tab.route) } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.symbol).font(.system(size: 21, weight: active ? .semibold : .regular))
                        Text(tab.title).font(.system(size: 11.5))
                    }
                    .foregroundStyle(active ? Theme.teal : Theme.muted)
                    .frame(width: 62, height: 62)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(active ? Theme.teal.opacity(0.14) : .clear))
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .background(
            LinearGradient(colors: [Theme.bg.opacity(0), Theme.bg.opacity(0.92), Theme.bg], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

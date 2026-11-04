import SwiftUI

// MARK: - Welcome

struct WelcomeView: View {
    @EnvironmentObject var state: AppState
    @State private var page = 0

    private let slides: [(String, String)] = [
        ("AI Computer", "Your personal\nAI workspace"),
        ("Local AI", "LFM3 runs on your iPhone,\neven offline"),
        ("Your agents", "Claude Code, Codex and\nGemini CLI in one place"),
    ]

    var body: some View {
        ZStack {
            SilkBackground(ribbons: SilkPreset.welcome).ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                TabView(selection: $page) {
                    ForEach(slides.indices, id: \.self) { i in
                        VStack(spacing: 12) {
                            Text(slides[i].0).font(.system(size: 30, weight: .bold))
                            Text(slides[i].1)
                                .font(.system(size: 16))
                                .foregroundStyle(Theme.fg2)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                        }
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 140)
                .padding(.bottom, 90)

                Button { state.go(.home) } label: {
                    HStack(spacing: 8) {
                        Text("Get Started").font(.system(size: 16, weight: .semibold))
                        Image(systemName: "arrow.right").font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(Theme.fg)
                    .frame(width: 262, height: 56)
                    .background(
                        Capsule().fill(LinearGradient(colors: [Color(hex: 0x283E3C, opacity: 0.75), Color(hex: 0x121E1E, opacity: 0.75)], startPoint: .top, endPoint: .bottom))
                    )
                    .background(.ultraThinMaterial.opacity(0.4), in: Capsule())
                    .overlay(Capsule().stroke(Color(hex: 0x78DCC8, opacity: 0.22), lineWidth: 1))
                }
                .buttonStyle(PressStyle())

                HStack(spacing: 10) {
                    ForEach(slides.indices, id: \.self) { i in
                        Circle()
                            .fill(.white.opacity(i == page ? 0.8 : 0.28))
                            .frame(width: 6, height: 6)
                            .onTapGesture { withAnimation { page = i } }
                    }
                }
                .padding(.top, 40)
                .padding(.bottom, 24)
            }
            .foregroundStyle(Theme.fg)
        }
    }
}

// MARK: - Home

struct HomeView: View {
    @EnvironmentObject var state: AppState
    @State private var question = ""

    var body: some View {
        ZStack(alignment: .top) {
            RadialGradient(colors: [Theme.teal.opacity(0.10), .clear], center: UnitPoint(x: 0.8, y: 0.05), startRadius: 0, endRadius: 320)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Text("My AI Computer").font(.system(size: 17, weight: .semibold))
                    Spacer()
                    OnlinePill(text: "Online")
                    Button { state.go(.settings) } label: { Avatar() }.buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 14)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Hello Matheesha 👋").font(.system(size: 27, weight: .bold)).padding(.top, 26)
                        Text("What would you like to do?")
                            .font(.system(size: 19))
                            .foregroundStyle(Theme.fg2)
                            .padding(.top, 10)
                            .padding(.bottom, 40)

                        HStack(spacing: 12) {
                            Image(systemName: "sparkle")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Theme.cyan)
                                .frame(width: 42, height: 42)
                                .background(Circle().fill(RadialGradient(colors: [Color(hex: 0x203A3D), Color(hex: 0x101B1D)], center: UnitPoint(x: 0.4, y: 0.35), startRadius: 0, endRadius: 30)))
                            TextField("", text: $question, prompt: Text("Ask me anything...").foregroundColor(Theme.muted))
                                .font(.system(size: 16))
                                .submitLabel(.send)
                                .onSubmit(send)
                            Button(action: send) {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(Color(hex: 0x062026))
                                    .frame(width: 44, height: 44)
                                    .background(Circle().fill(Theme.cyan))
                                    .shadow(color: Theme.cyan.opacity(0.35), radius: 9)
                            }
                            .buttonStyle(PressStyle())
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 68)
                        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(LinearGradient(colors: [Color(hex: 0x1A2124), Color(hex: 0x12181A)], startPoint: .top, endPoint: .bottom)))
                        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Theme.line, lineWidth: 1))
                        .shadow(color: Theme.teal.opacity(0.07), radius: 20)

                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                            HomeTile(glyph: .globe, title: "Open\nBrowser") { state.open(.browser) }
                            HomeTile(glyph: .folder, title: "Files") { state.open(.files) }
                            HomeTile(glyph: .terminal, title: "Terminal") { state.open(.terminal) }
                            HomeTile(glyph: .robot, title: "AI Agents") { state.go(.agents) }
                        }
                        .padding(.top, 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 110)
                }
            }
            .foregroundStyle(Theme.fg)
        }
    }

    private func send() {
        let q = question.trimmingCharacters(in: .whitespaces)
        question = ""
        state.open(.assistant, question: q.isEmpty ? nil : q)
    }
}

struct HomeTile: View {
    var glyph: Glyph
    var title: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                GlyphView(glyph: glyph, size: 44)
                Text(title).font(.system(size: 16, weight: .semibold)).multilineTextAlignment(.center)
            }
            .foregroundStyle(Theme.fg)
            .frame(maxWidth: .infinity, minHeight: 150)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.tile))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.line, lineWidth: 1))
        }
        .buttonStyle(PressStyle())
    }
}

// MARK: - Desktop (phone)

struct PhoneDesktopView: View {
    @EnvironmentObject var state: AppState
    @State private var fullScreen = false

    var body: some View {
        VStack(spacing: 0) {
            if !fullScreen {
                HStack(spacing: 12) {
                    Image(systemName: "desktopcomputer").font(.system(size: 18))
                    Text("Desktop").font(.system(size: 17, weight: .semibold))
                    Spacer()
                    IconButton(systemName: "arrow.up.left.and.arrow.down.right") { withAnimation { fullScreen = true } }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 14)
            }

            ZStack(alignment: .topLeading) {
                SilkBackground(ribbons: SilkPreset.desktop)

                VStack(spacing: 22) {
                    desktopIcon(.folder) { state.open(.files) }
                    desktopIcon(.globe) { state.open(.browser) }
                    desktopIcon(.terminal) { state.open(.terminal) }
                    desktopIcon(.code) { state.open(.code) }
                    desktopIcon(.trash) { state.open(.trash) }
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 10)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(hex: 0x141C1E, opacity: 0.45)))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.white.opacity(0.05), lineWidth: 1))
                .padding(.leading, 12)
                .padding(.top, 24)

                VStack {
                    Spacer()
                    HStack {
                        dockButton { Image(systemName: "arrow.left").font(.system(size: 18)) } action: {
                            if fullScreen { withAnimation { fullScreen = false } } else { state.go(.home) }
                        }
                        dockButton { GlyphView(glyph: .grid, size: 44) } action: { state.go(.agents) }
                        dockButton { GlyphView(glyph: .folder, size: 44) } action: { state.open(.files) }
                        dockButton { GlyphView(glyph: .globe, size: 44) } action: { state.open(.browser) }
                        dockButton { Image(systemName: "sparkle").font(.system(size: 18)) } action: { state.open(.assistant) }
                        dockButton { Image(systemName: "minus").font(.system(size: 18)) } action: { state.go(.home) }
                    }
                    .foregroundStyle(Theme.fg2)
                    .frame(height: 70)
                    .background(.ultraThinMaterial.opacity(0.5), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color(hex: 0x161E20, opacity: 0.6)))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(.white.opacity(0.06), lineWidth: 1))
                    .padding(12)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Theme.line, lineWidth: 1))
            .padding(.horizontal, fullScreen ? 0 : 14)
            .padding(.bottom, fullScreen ? 0 : 10)
            .ignoresSafeArea(edges: fullScreen ? .all : [])
        }
        .foregroundStyle(Theme.fg)
    }

    private func desktopIcon(_ glyph: Glyph, action: @escaping () -> Void) -> some View {
        Button(action: action) { GlyphView(glyph: glyph, size: 46).frame(width: 52, height: 52) }
            .buttonStyle(PressStyle())
    }

    private func dockButton<L: View>(@ViewBuilder label: () -> L, action: @escaping () -> Void) -> some View {
        Button(action: action) { label().frame(width: 50, height: 50).contentShape(Rectangle()) }
            .buttonStyle(PressStyle())
            .frame(maxWidth: .infinity)
    }
}

// MARK: - AI Connections

struct ConnectionsView: View {
    @EnvironmentObject var state: AppState
    @State private var segment = "Models"

    private let sectionFor = ["Models": "sec-models", "Agents": "sec-agents", "Providers": "sec-providers"]

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "AI Connections", onBack: { state.go(.home) }) {
                IconButton(systemName: "plus") { state.startAdd(.model) }
            }
            ScrollViewReader { proxy in
              VStack(spacing: 0) {
                SegmentBar(items: ["Models", "Agents", "MCP", "Providers"], selection: $segment) { item in
                    if item == "MCP" { state.go(.mcp); return }
                    segment = item
                    if let id = sectionFor[item] { withAnimation { proxy.scrollTo(id, anchor: .top) } }
                }
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Text("Local Models").font(.system(size: 16.5, weight: .semibold)).frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 10).id("sec-models")
                        connectionCard(state.models)
                        SectionTitle(text: "Coding Agents (ACP)").id("sec-agents")
                        connectionCard(state.agents)
                        SectionTitle(text: "API Providers").id("sec-providers")
                        connectionCard(state.providers)
                        WideButton(title: "Add Connection") { state.startAdd(.provider) }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
                .onAppear {
                    if let section = state.connectionsSection {
                        segment = sectionFor.first(where: { $0.value == section })?.key ?? "Models"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { withAnimation { proxy.scrollTo(section, anchor: .top) } }
                    }
                }
              }
            }
        }
        .foregroundStyle(Theme.fg)
    }

    private func connectionCard(_ items: [Connection]) -> some View {
        Card {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index > 0 { RowDivider() }
                Button { state.flash("\(item.name) · \(item.status)") } label: {
                    HStack(spacing: 13) {
                        MonoBadge(style: item.badge)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name).font(.system(size: 15.5, weight: .medium))
                            Text(item.detail).font(.system(size: 13)).foregroundStyle(Theme.muted)
                        }
                        Spacer(minLength: 8)
                        StatusBadge(text: item.status)
                        if item.showsChevron {
                            Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.fg2)
                        }
                    }
                    .padding(.horizontal, 14)
                    .frame(minHeight: 64)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - MCP Manager

struct MCPManagerView: View {
    @EnvironmentObject var state: AppState
    @State private var segment = "Servers"

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "MCP Manager", centered: true, onBack: { state.go(.home) })
            SegmentBar(items: ["Servers", "Tools"], selection: $segment)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    if segment == "Servers" { servers } else { tools }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 110)
            }
        }
        .foregroundStyle(Theme.fg)
    }

    private var servers: some View {
        VStack(spacing: 0) {
            Card {
                ForEach($state.mcpServers) { $server in
                    if server.id != state.mcpServers.first?.id { RowDivider() }
                    HStack(spacing: 13) {
                        GlyphView(glyph: server.glyph, size: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(server.name).font(.system(size: 15.5, weight: .medium))
                            Text(server.detail).font(.system(size: 13)).foregroundStyle(Theme.muted)
                        }
                        Spacer()
                        Toggle(server.name, isOn: $server.isOn).labelsHidden().tint(Theme.ok)
                    }
                    .padding(.horizontal, 14)
                    .frame(minHeight: 64)
                }
            }
            WideButton(title: "Add MCP Server") { state.startAdd(.mcp) }
            HStack {
                Text("Connected Servers").font(.system(size: 16.5, weight: .semibold))
                Spacer()
                OnlinePill(text: "\(state.onlineCount) Online")
            }
            .padding(.top, 22)
            .padding(.bottom, 10)
            Card {
                HStack {
                    ForEach(state.mcpServers) { server in
                        GlyphView(glyph: server.glyph, size: 34)
                            .opacity(server.isOn ? 1 : 0.25)
                            .saturation(server.isOn ? 1 : 0)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 8)
            }
        }
    }

    private var tools: some View {
        let enabled = state.mcpServers.filter(\.isOn)
        return VStack(alignment: .leading, spacing: 12) {
            Card {
                if enabled.isEmpty {
                    Text("Switch on a server to see its tools.").font(.system(size: 14)).foregroundStyle(Theme.muted).padding(30)
                }
                ForEach(enabled) { server in
                    ForEach(server.tools, id: \.self) { tool in
                        if !(server.id == enabled.first?.id && tool == server.tools.first) { RowDivider() }
                        HStack(spacing: 13) {
                            GlyphView(glyph: server.glyph, size: 30)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(server.id).\(tool)").font(.system(size: 13, design: .monospaced))
                                Text(server.name).font(.system(size: 13)).foregroundStyle(Theme.muted)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .frame(minHeight: 52)
                    }
                }
            }
            Text("Tools come from the servers you switch on. Your agents can only use tools listed here.")
                .font(.system(size: 12.5))
                .foregroundStyle(Theme.muted)
        }
    }
}

// MARK: - Settings

struct SettingsView: View {
    @EnvironmentObject var state: AppState
    @State private var darkMode = true

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "Settings", centered: true, onBack: { state.go(.home) })
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Card {
                        HStack(spacing: 14) {
                            Avatar(size: 58)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Matheesha Sarathchandra").font(.system(size: 16, weight: .semibold))
                                Text("matheesha@...").font(.system(size: 13.5)).foregroundStyle(Theme.muted)
                            }
                            Spacer()
                        }
                        .padding(16)
                    }

                    Card {
                        HStack(spacing: 13) {
                            settingIcon("person.crop.circle")
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Appearance").font(.system(size: 15.5, weight: .medium))
                                Text("Dark Mode").font(.system(size: 13)).foregroundStyle(Theme.muted)
                            }
                            Spacer()
                            Toggle("Dark mode", isOn: $darkMode).labelsHidden().tint(Theme.teal)
                                .onChange(of: darkMode) { _, _ in
                                    darkMode = true
                                    state.flash("Dark mode is the only theme for now")
                                }
                        }
                        .padding(.horizontal, 14).frame(minHeight: 58)
                        RowDivider()
                        settingRow("arrow.triangle.2.circlepath", "Language", value: "English") { state.flash("English is the only language for now") }
                    }
                    .padding(.top, 16)

                    SectionTitle(text: "AI & Models")
                    Card {
                        settingRow("cube", "Model Settings") { state.go(.agents, section: "sec-models") }
                        RowDivider()
                        settingRow("lock", "Provider Keys") { state.go(.agents, section: "sec-providers") }
                    }

                    SectionTitle(text: "System")
                    Card {
                        settingRow("internaldrive", "Storage", value: "24.6 GB used") { state.flash("24.6 GB of 256 GB used") }
                        RowDivider()
                        settingRow("shield", "Security & Privacy") { state.flash("Keys are stored in the iPhone Keychain") }
                        RowDivider()
                        settingRow("info.circle", "About App") { state.flash("My AI Computer · design preview 0.1") }
                    }

                    Card {
                        HStack(spacing: 14) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Color(hex: 0x06210F))
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Theme.ok))
                                .shadow(color: Theme.ok.opacity(0.35), radius: 11)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Your AI Computer").font(.system(size: 15.5, weight: .semibold))
                                Text("Ready to work").font(.system(size: 15)).foregroundStyle(Theme.fg2)
                            }
                            Spacer()
                        }
                        .padding(16)
                    }
                    .padding(.top, 16)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .foregroundStyle(Theme.fg)
    }

    private func settingIcon(_ name: String) -> some View {
        Image(systemName: name).font(.system(size: 19)).foregroundStyle(Theme.fg2).frame(width: 28)
    }

    private func settingRow(_ icon: String, _ title: String, value: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 13) {
                settingIcon(icon)
                Text(title).font(.system(size: 15.5, weight: .medium))
                Spacer()
                if let value { Text(value).font(.system(size: 14)).foregroundStyle(Theme.fg2) }
                Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.fg2)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add connection sheet

struct AddConnectionSheet: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var value = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(state.addKind == .mcp ? "Add MCP Server" : "Add Connection")
                .font(.system(size: 18, weight: .semibold))
                .padding(.top, 24)
            Picker("Type", selection: $state.addKind) {
                ForEach(AddKind.allCases) { kind in Text(kind.label).tag(kind) }
            }
            .pickerStyle(.menu)
            .tint(Theme.teal)
            field("Name", text: $name, placeholder: "e.g. OpenRouter")
            field(state.addKind.fieldLabel, text: $value, placeholder: state.addKind.placeholder)
            Text("Preview only. Nothing you type here is stored or sent.")
                .font(.system(size: 12.5))
                .foregroundStyle(Theme.muted)
            WideButton(title: "Add") {
                state.add(kind: state.addKind, name: name.trimmingCharacters(in: .whitespaces))
                dismiss()
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .foregroundStyle(Theme.fg)
    }

    private func field(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 13)).foregroundStyle(Theme.muted)
            TextField("", text: text, prompt: Text(placeholder).foregroundColor(Theme.muted))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 12)
                .frame(height: 46)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.bg2))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line2, lineWidth: 1))
        }
    }
}

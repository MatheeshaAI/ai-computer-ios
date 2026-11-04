import SwiftUI
import WebKit

/// Full-screen wrapper for the apps opened from Home / Desktop.
struct AppContainer: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    var app: PhoneApp

    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: app.title, onBack: { dismiss() })
                .overlay(alignment: .bottom) { RowDivider() }
            Group {
                switch app {
                case .files: FilesApp(start: "Home")
                case .trash: FilesApp(start: "Trash")
                case .browser: BrowserApp()
                case .terminal: TerminalApp()
                case .assistant: AssistantApp(initialQuestion: state.pendingQuestion)
                case .code: CodeApp()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.bg2.ignoresSafeArea())
        .foregroundStyle(Theme.fg)
    }
}

// MARK: - Files

struct FilesApp: View {
    struct Item: Hashable { var name: String; var isFolder: Bool }

    static let tree: [String: [Item]] = [
        "Home": ["Projects", "Documents", "Downloads", "Pictures", "Videos"].map { Item(name: $0, isFolder: true) },
        "Documents": ["AI-business-plan.md", "Client-quotes.pdf", "Notes.txt"].map { Item(name: $0, isFolder: false) },
        "Downloads": ["lfm3-1.7b-q4.gguf", "mcp-servers.json"].map { Item(name: $0, isFolder: false) },
        "Projects": ["ai-computer", "whatsapp-bot", "vps-scripts"].map { Item(name: $0, isFolder: true) },
        "Desktop": ["agent.py", "todo.md"].map { Item(name: $0, isFolder: false) },
        "Pictures": [Item(name: "wallpaper.png", isFolder: false)],
        "Videos": [], "Trash": [],
    ]
    struct Place: Hashable { var name: String; var symbol: String }
    static let sidebar: [Place] = [
        Place(name: "Home", symbol: "house"), Place(name: "Documents", symbol: "arrow.down.to.line"),
        Place(name: "Downloads", symbol: "arrow.down.to.line"), Place(name: "Projects", symbol: "rectangle"),
        Place(name: "Desktop", symbol: "rectangle"), Place(name: "Trash", symbol: "trash"),
    ]

    @State var start: String
    @State private var current: String? = nil

    var body: some View {
        let place = current ?? start
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Self.sidebar, id: \.self) { entry in
                        Button { current = entry.name } label: {
                            HStack(spacing: 8) {
                                Image(systemName: entry.symbol).font(.system(size: 15))
                                Text(entry.name).font(.system(size: 14))
                            }
                            .foregroundStyle(place == entry.name ? Theme.fg : Theme.fg2)
                            .padding(.horizontal, 12)
                            .frame(height: 38)
                            .background(RoundedRectangle(cornerRadius: 9).fill(place == entry.name ? Color.white.opacity(0.08) : .clear))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
            }
            .overlay(alignment: .bottom) { RowDivider() }

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("~/" + (place == "Home" ? "" : place)).font(.system(size: 12, design: .monospaced)).foregroundStyle(Theme.muted)
                    let items = Self.tree[place] ?? []
                    if items.isEmpty {
                        Text(place == "Trash" ? "Trash is empty" : "No files here yet")
                            .font(.system(size: 14)).foregroundStyle(Theme.muted)
                            .frame(maxWidth: .infinity).padding(.vertical, 30)
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 6)], spacing: 10) {
                            ForEach(items, id: \.self) { item in
                                Button {
                                    if item.isFolder, Self.tree[item.name] != nil { current = item.name }
                                } label: {
                                    VStack(spacing: 7) {
                                        if item.isFolder {
                                            GlyphView(glyph: .folder, size: 56)
                                        } else {
                                            Image(systemName: "doc.text").font(.system(size: 38, weight: .light)).foregroundStyle(Color(hex: 0x9FB0AD)).frame(height: 56)
                                        }
                                        Text(item.name).font(.system(size: 13.5)).multilineTextAlignment(.center).lineLimit(2)
                                    }
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(PressStyle())
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
    }
}

// MARK: - Browser

struct BrowserApp: View {
    @State private var address = ""
    @State private var url: URL?
    @StateObject private var web = WebController()

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                IconButton(systemName: "arrow.left") { if web.canGoBack { web.view.goBack() } else { url = nil; address = "" } }
                IconButton(systemName: "arrow.right") { web.view.goForward() }.opacity(web.canGoForward ? 1 : 0.4)
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").font(.system(size: 14)).foregroundStyle(Theme.fg2)
                    TextField("", text: $address, prompt: Text("Search or enter address").foregroundColor(Theme.fg2))
                        .font(.system(size: 14))
                        .keyboardType(.webSearch)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.go)
                        .onSubmit(load)
                }
                .padding(.horizontal, 12)
                .frame(height: 36)
                .background(Capsule().fill(Theme.surface2))
                .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .overlay(alignment: .bottom) { RowDivider() }

            ZStack {
                SkylineView()
                if url != nil { WebView(controller: web) }
            }
        }
    }

    private func load() {
        let q = address.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }
        let looksLikeURL = !q.contains(" ") && q.contains(".")
        let target: URL?
        if looksLikeURL {
            target = URL(string: q.hasPrefix("http") ? q : "https://" + q)
        } else {
            var c = URLComponents(string: "https://duckduckgo.com/")
            c?.queryItems = [URLQueryItem(name: "q", value: q)]
            target = c?.url
        }
        guard let target else { return }
        url = target
        web.view.load(URLRequest(url: target))
    }
}

@MainActor
final class WebController: NSObject, ObservableObject, WKNavigationDelegate {
    let view = WKWebView()
    @Published var canGoBack = false
    @Published var canGoForward = false

    override init() {
        super.init()
        view.navigationDelegate = self
        view.isOpaque = false
        view.backgroundColor = UIColor(red: 0.05, green: 0.07, blue: 0.08, alpha: 1)
        view.allowsBackForwardNavigationGestures = true
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
    }
}

struct WebView: UIViewRepresentable {
    var controller: WebController
    func makeUIView(context: Context) -> WKWebView { controller.view }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

/// Start page: city skyline at dusk, drawn in code.
struct SkylineView: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height, hz = h * 0.6
            ctx.fill(Path(CGRect(x: 0, y: 0, width: w, height: hz)), with: .linearGradient(
                Gradient(colors: [Color(hex: 0x1B2A63), Color(hex: 0x4A5FA8), Color(hex: 0xA689B8), Color(hex: 0xE9A98A)]),
                startPoint: .zero, endPoint: CGPoint(x: 0, y: hz)))
            var rng = SeededRandom(seed: 7)
            var x = 0.0
            while x < w {
                let bw = 6 + rng.next() * 18
                let far = x < w * 0.45
                let bh = (far ? 10 + rng.next() * 30 : 18 + rng.next() * 70) * (h / 300)
                let rect = CGRect(x: x, y: hz - bh, width: bw, height: bh)
                ctx.fill(Path(rect), with: .color(Color(hex: bh > 45 ? 0x0D1333 : 0x1D2550)))
                var wy = rect.minY + 4
                while wy < hz - 2 {
                    var wx = rect.minX + 2
                    while wx < rect.maxX - 2 {
                        if rng.next() < 0.16 {
                            ctx.fill(Path(CGRect(x: wx, y: wy, width: 1.4, height: 1.6)), with: .color(Color(hex: 0xFFCD82, opacity: 0.85)))
                        }
                        wx += 3.5
                    }
                    wy += 4
                }
                x += bw + rng.next() * 2
            }
            // tower with spire
            var tower = Path()
            let tx = w * 0.83, th = hz * 0.85
            tower.move(to: CGPoint(x: tx, y: hz))
            tower.addLine(to: CGPoint(x: tx + 3, y: hz - th * 0.55))
            tower.addLine(to: CGPoint(x: tx + 6, y: hz - th * 0.8))
            tower.addLine(to: CGPoint(x: tx + 8, y: hz - th))
            tower.addLine(to: CGPoint(x: tx + 10, y: hz - th * 0.8))
            tower.addLine(to: CGPoint(x: tx + 13, y: hz - th * 0.55))
            tower.addLine(to: CGPoint(x: tx + 16, y: hz))
            tower.closeSubpath()
            ctx.fill(tower, with: .color(Color(hex: 0x141C40)))
            // water
            ctx.fill(Path(CGRect(x: 0, y: hz, width: w, height: h - hz)), with: .linearGradient(
                Gradient(colors: [Color(hex: 0x2A2F5C), Color(hex: 0x0A1028)]), startPoint: CGPoint(x: 0, y: hz), endPoint: CGPoint(x: 0, y: h)))
            for _ in 0..<260 {
                let sx = rng.next() * w, sy = hz + rng.next() * (h - hz) * 0.8
                ctx.fill(Path(CGRect(x: sx, y: sy, width: 1 + rng.next() * 8, height: 1)),
                         with: .color(Color(hex: 0xFFC078, opacity: 0.15 + rng.next() * 0.35)))
            }
        }
    }
}

struct SeededRandom {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state >> 11) / Double(1 << 53)
    }
}

// MARK: - Terminal (Alpine Linux running on the phone via iSH)

struct TerminalApp: View {
    @ObservedObject private var shell = LinuxShell.shared
    @State private var input = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        if let note = statusNote {
                            Text(note).foregroundStyle(Theme.muted)
                        }
                        Text(shell.output)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .font(Theme.mono)
                    .foregroundStyle(Color(hex: 0xD7E0DE))
                    .padding(14)
                }
                .background(Color(hex: 0x050707))
                .onTapGesture { focused = true }
                .onChange(of: shell.output) { _, _ in proxy.scrollTo("bottom", anchor: .bottom) }
            }

            HStack(spacing: 8) {
                Text("$").font(Theme.mono).foregroundStyle(Theme.term).fontWeight(.semibold)
                TextField("", text: $input, prompt: Text("type a command").foregroundColor(Theme.muted))
                    .font(Theme.mono)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focused)
                    .tint(Theme.term)
                    .submitLabel(.send)
                    .onSubmit(run)
                Button { shell.send("\u{3}") } label: {
                    Text("^C").font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 10).frame(height: 32)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surface2))
                }
                .buttonStyle(PressStyle())
            }
            .padding(.horizontal, 12)
            .frame(height: 52)
            .background(Color(hex: 0x0A0E0F))
        }
        .onAppear {
            shell.startIfNeeded()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { focused = true }
        }
    }

    private var statusNote: String? {
        switch shell.status {
        case .idle, .installing: return "Installing Alpine Linux (first launch only)..."
        case .booting: return "Starting Linux..."
        case .running: return nil
        case .exited(let code): return "Shell exited (code \(code)). Reopen the app to start a new one."
        case .failed(let message): return message
        }
    }

    private func run() {
        let cmd = input
        input = ""
        focused = true
        if cmd.trimmingCharacters(in: .whitespaces) == "clear" { shell.clearScreen() }
        shell.send(cmd + "\n")
    }
}

// MARK: - AI Assistant (Claude Code on the user's PC, via the bridge)

struct AssistantApp: View {
    struct Message: Identifiable { let id = UUID(); var fromUser: Bool; var text: String; var isError = false }

    var initialQuestion: String?
    @State private var messages: [Message] = []
    @State private var input = ""
    @State private var sessionID: String?
    @State private var thinking = false

    private struct Suggestion: Hashable { var symbol: String; var text: String }
    private let suggestions: [Suggestion] = [
        Suggestion(symbol: "doc.text", text: "Summarize this page"), Suggestion(symbol: "doc.badge.gearshape", text: "Run a Python script"),
        Suggestion(symbol: "doc.text", text: "Create a project plan"), Suggestion(symbol: "magnifyingglass", text: "Search for information"),
    ]

    var body: some View {
        VStack(spacing: 12) {
            ScrollView {
                VStack(spacing: 10) {
                    VStack(spacing: 6) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(Theme.cyan)
                            .frame(width: 70, height: 70)
                            .background(Circle().fill(RadialGradient(colors: [Theme.cyan.opacity(0.18), Color(hex: 0x14282C, opacity: 0.4), .clear], center: .center, startRadius: 0, endRadius: 36)))
                        Text("How can I help you today?").font(.system(size: 20, weight: .semibold)).padding(.top, 8)
                        Text(Bridge.isSetUp ? "Claude Code · via your PC" : "Not connected · Settings → Claude Code Bridge")
                            .font(.system(size: 12)).foregroundStyle(Theme.muted)
                    }
                    .padding(.vertical, 18)

                    if messages.isEmpty {
                        ForEach(suggestions, id: \.self) { s in
                            Button { ask(s.text) } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: s.symbol).font(.system(size: 16)).foregroundStyle(Theme.fg2)
                                    Text(s.text).font(.system(size: 14.5))
                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .frame(height: 46)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.035)))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
                            }
                            .buttonStyle(PressStyle())
                        }
                    }

                    ForEach(messages) { m in
                        HStack {
                            if m.fromUser { Spacer(minLength: 40) }
                            VStack(alignment: .leading, spacing: 4) {
                                if !m.fromUser { Text(m.isError ? "Couldn't reach Claude" : "Claude Code").font(.system(size: 11.5)).foregroundStyle(m.isError ? Color(hex: 0xF2B84B) : Theme.muted) }
                                Text(m.text).font(.system(size: 14.5)).textSelection(.enabled)
                            }
                            .padding(.horizontal, 13).padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 16).fill(m.fromUser ? Color(hex: 0x1F4A4E) : Theme.surface2))
                            if !m.fromUser { Spacer(minLength: 40) }
                        }
                    }

                    if thinking {
                        HStack(spacing: 8) {
                            ProgressView().tint(Theme.muted)
                            Text("Claude is thinking on your PC...").font(.system(size: 13)).foregroundStyle(Theme.muted)
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 16)
            }

            HStack(spacing: 10) {
                TextField("", text: $input, prompt: Text("Ask anything...").foregroundColor(Theme.fg2))
                    .font(.system(size: 15))
                    .submitLabel(.send)
                    .onSubmit { ask(input) }
                Button { ask(input) } label: {
                    Image(systemName: "arrow.right").font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 36, height: 36).background(Circle().fill(Theme.blue))
                }
                .buttonStyle(PressStyle())
            }
            .padding(.leading, 16).padding(.trailing, 8)
            .frame(height: 56)
            .background(RoundedRectangle(cornerRadius: 18).fill(Theme.surface2))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line, lineWidth: 1))
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .onAppear { if let q = initialQuestion, messages.isEmpty { ask(q) } }
    }

    private func ask(_ raw: String) {
        let q = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty, !thinking else { return }
        input = ""
        messages.append(Message(fromUser: true, text: q))
        thinking = true
        Task { @MainActor in
            defer { thinking = false }
            do {
                let result = try await Bridge.chat(q, sessionID: sessionID)
                sessionID = result.session_id ?? sessionID
                withAnimation { messages.append(Message(fromUser: false, text: result.reply)) }
            } catch {
                withAnimation { messages.append(Message(fromUser: false, text: error.localizedDescription, isError: true)) }
            }
        }
    }
}

// MARK: - Code (sample file)

struct CodeApp: View {
    private let code = [
        "# agent.py · sample",
        "from aicomputer import Agent, mcp",
        "",
        "agent = Agent(\"claude-code\", transport=\"acp\")",
        "agent.tools = [mcp.github, mcp.filesystem]",
        "",
        "def main():",
        "    task = agent.run(\"Summarise today's new leads\")",
        "    print(task.result)",
        "",
        "if __name__ == \"__main__\":",
        "    main()",
    ]

    var body: some View {
        ScrollView([.vertical, .horizontal]) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(code.indices, id: \.self) { i in
                    HStack(alignment: .firstTextBaseline, spacing: 14) {
                        Text("\(i + 1)").foregroundStyle(Color(hex: 0x4B5654)).frame(width: 26, alignment: .trailing)
                        Text(code[i].isEmpty ? " " : code[i]).foregroundStyle(code[i].hasPrefix("#") ? Color(hex: 0x5F6E6B) : Color(hex: 0xD7E0DE))
                    }
                }
            }
            .font(.system(size: 13, design: .monospaced))
            .padding(14)
        }
        .background(Color(hex: 0x0A0E0F))
    }
}

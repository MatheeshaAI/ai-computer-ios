import SwiftUI

enum Route: String {
    case welcome, home, desktop, agents, mcp, settings

    var showsTabBar: Bool { self == .home || self == .mcp }
}

enum PhoneApp: String, Identifiable {
    case files, browser, terminal, assistant, code, trash
    var id: String { rawValue }

    var title: String {
        switch self {
        case .files: return "Files"
        case .browser: return "Browser"
        case .terminal: return "Terminal"
        case .assistant: return "AI Assistant"
        case .code: return "VS Code"
        case .trash: return "Trash"
        }
    }
}

enum AddKind: String, CaseIterable, Identifiable {
    case provider, agent, model, mcp
    var id: String { rawValue }

    var label: String {
        switch self {
        case .provider: return "API provider (API key)"
        case .agent: return "Coding agent (ACP)"
        case .model: return "Local model (GGUF)"
        case .mcp: return "MCP server"
        }
    }
    var fieldLabel: String {
        switch self {
        case .provider: return "API key"
        case .agent: return "ACP endpoint"
        case .model: return "Model file (GGUF)"
        case .mcp: return "Server URL"
        }
    }
    var placeholder: String {
        switch self {
        case .provider: return "sk-..."
        case .agent: return "acp://my-vps:7400"
        case .model: return "model-q4.gguf"
        case .mcp: return "https://..."
        }
    }
}

struct MonoBadgeStyle {
    var text: String
    var background: AnyShapeStyle
    var foreground: Color
    var round: Bool
    var border: Color? = nil
}

struct Connection: Identifiable {
    let id = UUID()
    var name: String
    var detail: String
    var status: String
    var badge: MonoBadgeStyle
    var showsChevron = false
}

struct MCPServer: Identifiable {
    let id: String
    var name: String
    var detail: String
    var isOn: Bool
    var glyph: Glyph
    var tools: [String]
}

final class AppState: ObservableObject {
    @Published var route: Route = .welcome
    @Published var openApp: PhoneApp?
    @Published var pendingQuestion: String?
    @Published var showAdd = false
    @Published var addKind: AddKind = .provider
    @Published var connectionsSection: String?
    @Published var toast: String?

    // Sample data for the UI preview
    @Published var models: [Connection] = [
        Connection(name: "LFM3-1.7B", detail: "On Device", status: "Active",
                   badge: MonoBadgeStyle(text: "LF", background: AnyShapeStyle(LinearGradient(colors: [Color(hex: 0x1D6F86), Color(hex: 0x103A4A)], startPoint: .topLeading, endPoint: .bottomTrailing)), foreground: Color(hex: 0x9FF0FF), round: false),
                   showsChevron: true)
    ]
    @Published var agents: [Connection] = [
        Connection(name: "Claude Code", detail: "Subscription", status: "Connected",
                   badge: MonoBadgeStyle(text: "CC", background: AnyShapeStyle(Color(hex: 0xD97757)), foreground: .white, round: true)),
        Connection(name: "Codex", detail: "Agent", status: "Connected",
                   badge: MonoBadgeStyle(text: "Cx", background: AnyShapeStyle(Color(hex: 0x0F1A1E)), foreground: .white, round: true, border: Color(hex: 0xE8EEF0))),
        Connection(name: "Gemini CLI", detail: "Agent", status: "Connected",
                   badge: MonoBadgeStyle(text: "G", background: AnyShapeStyle(LinearGradient(colors: [Color(hex: 0x4F8FF7), Color(hex: 0x1B4FC4)], startPoint: .topLeading, endPoint: .bottomTrailing)), foreground: .white, round: true)),
    ]
    @Published var providers: [Connection] = [
        Connection(name: "OpenAI", detail: "API Key", status: "Connected",
                   badge: MonoBadgeStyle(text: "O", background: AnyShapeStyle(Color(hex: 0xE9EEEE)), foreground: Color(hex: 0x0B0F10), round: true)),
        Connection(name: "Anthropic", detail: "API Key", status: "Connected",
                   badge: MonoBadgeStyle(text: "A", background: AnyShapeStyle(Color(hex: 0xE1704A)), foreground: .white, round: false)),
    ]
    @Published var mcpServers: [MCPServer] = [
        MCPServer(id: "github", name: "GitHub", detail: "Code & Issues", isOn: true, glyph: .repo, tools: ["create_issue", "list_pull_requests", "search_code"]),
        MCPServer(id: "fs", name: "Filesystem", detail: "Files & Folders", isOn: true, glyph: .filesystem, tools: ["read_file", "write_file", "list_directory"]),
        MCPServer(id: "browser", name: "Browser", detail: "Web Research", isOn: true, glyph: .web, tools: ["open_page", "search_web", "screenshot"]),
        MCPServer(id: "db", name: "Database", detail: "Data Access", isOn: true, glyph: .database, tools: ["run_query", "list_tables"]),
        MCPServer(id: "notion", name: "Notion MCP", detail: "Your workspace", isOn: true, glyph: .page, tools: ["search_pages", "create_page"]),
    ]

    var onlineCount: Int { mcpServers.filter(\.isOn).count }

    func go(_ route: Route, section: String? = nil) {
        connectionsSection = section
        self.route = route
    }

    func open(_ app: PhoneApp, question: String? = nil) {
        pendingQuestion = question
        openApp = app
    }

    func startAdd(_ kind: AddKind) {
        addKind = kind
        showAdd = true
    }

    func add(kind: AddKind, name: String) {
        let title = name.isEmpty ? "New connection" : name
        let badge = MonoBadgeStyle(text: String(title.prefix(1)).uppercased(), background: AnyShapeStyle(Theme.surface3), foreground: Theme.fg, round: false)
        switch kind {
        case .provider: providers.append(Connection(name: title, detail: "API provider", status: "Added", badge: badge))
        case .agent: agents.append(Connection(name: title, detail: "Coding agent", status: "Added", badge: badge))
        case .model: models.append(Connection(name: title, detail: "Local model", status: "Added", badge: badge))
        case .mcp: mcpServers.append(MCPServer(id: title.lowercased().filter(\.isLetter), name: title, detail: "Custom server", isOn: true, glyph: .grid, tools: ["custom_tool"]))
        }
        flash("\(title) added")
    }

    private var toastTask: DispatchWorkItem?
    func flash(_ message: String) {
        toastTask?.cancel()
        toast = message
        let task = DispatchWorkItem { [weak self] in self?.toast = nil }
        toastTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9, execute: task)
    }

    /// Lets the CI build open a given screen for screenshots: `-screen home`, `-app files`.
    static func fromLaunchArguments() -> AppState {
        let state = AppState()
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-screen"), i + 1 < args.count, let r = Route(rawValue: args[i + 1]) {
            state.route = r
        }
        if let i = args.firstIndex(of: "-app"), i + 1 < args.count, let a = PhoneApp(rawValue: args[i + 1]) {
            state.openApp = a
        }
        return state
    }
}

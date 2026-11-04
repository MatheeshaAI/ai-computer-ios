import Foundation

/// Runs Alpine Linux on the phone through the iSH-ARM64 emulator and exposes one interactive shell.
@MainActor
final class LinuxShell: ObservableObject {
    static let shared = LinuxShell()

    enum Status: Equatable {
        case idle, installing, booting, running, exited(Int32), failed(String)
    }

    @Published private(set) var status: Status = .idle
    @Published private(set) var output = ""

    /// Bump when the bundled root filesystem changes, so phones get a fresh copy.
    private let rootfsVersion = "alpine-3.21-1"
    private let maxOutput = 40_000
    private var pendingCR = false

    private var rootURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("alpine-rootfs", isDirectory: true)
    }

    func startIfNeeded() {
        guard status == .idle else { return }
        status = .installing
        let root = rootURL
        let version = rootfsVersion
        Task.detached(priority: .userInitiated) {
            do {
                try Self.installRootfs(at: root, version: version)
                await self.boot(root)
            } catch {
                await self.fail("Couldn't install Linux: \(error.localizedDescription)")
            }
        }
    }

    func send(_ text: String) {
        LinuxEngine.shared.sendInput(text)
    }

    func clearScreen() { output = "" }

    // MARK: - Steps

    private func boot(_ root: URL) {
        status = .booting
        let engine = LinuxEngine.shared
        engine.outputHandler = { [weak self] data in
            Task { @MainActor in self?.append(data) }
        }
        engine.exitHandler = { [weak self] pid, code in
            Task { @MainActor in if pid != 1 { self?.status = .exited(code) } }
        }
        let err = engine.boot(withRootPath: root.path)
        guard err == 0 else { return fail("Linux failed to boot (error \(err)).") }
        let started = engine.startProcess(["/bin/sh", "-l"])
        guard started == 0 else { return fail("Couldn't start the shell (error \(started)).") }
        status = .running
    }

    private func fail(_ message: String) {
        status = .failed(message)
        output += "\n\(message)\n"
    }

    /// Copies the bundled fakefs root (data/ + meta.db) to Application Support on first launch.
    nonisolated private static func installRootfs(at root: URL, version: String) throws {
        let fm = FileManager.default
        let marker = root.appendingPathComponent(".installed-version")
        if (try? String(contentsOf: marker, encoding: .utf8)) == version { return }
        guard let bundled = Bundle.main.url(forResource: "alpine-rootfs", withExtension: nil) else {
            throw NSError(domain: "LinuxShell", code: 1, userInfo: [NSLocalizedDescriptionKey: "Linux files are missing from the app"])
        }
        if fm.fileExists(atPath: root.path) { try fm.removeItem(at: root) }
        try fm.createDirectory(at: root.deletingLastPathComponent(), withIntermediateDirectories: true)
        try fm.copyItem(at: bundled, to: root)
        try version.write(to: marker, atomically: true, encoding: .utf8)
    }

    // MARK: - Output (a plain-text view of the terminal stream)

    private func append(_ data: Data) {
        var text = String(decoding: data, as: UTF8.self)
        text = Self.stripEscapes(text)
        for ch in text {
            switch ch {
            case "\r\n", "\n": output.append("\n"); pendingCR = false
            case "\r": pendingCR = true
            case "\u{8}", "\u{7F}": if !output.isEmpty, output.last != "\n" { output.removeLast() }
            case "\u{7}": break
            default:
                if pendingCR {
                    // Carriage return without newline: redraw the current line.
                    if let nl = output.lastIndex(of: "\n") { output.removeSubrange(output.index(after: nl)...) } else { output = "" }
                    pendingCR = false
                }
                output.append(ch)
            }
        }
        if output.count > maxOutput { output.removeFirst(output.count - maxOutput) }
    }

    private static let escapePattern = try! NSRegularExpression(
        pattern: "\u{1B}\\[[0-9;?]*[ -/]*[@-~]|\u{1B}\\][^\u{7}\u{1B}]*(\u{7}|\u{1B}\\\\)|\u{1B}[()][0-9A-Za-z]|\u{1B}[=>78cDEHM]")

    private static func stripEscapes(_ s: String) -> String {
        escapePattern.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: "")
    }
}

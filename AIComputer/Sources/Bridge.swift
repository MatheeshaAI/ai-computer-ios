import Foundation
import Security

/// Talks to bridge/bridge.py on the user's PC, which runs Claude Code on their subscription.
/// The PC is reached over Tailscale, so traffic is encrypted by WireGuard even though it is plain HTTP.
enum Bridge {
    struct Reply: Decodable { let reply: String; let session_id: String? }
    private struct Failure: Decodable { let error: String }

    enum BridgeError: LocalizedError {
        case notSetUp, badAddress, server(String), unreachable(String)
        var errorDescription: String? {
            switch self {
            case .notSetUp: return "Set up the PC bridge first: Settings → Claude Code Bridge."
            case .badAddress: return "The bridge address looks wrong. Use the PC's Tailscale IP, e.g. 100.101.102.103:8787."
            case .server(let message): return message
            case .unreachable(let message): return "Can't reach your PC (\(message)). Check the PC is on, the bridge is running and Tailscale is connected on both devices."
            }
        }
    }

    static var address: String {
        get { Keychain.get("bridge.address") ?? "" }
        set { Keychain.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), for: "bridge.address") }
    }
    static var token: String {
        get { Keychain.get("bridge.token") ?? "" }
        set { Keychain.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), for: "bridge.token") }
    }
    static var isSetUp: Bool { !address.isEmpty && !token.isEmpty }

    private static func url(_ path: String) throws -> URL {
        guard isSetUp else { throw BridgeError.notSetUp }
        var base = address
        if !base.contains("://") { base = "http://" + base }
        if URL(string: base)?.port == nil { base += ":8787" }
        guard let url = URL(string: base + path) else { throw BridgeError.badAddress }
        return url
    }

    private static func send(_ request: URLRequest) async throws -> Data {
        var request = request
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data: Data, response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw BridgeError.unreachable(error.localizedDescription)
        }
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            let message = (try? JSONDecoder().decode(Failure.self, from: data))?.error ?? "Bridge error \(status)"
            throw BridgeError.server(message)
        }
        return data
    }

    static func checkConnection() async throws {
        var request = URLRequest(url: try url("/health"))
        request.timeoutInterval = 10
        _ = try await send(request)
    }

    static func chat(_ message: String, sessionID: String?) async throws -> Reply {
        var request = URLRequest(url: try url("/chat"))
        request.httpMethod = "POST"
        request.timeoutInterval = 320 // the bridge allows Claude Code up to 300 s
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: String] = ["message": message]
        if let sessionID { body["session_id"] = sessionID }
        request.httpBody = try JSONEncoder().encode(body)
        return try JSONDecoder().decode(Reply.self, from: try await send(request))
    }
}

/// Minimal Keychain wrapper for small strings.
enum Keychain {
    private static func query(_ key: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: "com.matheesha.aicomputer",
         kSecAttrAccount as String: key]
    }

    static func get(_ key: String) -> String? {
        var q = query(key)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &item) == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func set(_ value: String, for key: String) {
        SecItemDelete(query(key) as CFDictionary)
        guard !value.isEmpty else { return }
        var q = query(key)
        q[kSecValueData as String] = Data(value.utf8)
        q[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(q as CFDictionary, nil)
    }
}

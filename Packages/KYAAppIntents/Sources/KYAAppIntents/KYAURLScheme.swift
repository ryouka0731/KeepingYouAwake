import AppKit
import Foundation

/// Builds and dispatches `keepingyouawake://...` URLs that the running app
/// already understands via `KYAEventHandler`. Using the URL scheme keeps the
/// intents free of any direct dependency on the app's internals: the same
/// path is exercised by AppleScript, the URL scheme handler tests, and
/// (now) Shortcuts.app.
enum KYAURLScheme {
    private static let scheme = "keepingyouawake"

    enum Action: String {
        case activate
        case deactivate
        case toggle
    }

    enum DispatchError: Error {
        case invalidURL
        case workspaceOpenFailed(URL)
    }

    static func dispatch(_ action: Action, query: [URLQueryItem] = []) throws {
        var components = URLComponents()
        components.scheme = scheme
        components.host = action.rawValue
        components.queryItems = query.isEmpty ? nil : query
        guard let url = components.url else {
            throw DispatchError.invalidURL
        }
        if !NSWorkspace.shared.open(url) {
            throw DispatchError.workspaceOpenFailed(url)
        }
    }
}

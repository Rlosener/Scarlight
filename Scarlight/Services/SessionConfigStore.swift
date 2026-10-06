import Foundation

enum SessionConfigStore {
    private static let filename = "session_config.json"
    private static let store = LocalJSONStore.shared

    static func load() -> GameSessionConfig {
        guard store.fileExists(filename) else { return .default }
        return (try? store.load(from: filename, as: GameSessionConfig.self)) ?? .default
    }

    static func save(_ config: GameSessionConfig) {
        try? store.save(config, to: filename)
    }
}

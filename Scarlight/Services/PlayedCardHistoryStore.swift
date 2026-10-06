import Foundation

/// Oyunlar arası tekrarları azaltmak için oynatılan kart/soru id geçmişi.
enum PlayedCardHistoryStore {
    private static let filename = "played_cards.json"
    private static let store = LocalJSONStore.shared

    static func load() -> Set<String> {
        guard store.fileExists(filename) else { return [] }
        return (try? store.load(from: filename, as: Set<String>.self)) ?? []
    }

    static func save(_ ids: Set<String>) {
        try? store.save(ids, to: filename)
    }

    static func clear() {
        guard store.fileExists(filename) else { return }
        try? store.delete(filename)
    }
}


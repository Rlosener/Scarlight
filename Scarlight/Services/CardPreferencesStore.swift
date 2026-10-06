import Foundation

struct CardPreference: Codable, Equatable {
    var isFavorite: Bool = false
    var isHiddenFromPool: Bool = false
}

enum CardPreferencesStore {
    private static let filename = "card_preferences.json"
    private static let store = LocalJSONStore.shared

    static func loadAll() -> [String: CardPreference] {
        guard store.fileExists(filename),
              let prefs = try? store.load(from: filename, as: [String: CardPreference].self) else {
            return [:]
        }
        return prefs
    }

    private static func save(_ prefs: [String: CardPreference]) throws {
        try store.save(prefs, to: filename)
        NotificationCenter.default.post(name: .cardsDidChange, object: nil)
    }

    static func replaceAll(_ prefs: [String: CardPreference]) throws {
        try save(prefs)
    }

    static func preference(for cardId: String) -> CardPreference {
        loadAll()[cardId] ?? CardPreference()
    }

    static func isFavorite(_ cardId: String) -> Bool {
        preference(for: cardId).isFavorite
    }

    static func isHidden(_ cardId: String) -> Bool {
        preference(for: cardId).isHiddenFromPool
    }

    static func setFavorite(_ cardId: String, _ value: Bool) throws {
        var prefs = loadAll()
        var entry = prefs[cardId] ?? CardPreference()
        entry.isFavorite = value
        prefs[cardId] = entry
        try save(prefs)
    }

    static func setHidden(_ cardId: String, _ value: Bool) throws {
        var prefs = loadAll()
        var entry = prefs[cardId] ?? CardPreference()
        entry.isHiddenFromPool = value
        prefs[cardId] = entry
        try save(prefs)
    }

    static func clearAll() {
        try? store.delete(filename)
        NotificationCenter.default.post(name: .cardsDidChange, object: nil)
    }

    /// Favori kartlara seçim havuzunda ekstra ağırlık verir.
    static func weightedRandom(from cards: [GameCard]) -> GameCard? {
        guard !cards.isEmpty else { return nil }
        let preferences = loadAll()
        var pool = cards
        for card in cards where preferences[card.id]?.isFavorite == true {
            pool.append(card)
        }
        return pool.randomElement()
    }
}

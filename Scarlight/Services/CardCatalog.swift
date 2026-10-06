import Foundation

/// Oyun kartlarının tek kaynak noktası: bundle desteleri + kullanıcı kartları + sistem (zar/çark).
enum CardCatalog {
    static let userCardsFilename = "user_cards.json"
    static let legacyCardsFilename = "cards.json"

    static func loadForGameplay() -> [GameCard] {
        migrateLegacyStoreIfNeeded()

        var cards: [GameCard] = []
        cards.append(contentsOf: DeckPackLoader.bundledPackCards())
        cards.append(contentsOf: loadUserCards())
        cards.append(contentsOf: CardLoader.loadSystemCards())
        let preferences = CardPreferencesStore.loadAll()
        return uniqueCards(cards).filter { $0.isActive && preferences[$0.id]?.isHiddenFromPool != true }
    }

    static func loadForEditor() -> [GameCard] {
        migrateLegacyStoreIfNeeded()
        var cards: [GameCard] = []
        cards.append(contentsOf: DeckPackLoader.bundledPackCards())
        cards.append(contentsOf: loadUserCards())
        cards.append(contentsOf: CardLoader.loadSystemCards())
        cards = uniqueCards(cards)
        cards.removeAll { isLegacyDemoCard($0) }
        return cards
    }

    static func loadUserCards() -> [GameCard] {
        let store = LocalJSONStore.shared
        guard store.fileExists(userCardsFilename),
              let cards = try? store.load(from: userCardsFilename, as: [GameCard].self) else {
            return []
        }
        return cards
    }

    @discardableResult
    static func saveUserCard(_ card: GameCard) throws -> GameCard {
        var userCard = card
        userCard.isUserAuthored = true
        var cards = loadUserCards()
        if let index = cards.firstIndex(where: { $0.id == userCard.id }) {
            cards[index] = userCard
        } else {
            cards.append(userCard)
        }
        try LocalDataValidation.validateCards([userCard])
        try LocalJSONStore.shared.save(cards, to: userCardsFilename)
        NotificationCenter.default.post(name: .cardsDidChange, object: nil)
        return userCard
    }

    @discardableResult
    static func deleteUserCard(id: String) -> Bool {
        var cards = loadUserCards()
        let before = cards.count
        cards.removeAll { $0.id == id }
        guard cards.count < before else { return false }
        do {
            try LocalJSONStore.shared.save(cards, to: userCardsFilename)
            return true
        } catch {
            return false
        }
    }

    /// Kullanıcı kartını veya bundle deste kartını kalıcı olarak siler.
    @discardableResult
    static func deleteCard(_ card: GameCard) -> Bool {
        let deleted: Bool
        if card.isUserCard {
            deleted = deleteUserCard(id: card.id)
        } else if isSystemCardId(card.id) {
            return false
        } else if let filename = PackFileStore.packFilename(forCardId: card.id) {
            deleted = PackFileStore.deleteEntry(cardId: card.id, in: filename)
        } else {
            return false
        }

        if deleted {
            NotificationCenter.default.post(name: .cardsDidChange, object: nil)
        }
        return deleted
    }

    static func canDelete(_ card: GameCard) -> Bool {
        card.isUserCard || PackFileStore.isBundledPackCardId(card.id)
    }

    @discardableResult
    static func updateUserCards(_ cards: [GameCard]) throws -> Bool {
        let userOnly = cards.filter(\.isUserCard)
        try LocalDataValidation.validateCards(userOnly)
        try LocalJSONStore.shared.save(userOnly, to: userCardsFilename)
        NotificationCenter.default.post(name: .cardsDidChange, object: nil)
        return true
    }

    /// User overrides keep their IDs; a catalog never exposes duplicate row identities.
    private static func uniqueCards(_ cards: [GameCard]) -> [GameCard] {
        var indices: [String: Int] = [:]
        var result: [GameCard] = []
        for card in cards {
            if let index = indices[card.id] {
                if card.isUserCard { result[index] = card }
            } else {
                indices[card.id] = result.count
                result.append(card)
            }
        }
        return result
    }

    static func importUserCards(_ imported: [GameCard]) throws {
        try LocalDataValidation.validateCards(imported)
        var cards = loadUserCards()
        var indices = Dictionary(cards.enumerated().map { ($1.id, $0) }, uniquingKeysWith: { first, _ in first })
        for var card in imported where !isSystemCardId(card.id) {
            card.isUserAuthored = true
            if let index = indices[card.id] {
                cards[index] = card
            } else {
                indices[card.id] = cards.count
                cards.append(card)
            }
        }
        try updateUserCards(cards)
    }

    /// Bundle deste kartı mı?
    static func isBundledPackId(_ id: String) -> Bool {
        id.hasPrefix("nhi_") ||
        id.hasPrefix("ht_") ||
        id.hasPrefix("ha_") ||
        id.hasPrefix("fr_") ||
        id.hasPrefix("bar_") ||
        id.hasPrefix("prop_hot_") ||
        id.hasPrefix("prop_ed_") ||
        id.hasPrefix("prop_nhi_") ||
        id.hasPrefix("prop_ht_") ||
        id.hasPrefix("prop_ha_") ||
        id.hasPrefix("prop_fr_") ||
        id.hasPrefix("prop_gen_")
    }

    /// Zar / çark gibi sistem kartları
    static func isSystemCardId(_ id: String) -> Bool {
        id.hasPrefix("sys_")
    }

    static func isLegacyDemoCard(_ card: GameCard) -> Bool {
        if card.isUserCard { return false }
        if isBundledPackId(card.id) || isSystemCardId(card.id) { return false }
        if card.deckType != nil { return false }
        // Eski CardLoader demo içeriği
        return card.text.contains("{actor}") || card.title.hasPrefix("Cesur Soru") ||
            card.title.hasPrefix("Sürpriz Soru") || card.title.hasPrefix("Süreli Görev") ||
            card.title.hasPrefix("Partner Görevi") || card.title.hasPrefix("Rol Kartı") ||
            card.title.hasPrefix("Final Focus")
    }

    /// Eski cards.json → user_cards.json taşıma; demo kartları at.
    static func migrateLegacyStoreIfNeeded() {
        let store = LocalJSONStore.shared
        let migrationKey = "card_catalog_migrated_v1"
        if UserDefaults.standard.bool(forKey: migrationKey) { return }

        var userCards = loadUserCards()

        if store.fileExists(legacyCardsFilename),
           let legacy = try? store.load(from: legacyCardsFilename, as: [GameCard].self) {
            let extracted = legacy.filter { card in
                card.isUserCard ||
                (!isBundledPackId(card.id) && !isSystemCardId(card.id) && !isLegacyDemoCard(card))
            }
            for card in extracted where !userCards.contains(where: { $0.id == card.id }) {
                var c = card
                c.isUserAuthored = true
                userCards.append(c)
            }
        }

        if !userCards.isEmpty {
            do {
                try store.save(userCards, to: userCardsFilename)
            } catch {
                return // Retry migration on the next load; never mark a failed write complete.
            }
        }

        UserDefaults.standard.set(true, forKey: migrationKey)
    }

    static func deckStats(from cards: [GameCard], profile: SessionContentProfile = .intimate) -> [(CardDeckType, Int)] {
        let active = cards.filter(\.isActive)
        let grouped = Dictionary(grouping: active) { $0.effectiveDeckType }
        return CardDeckType.playableDefaults(for: profile).map { ($0, grouped[$0]?.count ?? 0) }
    }

    static func deckStats(from cards: [GameCard]) -> [(CardDeckType, Int)] {
        deckStats(from: cards, profile: .intimate)
    }

    /// Eşya seçim ekranında kartı olan prop id'leri.
    static func propIdsWithCards() -> Set<String> {
        let cards = DeckPackLoader.bundledPackCards().filter { card in
            guard let ids = card.requiredPropIds, !ids.isEmpty else { return false }
            return card.isActive
        }
        return Set(cards.flatMap { $0.requiredPropIds ?? [] })
    }

    static func hasCards(forPropId propId: String) -> Bool {
        propIdsWithCards().contains(propId)
    }
}

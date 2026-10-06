import Foundation

/// Harici deste kartlarını yükler ve `GameCard` modeline dönüştürür.
enum DeckPackLoader {
    static func bundledPackCards() -> [GameCard] {
        var cards: [GameCard] = []
        cards.append(contentsOf: loadPackFile(filename: PackFileStore.deckPacksFilename))
        cards.append(contentsOf: loadPackFile(filename: PackFileStore.propQuestionsFilename))
        cards.append(contentsOf: loadPackFile(filename: PackFileStore.barSocialPacksFilename))
        return cards
    }

    private static func loadPackFile(filename: String) -> [GameCard] {
        let entries = PackFileStore.loadEntries(named: filename)
        if entries.isEmpty, filename == PackFileStore.deckPacksFilename, !PackFileStore.hasEditableCopy(named: filename) {
            print("DeckPackLoader: \(filename) bulunamadı")
            return DeckPackSeedData.fallbackCards()
        }
        return entries.map { $0.toGameCard() }
    }

    /// Her açılışta bundle'daki deste kartlarını ekler veya günceller.
    @discardableResult
    static func syncBundledPacks(into cards: inout [GameCard]) -> Bool {
        let packCards = bundledPackCards()
        guard !packCards.isEmpty else { return false }

        var changed = false
        var indexById = Dictionary(uniqueKeysWithValues: cards.enumerated().map { ($1.id, $0) })

        for packCard in packCards {
            if let index = indexById[packCard.id] {
                if cards[index] != packCard {
                    cards[index] = packCard
                    changed = true
                }
            } else {
                cards.append(packCard)
                indexById[packCard.id] = cards.count - 1
                changed = true
            }
        }
        return changed
    }

    static func deckTypes(for phase: GamePhase, profile: SessionContentProfile = .intimate) -> Set<CardDeckType> {
        switch profile {
        case .social:
            switch phase {
            case .boldQuestion, .surpriseQuestion:
                return [.barTruth, .standard]
            case .timedTask:
                return [.barDare, .standard]
            case .roleDuo, .finalFocus:
                return [.barNeverHaveI, .barTruth, .barDare, .standard]
            case .wheel, .dice:
                return [.barDare, .barNeverHaveI, .standard]
            }
        case .intimate:
            switch phase {
            case .boldQuestion, .surpriseQuestion:
                return [.hardTruth, .standard]
            case .timedTask:
                return [.hardAction, .standard, .propTask]
            case .roleDuo, .finalFocus:
                return [.fantasyRole, .standard, .propTask]
            case .wheel, .dice:
                return [.standard]
            }
        }
    }

    static func deckTypes(for phase: GamePhase) -> Set<CardDeckType> {
        deckTypes(for: phase, profile: .intimate)
    }
}

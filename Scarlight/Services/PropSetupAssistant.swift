import Foundation

struct PropSetupAnalysis: Equatable {
    let selectedPropCount: Int
    let playablePropCardCount: Int
    let recommendedPropIds: Set<String>
    let missingPropSelection: Bool
    let propDeckEnabled: Bool
    let selectedPropsWithoutCards: [String]

    var title: String {
        if !propDeckEnabled {
            return "Eşya görevleri kapalı"
        }
        if missingPropSelection {
            return "Eşya seçmeden eşya kartı çıkmaz"
        }
        if playablePropCardCount == 0 {
            return "Seçili eşyalara uygun kart yok"
        }
        return "\(playablePropCardCount) eşya kartı hazır"
    }

    var message: String {
        if !propDeckEnabled {
            return "Eşya görevlerini açarsan seçili eşyalara göre özel kartlar havuza eklenir."
        }
        if missingPropSelection {
            return "Önerilen eşyaları seçebilir ya da propsuz devam edip bu desteyi kapatabilirsin."
        }
        if !selectedPropsWithoutCards.isEmpty {
            return "\(selectedPropsWithoutCards.count) seçili eşyanın kartı yok; oyun bu eşyaları atlar."
        }
        return "Seçili eşyalar oyun havuzuyla uyumlu görünüyor."
    }
}

enum PropSetupAssistant {
    static func analyze(
        config: GameSessionConfig,
        playerCount: Int,
        cards: [GameCard] = CardCatalog.loadForGameplay()
    ) -> PropSetupAnalysis {
        let propCards = cards.filter { $0.effectiveDeckType == .propTask }
        let idsWithCards = Set(propCards.flatMap { $0.requiredPropIds ?? [] })
        let selectedWithoutCards = config.selectedPropIds
            .filter { !idsWithCards.contains($0) }
            .sorted()

        let playablePropCardCount = propCards.filter { card in
            guard card.matchesPlayerCount(playerCount) else { return false }
            guard config.matchesContentTier(card) else { return false }
            guard card.isAvailable(for: config.playIntensityLevel) else { return false }
            guard card.intensity <= config.maxCardIntensity else { return false }
            guard config.matchesBoundaryPreferences(card) else { return false }
            return config.hasAnyProp(from: card.requiredPropIds)
        }.count

        return PropSetupAnalysis(
            selectedPropCount: config.selectedPropIds.count,
            playablePropCardCount: playablePropCardCount,
            recommendedPropIds: recommendedPropIds(from: propCards),
            missingPropSelection: config.enabledDeckTypes.contains(.propTask) && config.selectedPropIds.isEmpty,
            propDeckEnabled: config.enabledDeckTypes.contains(.propTask),
            selectedPropsWithoutCards: selectedWithoutCards
        )
    }

    static func recommendedPropIds(from cards: [GameCard] = DeckPackLoader.bundledPackCards(), limit: Int = 8) -> Set<String> {
        var counts: [String: Int] = [:]
        for card in cards where card.effectiveDeckType == .propTask {
            for id in card.requiredPropIds ?? [] {
                counts[id, default: 0] += 1
            }
        }

        let ids = counts
            .sorted { lhs, rhs in
                if lhs.value == rhs.value { return lhs.key < rhs.key }
                return lhs.value > rhs.value
            }
            .prefix(limit)
            .map(\.key)
        return Set(ids)
    }
}

import Foundation

enum PlayableCardCounter {
    static func countPlayableCards(config: GameSessionConfig, playerCount: Int, cards: [GameCard] = CardCatalog.loadForGameplay()) -> Int {
        playableCards(config: config, playerCount: playerCount, cards: cards).count
    }

    static func playableCards(config: GameSessionConfig, playerCount: Int, cards: [GameCard] = CardCatalog.loadForGameplay()) -> [GameCard] {
        cards.filter { card in
            guard card.isActive else { return false }
            guard config.matchesContentProfile(card) else { return false }
            guard config.enabledDeckTypes.contains(card.effectiveDeckType) || card.effectiveDeckType == .standard else {
                return false
            }
            guard card.matchesPlayerCount(playerCount) else { return false }
            guard config.hasAnyProp(from: card.requiredPropIds) else { return false }
            guard config.matchesContentTier(card) else { return false }
            guard config.matchesBoundaryPreferences(card) else { return false }
            guard card.isAvailable(for: config.playIntensityLevel) else { return false }
            guard card.intensity <= config.maxCardIntensity else { return false }
            return true
        }
    }

    static func deckBreakdown(config: GameSessionConfig, playerCount: Int, cards: [GameCard] = CardCatalog.loadForGameplay()) -> [(CardDeckType, Int)] {
        let cards = playableCards(config: config, playerCount: playerCount, cards: cards)
        let grouped = Dictionary(grouping: cards) { $0.effectiveDeckType }
        return CardDeckType.playableDefaults(for: config.contentProfile).map { ($0, grouped[$0]?.count ?? 0) }
    }
}

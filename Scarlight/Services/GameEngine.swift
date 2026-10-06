import Foundation

enum GameState: String, Codable, Equatable {
    case idle
    case cardDisplay
    case timerRunning
    case waitingForCompletion
    case penaltyChoice
    case penaltyDisplay
    case partnerConsent
    case wheelSpin
    case diceRoll
    case diceWildChoice
    case neverHaveIChoice
    case roundSetup
    case gameComplete
}

struct CardSelectionContext {
    var session: GameSessionConfig
    var playerCount: Int
    var activeItemName: String?
}

struct GameEngine {
    private var allCards: [GameCard] = []
    private var allPenalties: [PenaltyCard] = []
    private var playedCardIds: Set<String> = []
    private var recentRefusalPenaltyIds: [String] = []

    mutating func loadCards(_ cards: [GameCard]) {
        let preferences = CardPreferencesStore.loadAll()
        self.allCards = cards.filter { $0.isActive && preferences[$0.id]?.isHiddenFromPool != true }
    }

    mutating func loadPenalties(_ penalties: [PenaltyCard]) {
        self.allPenalties = penalties.filter { $0.isActive }
    }

    mutating func resetPlayedCards() {
        playedCardIds.removeAll()
    }

    mutating func seedPlayedCardIds(_ ids: Set<String>) {
        playedCardIds = ids
    }

    func playedCardIdsSnapshot() -> Set<String> {
        playedCardIds
    }

    mutating func selectCard(
        for phase: GamePhase,
        fateCategory: FateCategory,
        intensity: Int,
        intensityLevel: IntensityLevel,
        context: CardSelectionContext
    ) -> GameCard? {
        selectFateCard(
            category: fateCategory,
            intensity: intensity,
            intensityLevel: intensityLevel,
            context: context
        )
    }

    /// Zar: kategoriye göre gerçek deste kartı seç.
    mutating func selectFateCard(
        category: FateCategory,
        intensity: Int,
        intensityLevel: IntensityLevel,
        context: CardSelectionContext
    ) -> GameCard? {
        let allowedDecks = FateCategoryMapper.deckTypes(for: category, profile: context.session.contentProfile)
            .intersection(context.session.enabledDeckTypes)
        let preferredTiers = FateCategoryMapper.preferredTiers(for: category)

        func pool(strict: Bool, ignorePlayed: Bool) -> [GameCard] {
            allCards.filter { card in
                guard FateCategoryMapper.isUsableContent(card) else { return false }
                guard context.session.matchesContentProfile(card) else { return false }
                guard allowedDecks.contains(card.effectiveDeckType) else { return false }
                guard card.matchesPlayerCount(context.playerCount) else { return false }
                guard context.session.hasAnyProp(from: card.requiredPropIds) else { return false }
                guard context.session.matchesContentTier(card) else { return false }
                guard context.session.matchesBoundaryPreferences(card) else { return false }
                guard card.isAvailable(for: intensityLevel) else { return false }
                if ignorePlayed, playedCardIds.contains(card.id) { return false }
                if strict, card.intensity > intensity { return false }
                if let tiers = preferredTiers, let tier = card.contentTier, !tiers.contains(tier) {
                    return false
                }
                return true
            }
        }

        var available = pool(strict: true, ignorePlayed: true)
        if available.isEmpty {
            available = pool(strict: false, ignorePlayed: true)
        }
        if available.isEmpty {
            playedCardIds.removeAll()
            available = pool(strict: false, ignorePlayed: true)
        }
        if available.isEmpty {
            available = pool(strict: false, ignorePlayed: false)
        }

        guard let selected = CardPreferencesStore.weightedRandom(from: available) else { return nil }
        playedCardIds.insert(selected.id)
        return selected
    }

    /// Çark: görev ağırlıklı deste kartı seç.
    mutating func selectWheelCard(
        intensity: Int,
        intensityLevel: IntensityLevel,
        context: CardSelectionContext
    ) -> GameCard? {
        let allowedDecks = FateCategoryMapper.wheelDeckTypes(profile: context.session.contentProfile)
            .intersection(context.session.enabledDeckTypes)

        func pool(strict: Bool, ignorePlayed: Bool) -> [GameCard] {
            allCards.filter { card in
                guard FateCategoryMapper.isUsableContent(card) else { return false }
                guard context.session.matchesContentProfile(card) else { return false }
                guard allowedDecks.contains(card.effectiveDeckType) else { return false }
                guard card.matchesPlayerCount(context.playerCount) else { return false }
                guard context.session.hasAnyProp(from: card.requiredPropIds) else { return false }
                guard context.session.matchesContentTier(card) else { return false }
                guard context.session.matchesBoundaryPreferences(card) else { return false }
                guard card.isAvailable(for: intensityLevel) else { return false }
                if ignorePlayed, playedCardIds.contains(card.id) { return false }
                if strict, card.intensity > intensity { return false }
                if context.session.contentProfile == .intimate {
                    if card.effectiveDeckType == .hardTruth { return false }
                    if card.effectiveDeckType == .neverHaveI, card.onYesTask == nil { return false }
                } else {
                    if card.effectiveDeckType == .barTruth { return false }
                    if card.effectiveDeckType == .barNeverHaveI, card.onYesTask == nil { return false }
                }
                return true
            }
        }

        var available = pool(strict: true, ignorePlayed: true)
        if available.isEmpty { available = pool(strict: false, ignorePlayed: true) }
        if available.isEmpty {
            playedCardIds.removeAll()
            available = pool(strict: false, ignorePlayed: true)
        }

        guard let selected = CardPreferencesStore.weightedRandom(from: available) else { return nil }
        playedCardIds.insert(selected.id)
        return selected
    }

    mutating func selectCard(
        for phase: GamePhase,
        intensity: Int,
        intensityLevel: IntensityLevel,
        context: CardSelectionContext
    ) -> GameCard? {
        let allowedDecks = deckTypes(for: phase, session: context.session)
        let phasePool = phaseAliases(for: phase)

        func filterPool(_ pool: [GameCard], strict: Bool) -> [GameCard] {
            pool.filter { card in
                guard phasePool.contains(card.phase) else { return false }
                guard context.session.matchesContentProfile(card) else { return false }
                guard allowedDecks.contains(card.effectiveDeckType) else { return false }
                guard card.matchesPlayerCount(context.playerCount) else { return false }
                guard context.session.hasAnyProp(from: card.requiredPropIds) else { return false }
                guard context.session.matchesContentTier(card) else { return false }
                guard context.session.matchesBoundaryPreferences(card) else { return false }
                guard !CardCatalog.isLegacyDemoCard(card) else { return false }
                guard !playedCardIds.contains(card.id) else { return false }

                if strict {
                    return card.intensity <= intensity &&
                        card.isAvailable(for: intensityLevel) &&
                        context.session.enabledDeckTypes.contains(card.effectiveDeckType)
                }
                return card.isAvailable(for: intensityLevel)
            }
        }

        var availableCards = filterPool(allCards, strict: true)

        if availableCards.isEmpty {
            playedCardIds.removeAll()
            availableCards = filterPool(allCards, strict: true)
        }

        if availableCards.isEmpty {
            availableCards = filterPool(allCards, strict: false)
        }

        guard let selectedCard = CardPreferencesStore.weightedRandom(from: availableCards) else {
            return nil
        }

        playedCardIds.insert(selectedCard.id)
        return selectedCard
    }

    private func phaseAliases(for phase: GamePhase) -> Set<GamePhase> {
        switch phase {
        case .surpriseQuestion:
            return [.surpriseQuestion, .boldQuestion]
        case .finalFocus:
            return [.finalFocus, .roleDuo, .timedTask, .boldQuestion]
        default:
            return [phase]
        }
    }

    private func deckTypes(for phase: GamePhase, session: GameSessionConfig) -> Set<CardDeckType> {
        var types = DeckPackLoader.deckTypes(for: phase, profile: session.contentProfile)
        if phase == .surpriseQuestion {
            types.formUnion(DeckPackLoader.deckTypes(for: .boldQuestion, profile: session.contentProfile))
        }
        if phase == .finalFocus {
            types.formUnion(Set(CardDeckType.playableDefaults(for: session.contentProfile)))
        }
        return types.intersection(session.enabledDeckTypes.union([.standard]))
    }

    mutating func selectCard(for phase: GamePhase, intensity: Int, intensityLevel: IntensityLevel) -> GameCard? {
        selectCard(
            for: phase,
            intensity: intensity,
            intensityLevel: intensityLevel,
            context: CardSelectionContext(session: .default, playerCount: 2)
        )
    }

    func selectPenalty(id: String?) -> PenaltyCard? {
        guard let id = id else { return nil }
        return allPenalties.first { $0.id == id }
    }

    mutating func selectRandomPenalty(type: PenaltyType, maxIntensity: Int) -> PenaltyCard? {
        var available = allPenalties.filter {
            $0.type == type && $0.intensity <= maxIntensity && $0.isActive
        }

        if type == .refusal {
            let recent = Set(recentRefusalPenaltyIds.suffix(4))
            let withoutRecent = available.filter { !recent.contains($0.id) }
            if !withoutRecent.isEmpty {
                available = withoutRecent
            }
        }

        guard let selected = available.randomElement() else { return nil }

        if type == .refusal {
            recentRefusalPenaltyIds.append(selected.id)
            if recentRefusalPenaltyIds.count > 6 {
                recentRefusalPenaltyIds.removeFirst(recentRefusalPenaltyIds.count - 6)
            }
        }

        return selected
    }

    func selectActor(rule: ActorRule, currentPlayer: Player?, players: [Player], wheelSelectedId: UUID?) -> Player? {
        switch rule {
        case .currentPlayer:
            return currentPlayer
        case .wheelSelected:
            return players.first { $0.id == wheelSelectedId }
        case .randomPlayer:
            return players.randomElement()
        case .previousPlayer:
            return currentPlayer
        }
    }

    func selectTarget(rule: TargetRule, actor: Player?, players: [Player], partnerId: UUID? = nil) -> Player? {
        guard let actor = actor else { return nil }

        switch rule {
        case .none:
            return nil
        case .randomOther:
            let others = players.filter { $0.id != actor.id }
            return others.randomElement()
        case .partnerOrRandom:
            if let partnerId,
               let partner = players.first(where: { $0.id == partnerId && $0.id != actor.id }) {
                return partner
            }
            let others = players.filter { $0.id != actor.id }
            return others.randomElement()
        case .allPlayers:
            return players.first
        case .chosenByActor:
            if let partnerId,
               let partner = players.first(where: { $0.id == partnerId && $0.id != actor.id }) {
                return partner
            }
            let others = players.filter { $0.id != actor.id }
            return others.randomElement()
        case .chosenByWheel:
            return players.randomElement()
        }
    }
}

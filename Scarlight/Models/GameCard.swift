import Foundation

struct GameCard: Identifiable, Codable, Equatable {
    let id: String
    var title: String
    var type: CardType
    var phase: GamePhase
    var intensity: Int
    var minIntensity: IntensityLevel
    var maxIntensity: IntensityLevel

    var durationSeconds: Int

    var actorRule: ActorRule
    var targetRule: TargetRule

    var requiresTargetConsent: Bool
    var usesWheel: Bool
    var usesDice: Bool

    var text: String

    var answers: [String]?
    var triggerAnswer: String?
    var surpriseTask: SurpriseTask?

    var relatedPenaltyId: String?
    var refusalPenaltyId: String?

    var fateCategory: FateCategory?

    var deckType: CardDeckType?
    var contentTier: ContentTier?
    var minPlayers: Int?
    var maxPlayers: Int?
    var onYesTask: String?
    var requiredPropIds: [String]?
    var propCategory: PropCategory?

    var isActive: Bool
    /// Kullanıcının oyun içi veya editörden eklediği kart
    var isUserAuthored: Bool?

    var effectiveDeckType: CardDeckType { deckType ?? .standard }

    var isUserCard: Bool { isUserAuthored == true }

    init(
        id: String = UUID().uuidString,
        title: String,
        type: CardType,
        phase: GamePhase,
        intensity: Int,
        minIntensity: IntensityLevel = .soft,
        maxIntensity: IntensityLevel = .hardcore,
        durationSeconds: Int,
        actorRule: ActorRule = .currentPlayer,
        targetRule: TargetRule = .none,
        requiresTargetConsent: Bool = false,
        usesWheel: Bool = false,
        usesDice: Bool = false,
        text: String,
        answers: [String]? = nil,
        triggerAnswer: String? = nil,
        surpriseTask: SurpriseTask? = nil,
        relatedPenaltyId: String? = nil,
        refusalPenaltyId: String? = nil,
        fateCategory: FateCategory? = nil,
        deckType: CardDeckType? = nil,
        contentTier: ContentTier? = nil,
        minPlayers: Int? = nil,
        maxPlayers: Int? = nil,
        onYesTask: String? = nil,
        requiredPropIds: [String]? = nil,
        propCategory: PropCategory? = nil,
        isActive: Bool = true,
        isUserAuthored: Bool? = nil
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.phase = phase
        self.intensity = intensity
        self.minIntensity = minIntensity
        self.maxIntensity = maxIntensity
        self.durationSeconds = durationSeconds
        self.actorRule = actorRule
        self.targetRule = targetRule
        self.requiresTargetConsent = requiresTargetConsent
        self.usesWheel = usesWheel
        self.usesDice = usesDice
        self.text = text
        self.answers = answers
        self.triggerAnswer = triggerAnswer
        self.surpriseTask = surpriseTask
        self.relatedPenaltyId = relatedPenaltyId
        self.refusalPenaltyId = refusalPenaltyId
        self.fateCategory = fateCategory
        self.deckType = deckType
        self.contentTier = contentTier
        self.minPlayers = minPlayers
        self.maxPlayers = maxPlayers
        self.onYesTask = onYesTask
        self.requiredPropIds = requiredPropIds
        self.propCategory = propCategory
        self.isActive = isActive
        self.isUserAuthored = isUserAuthored
    }

    func isAvailable(for level: IntensityLevel) -> Bool {
        return level.rawValue >= minIntensity.rawValue && level.rawValue <= maxIntensity.rawValue
    }

    func matchesPlayerCount(_ count: Int) -> Bool {
        Self.supportsPlayerCount(minPlayers: minPlayers, maxPlayers: maxPlayers, count: count)
    }

    static func supportsPlayerCount(minPlayers: Int?, maxPlayers: Int?, count: Int) -> Bool {
        let min = minPlayers ?? 2
        let max = maxPlayers ?? 99

        if max <= 2 {
            return count == 2 || count == 3
        }

        if min == 3 && max == 3 {
            return count == 3
        }

        return count >= min && count <= max
    }

    func matchesSession(_ session: GameSessionConfig, playerCount: Int) -> Bool {
        guard matchesPlayerCount(playerCount) else { return false }
        guard session.matchesContentProfile(self) else { return false }
        guard session.enabledDeckTypes.contains(effectiveDeckType) || effectiveDeckType == .standard else {
            return false
        }
        guard session.hasAnyProp(from: requiredPropIds) else { return false }
        return session.matchesBoundaryPreferences(self)
    }

    var isNeverHaveI: Bool {
        effectiveDeckType == .neverHaveI || effectiveDeckType == .barNeverHaveI
    }

    /// maxPlayers 2 olan kartlar: sıradaki oyuncu + rastgele bir diğer oyuncu.
    var isTwoPlayerContent: Bool {
        (maxPlayers ?? 99) <= 2
    }

    /// Süreli görev mi, yoksa sözlü cevap mı?
    var isTimedTaskCard: Bool {
        if isNeverHaveI { return false }
        switch type {
        case .task, .roleDuo, .wheel, .dice:
            return true
        default:
            return false
        }
    }

    var hasTimedSurface: Bool {
        isTimedTaskCard || (isNeverHaveI && onYesTask?.isEmpty == false)
    }
}

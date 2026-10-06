import Foundation

struct BoundaryPreferences: Codable, Equatable {
    var allowsProps: Bool
    var allowsTimedCards: Bool
    var maximumCardIntensity: Int
    var disabledDeckTypes: Set<CardDeckType>

    static let `default` = BoundaryPreferences(
        allowsProps: true,
        allowsTimedCards: true,
        maximumCardIntensity: 5,
        disabledDeckTypes: []
    )

    var hasActiveLimits: Bool {
        !allowsProps ||
            !allowsTimedCards ||
            maximumCardIntensity < 5 ||
            !disabledDeckTypes.isEmpty
    }

    func normalized(for profile: SessionContentProfile) -> BoundaryPreferences {
        var copy = self
        copy.maximumCardIntensity = min(5, max(3, copy.maximumCardIntensity))
        if profile == .social {
            copy.allowsProps = false
            copy.maximumCardIntensity = min(copy.maximumCardIntensity, 3)
            copy.disabledDeckTypes.insert(.propTask)
        }
        if !copy.allowsProps {
            copy.disabledDeckTypes.insert(.propTask)
        }
        return copy
    }

    func allows(_ card: GameCard) -> Bool {
        guard card.intensity <= maximumCardIntensity else { return false }
        guard !disabledDeckTypes.contains(card.effectiveDeckType) else { return false }

        if !allowsProps {
            let requiresProp = card.effectiveDeckType == .propTask ||
                card.requiredPropIds?.isEmpty == false ||
                card.propCategory != nil
            guard !requiresProp else { return false }
        }

        if !allowsTimedCards, card.hasTimedSurface {
            return false
        }

        return true
    }
}

struct GameSessionConfig: Codable, Equatable {
    var selectedPropIds: Set<String>
    var enabledDeckTypes: Set<CardDeckType>
    /// Bar/arkadaş veya sıcak-yetişkin içerik ayrımı.
    var contentProfile: SessionContentProfile
    /// Kart havuzu için oyun yoğunluğu (Soft … Hardcore).
    var playIntensityLevel: IntensityLevel
    /// Kartların maksimum yoğunluk puanı (3–5).
    var maxCardIntensity: Int
    /// Hangi içerik seviyeleri çıksın (Başlangıç / Orta / Ateşli).
    var enabledContentTiers: Set<ContentTier>
    /// 3 kişilik oyunda sabit partner çifti (2 oyuncu id'si).
    var partnerPlayerIds: [UUID]
    /// Hangi oyun fazları aktif (çark, zar vb.).
    var enabledPhases: Set<GamePhase>
    /// Yeni oyun başlarken kart/soru geçmişi sıfırlansın mı?
    /// Kapalıyken tekrar eden soruların önüne geçmek için geçmiş korunur.
    var resetDrawnCardsOnStart: Bool
    /// Oyuncunun sınır/konfor tercihlerinden gelen sert filtreler.
    var boundaryPreferences: BoundaryPreferences

    static var defaultEnabledPhases: Set<GamePhase> {
        Set(GamePhase.allCases)
    }

    static let `default` = GameSessionConfig(
        selectedPropIds: [],
        enabledDeckTypes: Set(CardDeckType.playableDefaults),
        contentProfile: .intimate,
        playIntensityLevel: .soft,
        maxCardIntensity: 3,
        enabledContentTiers: Set(ContentTier.allCases),
        partnerPlayerIds: [],
        enabledPhases: defaultEnabledPhases,
        resetDrawnCardsOnStart: false,
        boundaryPreferences: .default
    )

    enum CodingKeys: String, CodingKey {
        case selectedPropIds
        case enabledDeckTypes
        case contentProfile
        case playIntensityLevel
        case maxCardIntensity
        case enabledContentTiers
        case partnerPlayerIds
        case enabledPhases
        case resetDrawnCardsOnStart
        case boundaryPreferences
    }

    init(
        selectedPropIds: Set<String>,
        enabledDeckTypes: Set<CardDeckType>,
        contentProfile: SessionContentProfile = .intimate,
        playIntensityLevel: IntensityLevel = .soft,
        maxCardIntensity: Int = 3,
        enabledContentTiers: Set<ContentTier> = Set(ContentTier.allCases),
        partnerPlayerIds: [UUID] = [],
        enabledPhases: Set<GamePhase> = GameSessionConfig.defaultEnabledPhases,
        resetDrawnCardsOnStart: Bool = false,
        boundaryPreferences: BoundaryPreferences = .default
    ) {
        let normalizedBoundaries = boundaryPreferences.normalized(for: contentProfile)
        self.selectedPropIds = selectedPropIds
        self.enabledDeckTypes = enabledDeckTypes.subtracting(normalizedBoundaries.disabledDeckTypes)
        self.contentProfile = contentProfile
        self.playIntensityLevel = playIntensityLevel
        self.maxCardIntensity = min(normalizedBoundaries.maximumCardIntensity, min(5, max(3, maxCardIntensity)))
        self.enabledContentTiers = enabledContentTiers.isEmpty
            ? Set(ContentTier.allCases)
            : enabledContentTiers
        self.partnerPlayerIds = partnerPlayerIds
        self.enabledPhases = enabledPhases.isEmpty ? GameSessionConfig.defaultEnabledPhases : enabledPhases
        self.resetDrawnCardsOnStart = resetDrawnCardsOnStart
        self.boundaryPreferences = normalizedBoundaries
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        selectedPropIds = try container.decode(Set<String>.self, forKey: .selectedPropIds)
        enabledDeckTypes = try container.decode(Set<CardDeckType>.self, forKey: .enabledDeckTypes)
        contentProfile = try container.decodeIfPresent(SessionContentProfile.self, forKey: .contentProfile) ?? .intimate
        playIntensityLevel = try container.decode(IntensityLevel.self, forKey: .playIntensityLevel)
        maxCardIntensity = try container.decode(Int.self, forKey: .maxCardIntensity)
        enabledContentTiers = try container.decode(Set<ContentTier>.self, forKey: .enabledContentTiers)
        partnerPlayerIds = try container.decodeIfPresent([UUID].self, forKey: .partnerPlayerIds) ?? []
        enabledPhases = try container.decodeIfPresent(Set<GamePhase>.self, forKey: .enabledPhases)
            ?? GameSessionConfig.defaultEnabledPhases
        resetDrawnCardsOnStart = try container.decodeIfPresent(Bool.self, forKey: .resetDrawnCardsOnStart) ?? false
        boundaryPreferences = try container
            .decodeIfPresent(BoundaryPreferences.self, forKey: .boundaryPreferences)?
            .normalized(for: contentProfile) ?? BoundaryPreferences.default.normalized(for: contentProfile)
        enabledDeckTypes.subtract(boundaryPreferences.disabledDeckTypes)
        maxCardIntensity = min(maxCardIntensity, boundaryPreferences.maximumCardIntensity)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(selectedPropIds, forKey: .selectedPropIds)
        try container.encode(enabledDeckTypes, forKey: .enabledDeckTypes)
        try container.encode(contentProfile, forKey: .contentProfile)
        try container.encode(playIntensityLevel, forKey: .playIntensityLevel)
        try container.encode(maxCardIntensity, forKey: .maxCardIntensity)
        try container.encode(enabledContentTiers, forKey: .enabledContentTiers)
        try container.encode(partnerPlayerIds, forKey: .partnerPlayerIds)
        try container.encode(enabledPhases, forKey: .enabledPhases)
        try container.encode(resetDrawnCardsOnStart, forKey: .resetDrawnCardsOnStart)
        try container.encode(boundaryPreferences, forKey: .boundaryPreferences)
    }

    func isPhaseEnabled(_ phase: GamePhase) -> Bool {
        enabledPhases.contains(phase)
    }

    static func firstEnabledPhase(in config: GameSessionConfig) -> GamePhase {
        GamePhase.allCases.first { config.isPhaseEnabled($0) } ?? .boldQuestion
    }

    var partnerPairSet: Set<UUID> {
        Set(partnerPlayerIds.prefix(2))
    }

    func matchesContentProfile(_ card: GameCard) -> Bool {
        card.effectiveDeckType.sessionContentProfile == contentProfile
    }

    func matchesContentTier(_ card: GameCard) -> Bool {
        guard let tier = card.contentTier else { return true }
        return enabledContentTiers.contains(tier)
    }

    func matchesBoundaryPreferences(_ card: GameCard) -> Bool {
        boundaryPreferences.allows(card)
    }

    func isPropSelected(_ id: String) -> Bool {
        selectedPropIds.contains(id)
    }

    func hasAnyProp(from ids: [String]?) -> Bool {
        guard let ids, !ids.isEmpty else { return true }
        return !selectedPropIds.isDisjoint(with: ids)
    }

    func randomSelectedPropName(matching category: PropCategory?) -> String? {
        var pool = PropCatalog.allIncludingUser.filter { selectedPropIds.contains($0.id) }
        if let category {
            pool = pool.filter { $0.category == category }
        }
        return pool.randomElement()?.name
    }
}

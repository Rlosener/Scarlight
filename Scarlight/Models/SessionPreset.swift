import Foundation

struct SessionPreset: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var config: GameSessionConfig
    var isBuiltIn: Bool

    static let builtIns: [SessionPreset] = [
        SessionPreset(
            id: "builtin_soft_start",
            name: "Yumuşak Başlangıç",
            config: GameSessionConfig(
                selectedPropIds: [],
                enabledDeckTypes: [.hardTruth, .neverHaveI],
                playIntensityLevel: .soft,
                maxCardIntensity: 3,
                enabledContentTiers: [.beginning],
                enabledPhases: [.boldQuestion, .surpriseQuestion, .finalFocus],
                resetDrawnCardsOnStart: false
            ),
            isBuiltIn: true
        ),
        SessionPreset(
            id: "builtin_romantic",
            name: "Romantik Başlangıç",
            config: GameSessionConfig(
                selectedPropIds: [],
                enabledDeckTypes: [.neverHaveI, .hardTruth],
                playIntensityLevel: .soft,
                maxCardIntensity: 3,
                enabledContentTiers: [.beginning, .medium],
                enabledPhases: GameSessionConfig.defaultEnabledPhases
            ),
            isBuiltIn: true
        ),
        SessionPreset(
            id: "builtin_balanced_night",
            name: "Dengeli Gece",
            config: GameSessionConfig(
                selectedPropIds: [],
                enabledDeckTypes: [.neverHaveI, .hardTruth, .hardAction, .fantasyRole],
                playIntensityLevel: .medium,
                maxCardIntensity: 4,
                enabledContentTiers: [.beginning, .medium],
                enabledPhases: [.boldQuestion, .surpriseQuestion, .timedTask, .wheel, .roleDuo, .finalFocus],
                resetDrawnCardsOnStart: false
            ),
            isBuiltIn: true
        ),
        SessionPreset(
            id: "builtin_bar",
            name: "Bar",
            config: GameSessionConfig(
                selectedPropIds: [],
                enabledDeckTypes: Set(CardDeckType.socialPlayableDefaults),
                contentProfile: .social,
                playIntensityLevel: .soft,
                maxCardIntensity: 3,
                enabledContentTiers: [.beginning, .medium],
                enabledPhases: [.boldQuestion, .surpriseQuestion, .timedTask, .wheel],
                resetDrawnCardsOnStart: false
            ),
            isBuiltIn: true
        ),
        SessionPreset(
            id: "builtin_lighter",
            name: "Çakmak",
            config: PlayAtmosphere.defaultFriendsConfig,
            isBuiltIn: true
        ),
        SessionPreset(
            id: "builtin_three_player",
            name: "3 Kişilik",
            config: GameSessionConfig(
                selectedPropIds: [],
                enabledDeckTypes: [.neverHaveI, .hardTruth, .hardAction, .fantasyRole],
                playIntensityLevel: .medium,
                maxCardIntensity: 4,
                enabledContentTiers: [.beginning, .medium],
                enabledPhases: [.boldQuestion, .surpriseQuestion, .timedTask, .wheel, .dice, .roleDuo, .finalFocus],
                resetDrawnCardsOnStart: false
            ),
            isBuiltIn: true
        ),
        SessionPreset(
            id: "builtin_questions",
            name: "Sadece Sorular",
            config: GameSessionConfig(
                selectedPropIds: [],
                enabledDeckTypes: [.neverHaveI, .hardTruth],
                playIntensityLevel: .medium,
                maxCardIntensity: 4,
                enabledContentTiers: Set(ContentTier.allCases),
                enabledPhases: [.boldQuestion, .surpriseQuestion, .finalFocus]
            ),
            isBuiltIn: true
        ),
        SessionPreset(
            id: "builtin_full",
            name: "Tam Paket",
            config: .default,
            isBuiltIn: true
        ),
        SessionPreset(
            id: "builtin_no_props",
            name: "Propsuz",
            config: GameSessionConfig(
                selectedPropIds: [],
                enabledDeckTypes: Set(CardDeckType.playableDefaults),
                playIntensityLevel: .medium,
                maxCardIntensity: 4,
                enabledContentTiers: Set(ContentTier.allCases),
                enabledPhases: GameSessionConfig.defaultEnabledPhases
            ),
            isBuiltIn: true
        )
    ]
}

enum SessionPresetStore {
    private static let filename = "session_presets.json"
    private static let store = LocalJSONStore.shared

    static func allPresets() -> [SessionPreset] {
        SessionPreset.builtIns + loadUserPresets()
    }

    static func loadUserPresets() -> [SessionPreset] {
        guard store.fileExists(filename),
              let presets = try? store.load(from: filename, as: [SessionPreset].self) else {
            return []
        }
        return presets
    }

    static func replaceUserPresets(_ presets: [SessionPreset]) {
        let normalized = presets.map { preset in
            SessionPreset(
                id: preset.id,
                name: preset.name,
                config: preset.config,
                isBuiltIn: false
            )
        }
        try? store.save(normalized, to: filename)
    }

    @discardableResult
    static func saveUserPreset(name: String, config: GameSessionConfig) -> SessionPreset {
        var presets = loadUserPresets()
        let preset = SessionPreset(
            id: UUID().uuidString,
            name: name,
            config: config,
            isBuiltIn: false
        )
        presets.append(preset)
        try? store.save(presets, to: filename)
        return preset
    }

    @discardableResult
    static func duplicateAsUserPreset(_ preset: SessionPreset) -> SessionPreset {
        saveUserPreset(name: "\(preset.name) Kopya", config: preset.config)
    }

    static func deleteUserPreset(id: String) {
        var presets = loadUserPresets()
        presets.removeAll { $0.id == id }
        try? store.save(presets, to: filename)
    }
}

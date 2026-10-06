import Foundation

/// Oyun girişinde seçilen ortam modu.
enum PlayAtmosphere: String, CaseIterable, Identifiable, Hashable {
    case friends
    case lighter
    case hot

    var id: String { rawValue }

    /// Ortam seçim ekranında gösterilen seçenekler.
    static var selectionOptions: [PlayAtmosphere] {
        [.friends, .lighter, .hot]
    }

    var displayName: String {
        switch self {
        case .friends: return "Arkadaş Ortamı"
        case .lighter: return "Çakmak Oyunu"
        case .hot: return "Sıcak Ortam"
        }
    }

    var subtitle: String {
        switch self {
        case .friends:
            return "Barda agalarla — ortam soruları, flört ve seks yok."
        case .lighter:
            return "Çakmağı tut, soru yaz veya öner, birine ver — cevaptan sonra çakmak ona geçer."
        case .hot:
            return "Scarlight'ın yetişkin seti — cesur sorular, görevler ve fantezi."
        }
    }

    var icon: String {
        switch self {
        case .friends: return "wineglass.fill"
        case .lighter: return "flame.fill"
        case .hot: return "flame.circle.fill"
        }
    }

    var accentHint: String {
        switch self {
        case .friends: return "Bar Ben Hiç · Doğruluk · Cesaret"
        case .lighter: return "Soru yaz · Öner · Çakmağı pasla"
        case .hot: return "Ben Hiç · Hard · Rol · Eşya"
        }
    }

    var isLighterGame: Bool {
        self == .lighter
    }

    var usesScarlightEngine: Bool {
        !isLighterGame
    }

    var contentProfile: SessionContentProfile {
        switch self {
        case .friends, .lighter: return .social
        case .hot: return .intimate
        }
    }

    static var defaultFriendsConfig: GameSessionConfig {
        GameSessionConfig(
            selectedPropIds: [],
            enabledDeckTypes: Set(CardDeckType.socialPlayableDefaults),
            contentProfile: .social,
            playIntensityLevel: .soft,
            maxCardIntensity: 3,
            enabledContentTiers: [.beginning, .medium],
            enabledPhases: [.boldQuestion, .surpriseQuestion, .timedTask, .wheel]
        )
    }

    static var defaultHotConfig: GameSessionConfig {
        GameSessionConfig(
            selectedPropIds: [],
            enabledDeckTypes: Set(CardDeckType.playableDefaults),
            contentProfile: .intimate,
            playIntensityLevel: .hot,
            maxCardIntensity: 5,
            enabledContentTiers: [.medium, .hot],
            enabledPhases: GameSessionConfig.defaultEnabledPhases
        )
    }

    func baseConfig() -> GameSessionConfig {
        switch self {
        case .friends: return Self.defaultFriendsConfig
        case .hot: return Self.defaultHotConfig
        case .lighter: return Self.defaultFriendsConfig
        }
    }

    func preparedConfig() -> GameSessionConfig {
        var config = baseConfig()
        config.contentProfile = contentProfile

        guard contentProfile == .intimate else { return config }

        let playableProps = CardCatalog.propIdsWithCards()
        if config.selectedPropIds.isEmpty, !playableProps.isEmpty {
            config.selectedPropIds = playableProps
        }
        return config
    }
}

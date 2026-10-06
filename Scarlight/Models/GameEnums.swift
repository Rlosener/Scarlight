import Foundation

enum IntensityLevel: Int, Codable, CaseIterable, Identifiable {
    case soft = 1
    case medium = 2
    case hot = 3
    case hardcore = 4

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .soft: return "Soft"
        case .medium: return "Medium"
        case .hot: return "Ateşli"
        case .hardcore: return "Hardcore"
        }
    }

    var color: String {
        switch self {
        case .soft: return "#F2A6B3"
        case .medium: return "#E02B3F"
        case .hot: return "#B11226"
        case .hardcore: return "#6E1823"
        }
    }

    func displayName(for profile: SessionContentProfile) -> String {
        switch (self, profile) {
        case (.hot, .social): return "Cesur"
        case (.hardcore, .social): return "Ekstra"
        default: return displayName
        }
    }

    static func playableLevels(for profile: SessionContentProfile) -> [IntensityLevel] {
        profile == .social ? [.soft, .medium] : allCases
    }

    func accentColorHex(for profile: SessionContentProfile) -> String {
        if profile == .social {
            switch self {
            case .soft: return "#90CDF4"
            case .medium: return "#4299E1"
            case .hot, .hardcore: return "#2B6CB0"
            }
        }
        return color
    }

    var turnsRequired: Int {
        switch self {
        case .soft: return 12
        case .medium: return 15
        case .hot: return 18
        case .hardcore: return 0
        }
    }
}

enum Gender: String, Codable, CaseIterable, Identifiable {
    case female = "Kadın"
    case male = "Erkek"
    case other = "Diğer"

    var id: String { rawValue }
}

enum PlayerRole: String, Codable, CaseIterable, Identifiable {
    case dominant = "Baskın"
    case receptive = "Uyumlu"
    case mixed = "Karışık"
    case random = "Rastgele"

    var id: String { rawValue }
}

enum GamePhase: String, Codable, CaseIterable, Identifiable, Hashable {
    case boldQuestion = "Cesur Soru"
    case surpriseQuestion = "Sürpriz Soru"
    case timedTask = "Süreli Görev"
    case wheel = "Çark"
    case dice = "Zar"
    case roleDuo = "Rol Kartı"
    case finalFocus = "Final Focus"

    var id: String { rawValue }

    static func from(packKey: String) -> GamePhase {
        switch packKey {
        case "boldQuestion": return .boldQuestion
        case "surpriseQuestion": return .surpriseQuestion
        case "timedTask": return .timedTask
        case "wheel": return .wheel
        case "dice": return .dice
        case "roleDuo": return .roleDuo
        case "finalFocus": return .finalFocus
        default:
            if let match = GamePhase.allCases.first(where: { $0.rawValue == packKey }) {
                return match
            }
            return .boldQuestion
        }
    }

    static func playablePhases(for profile: SessionContentProfile) -> [GamePhase] {
        switch profile {
        case .social:
            return [.boldQuestion, .surpriseQuestion, .timedTask, .wheel]
        case .intimate:
            return allCases
        }
    }
}

enum CardType: String, Codable, CaseIterable, Identifiable {
    case question
    case task
    case surpriseQuestion
    case wheel
    case dice
    case roleDuo
    case penalty

    var id: String { rawValue }

    static func from(packKey: String) -> CardType {
        CardType(rawValue: packKey) ?? .question
    }
}

enum ActorRule: String, Codable, CaseIterable, Identifiable {
    case currentPlayer
    case wheelSelected
    case randomPlayer
    case previousPlayer

    var id: String { rawValue }
}

enum TargetRule: String, Codable, CaseIterable, Identifiable {
    case none
    case randomOther
    case partnerOrRandom
    case allPlayers
    case chosenByActor
    case chosenByWheel

    var id: String { rawValue }
}

enum SessionContentProfile: String, Codable, CaseIterable, Identifiable {
    /// Barda agalarla — flört/sex yok, sosyal soru ve görevler.
    case social
    /// Scarlight'ın yetişkin / seks konseptli içeriği.
    case intimate

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .social: return "Bar & Arkadaş"
        case .intimate: return "Sıcak & Özel"
        }
    }
}

enum CardDeckType: String, Codable, CaseIterable, Identifiable {
    case standard
    case neverHaveI
    case hardTruth
    case hardAction
    case fantasyRole
    case propTask
    case barNeverHaveI
    case barTruth
    case barDare

    var id: String { rawValue }

    /// Yetişkin oyun varsayılan desteleri.
    static var playableDefaults: [CardDeckType] {
        [.neverHaveI, .hardTruth, .hardAction, .fantasyRole, .propTask]
    }

    /// Bar / arkadaş ortamı desteleri.
    static var socialPlayableDefaults: [CardDeckType] {
        [.barNeverHaveI, .barTruth, .barDare]
    }

    var sessionContentProfile: SessionContentProfile {
        switch self {
        case .barNeverHaveI, .barTruth, .barDare:
            return .social
        case .standard:
            return .intimate
        default:
            return .intimate
        }
    }

    static func playableDefaults(for profile: SessionContentProfile) -> [CardDeckType] {
        switch profile {
        case .social: return socialPlayableDefaults
        case .intimate: return playableDefaults
        }
    }

    var displayName: String {
        switch self {
        case .standard: return "Klasik"
        case .neverHaveI: return "Ben Hiç"
        case .hardTruth: return "Hard Doğruluk"
        case .hardAction: return "Hard Aksiyon"
        case .fantasyRole: return "Fantezi / Rol"
        case .propTask: return "Eşya Görevleri"
        case .barNeverHaveI: return "Bar — Ben Hiç"
        case .barTruth: return "Bar — Doğruluk"
        case .barDare: return "Bar — Cesaret"
        }
    }

    var icon: String {
        switch self {
        case .standard: return "rectangle.stack"
        case .neverHaveI: return "hand.raised.fill"
        case .hardTruth: return "questionmark.bubble.fill"
        case .hardAction: return "timer"
        case .fantasyRole: return "theatermasks.fill"
        case .propTask: return "bag.fill"
        case .barNeverHaveI: return "wineglass.fill"
        case .barTruth: return "bubble.left.and.bubble.right.fill"
        case .barDare: return "bolt.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .standard: return "Sistem kartları"
        case .neverHaveI: return "Ben hiç… — yaptıysan süreli görev"
        case .hardTruth: return "Cesur doğruluk soruları, süresiz"
        case .hardAction: return "Süreli fiziksel görevler"
        case .fantasyRole: return "İkili rol ve fantezi senaryoları"
        case .propTask: return "Seçilen eşyalarla yapılan görevler"
        case .barNeverHaveI: return "Barda oynanır — komik ve cesur, +18 değil"
        case .barTruth: return "Arkadaş grubuna uygun doğruluk soruları"
        case .barDare: return "Hafif cesaret görevleri — masa oyunu temposu"
        }
    }

    var contentGroup: DeckContentGroup {
        DeckContentGroup.allCases.first { $0.deckTypes.contains(self) } ?? .questions
    }

    var isQuestionDeck: Bool {
        self == .neverHaveI || self == .hardTruth || self == .barNeverHaveI || self == .barTruth
    }
}

/// Kart editörü ve deste seçiminde soru / görev grupları.
enum DeckContentGroup: String, CaseIterable, Identifiable {
    case barSocial = "Bar & Arkadaş"
    case questions = "Sorular"
    case actionTasks = "Aksiyon Görevleri"
    case roleFantasy = "Rol & Fantezi"
    case propTasks = "Eşya Görevleri"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .barSocial: return "wineglass.fill"
        case .questions: return "questionmark.bubble.fill"
        case .actionTasks: return "timer"
        case .roleFantasy: return "theatermasks.fill"
        case .propTasks: return "bag.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .barSocial:
            return "Barda agalarla — sosyal, flörtsüz set"
        case .questions:
            return "Süresiz soru kartları"
        case .actionTasks:
            return "Süreli cesur görevler"
        case .roleFantasy:
            return "Rol oynama ve fantezi"
        case .propTasks:
            return "Eşya ile yapılan görevler"
        }
    }

    var deckTypes: [CardDeckType] {
        switch self {
        case .barSocial: return CardDeckType.socialPlayableDefaults
        case .questions: return [.neverHaveI, .hardTruth]
        case .actionTasks: return [.hardAction]
        case .roleFantasy: return [.fantasyRole]
        case .propTasks: return [.propTask]
        }
    }

    var contentProfile: SessionContentProfile {
        self == .barSocial ? .social : .intimate
    }

    /// Oyun kurulumunda gösterilecek gruplar.
    static func playableGroups(for profile: SessionContentProfile) -> [DeckContentGroup] {
        allCases.filter { group in
            group.contentProfile == profile &&
            group.deckTypes.contains { deck in
                CardDeckType.playableDefaults(for: profile).contains(deck)
            }
        }
    }

    /// Oyun kurulumunda gösterilecek gruplar (tüm intimate desteler).
    static var playableGroups: [DeckContentGroup] {
        playableGroups(for: .intimate)
    }
}

enum ContentTier: String, Codable, CaseIterable, Identifiable {
    case beginning
    case medium
    case hot

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .beginning: return "Başlangıç"
        case .medium: return "Orta"
        case .hot: return "Ateşli"
        }
    }

    func displayName(for profile: SessionContentProfile) -> String {
        switch (self, profile) {
        case (.hot, .social): return "Cesur"
        default: return displayName
        }
    }

    static func playableTiers(for profile: SessionContentProfile) -> [ContentTier] {
        profile == .social ? [.beginning, .medium] : allCases
    }

    var intensityLevel: IntensityLevel {
        switch self {
        case .beginning: return .soft
        case .medium: return .medium
        case .hot: return .hot
        }
    }
}

/// Kart ekleme: kaç oyunculu masada kullanılacağı
enum CardPlayerScope: String, CaseIterable, Identifiable {
    case twoPlayers
    case threePlayers
    case mixed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .twoPlayers: return "2 Kişi"
        case .threePlayers: return "3 Kişi"
        case .mixed: return "Karışık"
        }
    }

    var minPlayers: Int {
        switch self {
        case .twoPlayers, .mixed: return 2
        case .threePlayers: return 3
        }
    }

    var maxPlayers: Int {
        switch self {
        case .twoPlayers: return 2
        case .threePlayers, .mixed: return 3
        }
    }

    var hint: String {
        switch self {
        case .twoPlayers:
            return "Sıradaki oyuncu + rastgele biri. 2 ve 3 kişilik masada çıkar."
        case .threePlayers:
            return "Yalnızca 3 oyunculu masada çıkar. {diğer oyuncu} kullanılabilir."
        case .mixed:
            return "2 veya 3 oyunculu masada çıkar."
        }
    }

    static func from(minPlayers: Int?, maxPlayers: Int?) -> CardPlayerScope {
        let min = minPlayers ?? 2
        let max = maxPlayers ?? 2
        if min >= 3 && max <= 3 { return .threePlayers }
        if max <= 2 { return .twoPlayers }
        return .mixed
    }
}

/// Kart listelerinde filtre: tümü / 2 kişi / 3 kişi / karışık
enum PlayerCountFilter: String, CaseIterable, Identifiable {
    case all
    case twoPlayers
    case threePlayers
    case mixed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "Tümü"
        case .twoPlayers: return "2 Kişi"
        case .threePlayers: return "3 Kişi"
        case .mixed: return "2–3 Kişi"
        }
    }

    func matches(minPlayers: Int?, maxPlayers: Int?) -> Bool {
        switch self {
        case .all:
            return true
        case .twoPlayers:
            return GameCard.supportsPlayerCount(minPlayers: minPlayers, maxPlayers: maxPlayers, count: 2)
        case .threePlayers:
            return GameCard.supportsPlayerCount(minPlayers: minPlayers, maxPlayers: maxPlayers, count: 3)
        case .mixed:
            return CardPlayerScope.from(minPlayers: minPlayers, maxPlayers: maxPlayers)
                == correspondingScope
        }
    }

    private var correspondingScope: CardPlayerScope {
        switch self {
        case .all: return .mixed
        case .twoPlayers: return .twoPlayers
        case .threePlayers: return .threePlayers
        case .mixed: return .mixed
        }
    }
}

enum FateCategory: Int, Codable, CaseIterable, Identifiable {
    case question = 1
    case touch = 2
    case role = 3
    case dare = 4
    case partner = 5
    case wild = 6

    var id: Int { rawValue }

    static func from(diceValue: Int) -> FateCategory {
        FateCategory(rawValue: diceValue) ?? .question
    }

    var displayName: String {
        switch self {
        case .question: return "Soru"
        case .touch: return "Dokunuş"
        case .role: return "Rol"
        case .dare: return "Cesaret"
        case .partner: return "Partner"
        case .wild: return "Wild"
        }
    }

    var icon: String {
        switch self {
        case .question: return "bubble.left.fill"
        case .touch: return "hand.raised.fill"
        case .role: return "theatermasks.fill"
        case .dare: return "flame.fill"
        case .partner: return "person.2.fill"
        case .wild: return "sparkles"
        }
    }

    var color: String {
        switch self {
        case .question: return "#F2A6B3"
        case .touch: return "#E02B3F"
        case .role: return "#B11226"
        case .dare: return "#6E1823"
        case .partner: return "#E02B3F"
        case .wild: return "#FFD700"
        }
    }

    /// Wild seçiminde sunulan kategoriler (wild hariç)
    static var selectableCategories: [FateCategory] {
        allCases.filter { $0 != .wild }
    }
}

enum PenaltyType: String, Codable, CaseIterable, Identifiable {
    case related
    case refusal
    case wheel
    case timer
    case jokerLoss
    case doubleTurn
    case targetChoice

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .related: return "Hafif Alternatif"
        case .refusal: return "Red Cezası"
        case .wheel: return "Çark"
        case .timer: return "Süre"
        case .jokerLoss: return "Joker Kaybı"
        case .doubleTurn: return "Çift Tur"
        case .targetChoice: return "Hedef Seçimi"
        }
    }
}

import SwiftUI

enum ModeSceneTreatment: String, CaseIterable {
    case bar
    case flame
    case privateRoom
}

enum VisualEffectBudget: String, CaseIterable, Identifiable {
    case full
    case balanced
    case reduced

    var id: String { rawValue }

    static func resolved(performanceModeEnabled: Bool) -> VisualEffectBudget {
        performanceModeEnabled ? .reduced : .balanced
    }

    var allowsAmbientTexture: Bool {
        self != .reduced
    }

    var allowsPremiumGlow: Bool {
        self != .reduced
    }

    var shadowRadius: CGFloat {
        switch self {
        case .full: return 18
        case .balanced: return 12
        case .reduced: return 0
        }
    }

    var ambientOpacity: Double {
        switch self {
        case .full: return 1.0
        case .balanced: return 0.68
        case .reduced: return 0
        }
    }
}

struct ModeExperienceSpec: Identifiable, Hashable {
    let atmosphere: PlayAtmosphere
    let shortTitle: String
    let conceptName: String
    let heroTitle: String
    let moodLine: String
    let setupTitle: String
    let setupSubtitle: String
    let selectionBadge: String
    let primarySymbol: String
    let secondarySymbol: String
    let sceneTreatment: ModeSceneTreatment
    let motionLevel: Int
    let cardChromeLabel: String
    let actionHint: String
    let chips: [String]

    var id: String { atmosphere.id }

    var theme: SessionTheme {
        SessionTheme.forAtmosphere(atmosphere)
    }

    static func spec(for atmosphere: PlayAtmosphere) -> ModeExperienceSpec {
        switch atmosphere {
        case .friends:
            return ModeExperienceSpec(
                atmosphere: .friends,
                shortTitle: "Arkadaş",
                conceptName: "Bar Sosyali",
                heroTitle: "Arkadaş Ortamı",
                moodLine: "Hızlı, komik ve grup enerjisi yüksek soru akışı.",
                setupTitle: "Bar masası hazır mı?",
                setupSubtitle: "Soru ağırlıklı başlar; tempo yükseldikçe hafif cesaret kartları devreye girer.",
                selectionBadge: "Sosyal",
                primarySymbol: "wineglass.fill",
                secondarySymbol: "music.note.list",
                sceneTreatment: .bar,
                motionLevel: 1,
                cardChromeLabel: "BAR TURU",
                actionHint: "Soru önce, hareket sonra.",
                chips: ["Bar", "Soru", "Grup"]
            )
        case .lighter:
            return ModeExperienceSpec(
                atmosphere: .lighter,
                shortTitle: "Çakmak",
                conceptName: "Pas Döngüsü",
                heroTitle: "Çakmak Oyunu",
                moodLine: "Çakmağı tutan sorar, hedef cevaplar, sıra el değiştirir.",
                setupTitle: "Çakmak kimdeyse oyun onda.",
                setupSubtitle: "Holder, hedef ve reveal akışı tek döngüde net görünür.",
                selectionBadge: "Döngü",
                primarySymbol: "flame.fill",
                secondarySymbol: "arrow.triangle.2.circlepath",
                sceneTreatment: .flame,
                motionLevel: 2,
                cardChromeLabel: "ÇAKMAK TURU",
                actionHint: "Sor, açtır, devret.",
                chips: ["Holder", "Hedef", "Pas"]
            )
        case .hot:
            return ModeExperienceSpec(
                atmosphere: .hot,
                shortTitle: "Sıcak",
                conceptName: "Gece Modu",
                heroTitle: "Sıcak Ortam",
                moodLine: "Daha sinematik, sınırları net ve yoğunluğu kontrollü akış.",
                setupTitle: "Gece ayarlarını kilitle.",
                setupSubtitle: "Sınır, eşya ve yoğunluk seçimi netleşir; oyun kontrollü şekilde yükselir.",
                selectionBadge: "Premium",
                primarySymbol: "flame.circle.fill",
                secondarySymbol: "sparkles",
                sceneTreatment: .privateRoom,
                motionLevel: 2,
                cardChromeLabel: "SICAK TUR",
                actionHint: "Yavaş açılır, güçlü oynanır.",
                chips: ["Sınır", "Eşya", "Yoğunluk"]
            )
        }
    }
}

extension PlayAtmosphere {
    var experience: ModeExperienceSpec {
        ModeExperienceSpec.spec(for: self)
    }
}

private struct VisualEffectBudgetKey: EnvironmentKey {
    static let defaultValue: VisualEffectBudget = .balanced
}

extension EnvironmentValues {
    var visualEffectBudget: VisualEffectBudget {
        get { self[VisualEffectBudgetKey.self] }
        set { self[VisualEffectBudgetKey.self] = newValue }
    }
}

extension View {
    func visualEffectBudget(_ budget: VisualEffectBudget) -> some View {
        environment(\.visualEffectBudget, budget)
    }
}

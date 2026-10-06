import Foundation

/// Pozisyon zarı görevi (kader zarından bağımsız).
struct SurprisePosition: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let assetName: String
    let taskText: String
    let durationSeconds: Int

    var isTimed: Bool { true }
    var iconImageName: String { assetName }
}

enum SurprisePositionCatalog {
    /// Pozisyon zarı tetiklenme olasılığı (her kader atışında).
    static let triggerChance: Double = 0.28
    /// Üst üste pozisyon zarı gelmesin: en az bu kadar kader atışı arası.
    static let minFateRollsBetween: Int = 2
    /// Tüm zar fazında en fazla kaç pozisyon zarı.
    static let maxPerDicePhase: Int = 2

    static let all: [SurprisePosition] = [
        SurprisePosition(
            id: "surprise_oral",
            name: "Oral",
            assetName: "dice_oral",
            taskText: "Oral devam et.",
            durationSeconds: 120
        ),
        SurprisePosition(
            id: "surprise_licking",
            name: "Yalama",
            assetName: "dice_licking",
            taskText: "Partneri yala.",
            durationSeconds: 90
        ),
        SurprisePosition(
            id: "surprise_front",
            name: "Yüz yüze",
            assetName: "dice_front",
            taskText: "Yüz yüze pozisyona geç.",
            durationSeconds: 120
        ),
        SurprisePosition(
            id: "surprise_doggy",
            name: "Arkadan",
            assetName: "dice_doggy",
            taskText: "Arkadan pozisyona geç.",
            durationSeconds: 120
        ),
        SurprisePosition(
            id: "surprise_cowgirl",
            name: "Üstte",
            assetName: "dice_cowgirl",
            taskText: "Üstte pozisyona geç.",
            durationSeconds: 120
        ),
        SurprisePosition(
            id: "surprise_back",
            name: "Kaşık",
            assetName: "dice_back",
            taskText: "Kaşık pozisyona geç.",
            durationSeconds: 90
        ),
        SurprisePosition(
            id: "surprise_anal",
            name: "Anal",
            assetName: "dice_anal",
            taskText: "Anal pozisyona geç.",
            durationSeconds: 90
        ),
        SurprisePosition(
            id: "surprise_standing",
            name: "Ayakta",
            assetName: "dice_standing",
            taskText: "Ayakta devam et.",
            durationSeconds: 60
        ),
        SurprisePosition(
            id: "surprise_dog",
            name: "Diz üstü",
            assetName: "dice_dog",
            taskText: "Diz üstü pozisyona geç.",
            durationSeconds: 90
        ),
        SurprisePosition(
            id: "surprise_sex",
            name: "Ritim",
            assetName: "dice_sex",
            taskText: "Ritmi artır.",
            durationSeconds: 120
        ),
    ]

    static func randomPosition() -> SurprisePosition? {
        all.randomElement()
    }

    static func byAssetName(_ name: String) -> SurprisePosition? {
        all.first { $0.assetName == name }
    }
}

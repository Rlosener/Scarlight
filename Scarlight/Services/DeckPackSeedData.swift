import Foundation

/// JSON yüklenemezse kullanılan örnek deste kartları.
enum DeckPackSeedData {
    static func fallbackCards() -> [GameCard] {
        propTaskSamples + neverHaveISamples
    }

    private static let propTaskSamples: [GameCard] = [
        makePropCard(
            id: "prop_hot_001",
            text: "{AO}, {HO} üzerinde {item} ile 45 saniye uyarıcı görev yapacak.",
            category: .hotStimulating,
            propIds: ["hot_0", "hot_1"],
            tier: .medium,
            players: 2
        ),
        makePropCard(
            id: "prop_ed_001",
            text: "{AO}, {HO}'ya {item} ile 1 dakika masaj yapacak.",
            category: .edibleReachable,
            propIds: ["ed_4", "ed_5"],
            tier: .beginning,
            players: 2
        )
    ]

    private static let neverHaveISamples: [GameCard] = [
        makeNeverHaveI(
            id: "nhi_sample_001",
            text: "Ben hiç birine dokunmadan sadece bakarak yükseltmeye çalışmadım.",
            task: "{HO}'ya 30 saniye göz teması kur, konuşma",
            tier: .beginning,
            min: 2, max: 2
        )
    ]

    private static func makePropCard(
        id: String,
        text: String,
        category: PropCategory,
        propIds: [String],
        tier: ContentTier,
        players: Int
    ) -> GameCard {
        GameCard(
            id: id,
            title: "Eşya Görevi",
            type: .task,
            phase: .timedTask,
            intensity: tier == .hot ? 5 : 3,
            minIntensity: tier.intensityLevel,
            maxIntensity: tier == .hot ? .hardcore : tier.intensityLevel,
            durationSeconds: 60,
            targetRule: .randomOther,
            text: text,
            deckType: .propTask,
            contentTier: tier,
            minPlayers: players,
            maxPlayers: players,
            requiredPropIds: propIds,
            propCategory: category
        )
    }

    private static func makeNeverHaveI(
        id: String,
        text: String,
        task: String,
        tier: ContentTier,
        min: Int,
        max: Int
    ) -> GameCard {
        GameCard(
            id: id,
            title: "Ben Hiç",
            type: .question,
            phase: .boldQuestion,
            intensity: 3,
            minIntensity: tier.intensityLevel,
            maxIntensity: tier.intensityLevel,
            durationSeconds: tier == .beginning ? 30 : 60,
            targetRule: min >= 3 ? .randomOther : .randomOther,
            text: text,
            deckType: .neverHaveI,
            contentTier: tier,
            minPlayers: min,
            maxPlayers: max,
            onYesTask: task
        )
    }
}

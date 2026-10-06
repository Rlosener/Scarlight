import Foundation

/// Kart yazım önizlemesi için örnek oyuncu isimleri.
enum CardPreviewSamples {
    static let actorName = "Ahmet"
    static let targetName = "Su"
    static let thirdName = "Can"

    struct PreviewPlayers {
        let actor: Player
        let target: Player
        let third: Player?
        let all: [Player]
    }

    static func players(for scope: CardPlayerScope) -> PreviewPlayers {
        let actor = Player(name: actorName, gender: .male, role: .dominant, colorHex: "#E02B3F")
        let target = Player(name: targetName, gender: .female, role: .receptive, colorHex: "#F2A6B3")
        let third = Player(name: thirdName, gender: .male, role: .mixed, colorHex: "#B11226")

        switch scope {
        case .twoPlayers, .mixed:
            return PreviewPlayers(actor: actor, target: target, third: scope == .mixed ? third : nil, all: [actor, target, third])
        case .threePlayers:
            return PreviewPlayers(actor: actor, target: target, third: third, all: [actor, target, third])
        }
    }

    static func roleLegend(for scope: CardPlayerScope) -> String {
        switch scope {
        case .twoPlayers:
            return "\(actorName) → \(targetName)"
        case .threePlayers:
            return "\(actorName) → \(targetName) · \(thirdName)"
        case .mixed:
            return "\(actorName) → \(targetName) (3 kişide: \(thirdName))"
        }
    }
}

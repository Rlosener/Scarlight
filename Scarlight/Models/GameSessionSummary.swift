import Foundation

struct GameSessionSummary {
    let totalTurns: Int
    let finalIntensity: IntensityLevel
    let completedCycles: Int
    let durationSeconds: Int
    let passCount: Int
    let penaltyCount: Int
    let jokersUsed: Int
    let phasesPlayed: [String]
    let playerNames: [String]
    let enabledDeckCount: Int
    let propCount: Int
    let contentProfile: SessionContentProfile
    let enabledDeckNames: [String]
    let selectedPropNames: [String]
    let playerStats: [PlayerTurnStat]
    let replayPlayers: [Player]
    let replayConfig: GameSessionConfig?

    struct PlayerTurnStat: Identifiable, Codable, Equatable {
        let id: UUID
        let name: String
        let turnCount: Int
        let jokersRemaining: Int
    }

    var formattedDuration: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        if minutes > 0 { return "\(minutes) dk \(seconds) sn" }
        return "\(seconds) sn"
    }

    var shareText: String {
        var lines = [
            "Scarlight — Oturum Özeti",
            "Oyuncular: \(playerNames.joined(separator: ", "))",
            "Mod: \(contentProfile.displayName)",
            "Süre: \(formattedDuration)",
            "Tur: \(totalTurns) · Yoğunluk: \(finalIntensity.displayName)",
            "Pas: \(passCount) · Ceza: \(penaltyCount) · Joker: \(jokersUsed)"
        ]
        if !phasesPlayed.isEmpty {
            lines.append("Fazlar: \(phasesPlayed.joined(separator: ", "))")
        }
        if !enabledDeckNames.isEmpty {
            lines.append("Desteler: \(enabledDeckNames.joined(separator: ", "))")
        }
        if !selectedPropNames.isEmpty {
            lines.append("Eşyalar: \(selectedPropNames.joined(separator: ", "))")
        }
        return lines.joined(separator: "\n")
    }
}

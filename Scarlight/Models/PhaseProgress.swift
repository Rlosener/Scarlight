import Foundation

struct PhaseProgress: Codable, Equatable {
    var phase: GamePhase
    var completedTurns: [UUID: Int]
    var requiredTurnsPerPlayer: Int

    init(phase: GamePhase, players: [Player], requiredTurnsPerPlayer: Int = 3) {
        self.phase = phase
        self.completedTurns = Dictionary(uniqueKeysWithValues: players.map { ($0.id, 0) })
        self.requiredTurnsPerPlayer = requiredTurnsPerPlayer
    }

    func isComplete(for players: [Player]) -> Bool {
        players.allSatisfy { completedTurns[$0.id, default: 0] >= requiredTurnsPerPlayer }
    }
}

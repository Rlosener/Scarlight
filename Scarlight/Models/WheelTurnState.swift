import Foundation

struct WheelTurnState: Codable, Equatable {
    var completedTurns: [UUID: Int]
    var remainingBag: [UUID]
    var requiredTurnsPerPlayer: Int

    init(players: [Player], requiredTurnsPerPlayer: Int = 3) {
        self.completedTurns = Dictionary(uniqueKeysWithValues: players.map { ($0.id, 0) })
        self.requiredTurnsPerPlayer = requiredTurnsPerPlayer
        self.remainingBag = Self.createBag(from: players, turnsPerPlayer: requiredTurnsPerPlayer)
    }

    static func createBag(from players: [Player], turnsPerPlayer: Int) -> [UUID] {
        var bag: [UUID] = []
        for player in players {
            for _ in 0..<turnsPerPlayer {
                bag.append(player.id)
            }
        }
        return bag.shuffled()
    }

    mutating func refillBagIfNeeded(players: [Player]) {
        if remainingBag.isEmpty {
            remainingBag = Self.createBag(from: players, turnsPerPlayer: requiredTurnsPerPlayer)
        }
    }

    func isComplete() -> Bool {
        completedTurns.values.allSatisfy { $0 >= requiredTurnsPerPlayer }
    }
}

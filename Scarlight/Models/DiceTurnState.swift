import Foundation

enum DiceTurnKind: String, Codable, Equatable {
    case fate
    case position
}

struct DiceScheduledTurn: Codable, Equatable {
    let playerIndex: Int
    let kind: DiceTurnKind
}

struct DiceTurnState: Codable, Equatable {
    var schedule: [DiceScheduledTurn]
    var scheduleIndex: Int
    var fateCompleted: [UUID: Int]
    var positionCompleted: [UUID: Int]
    var requiredFatePerPlayer: Int
    var requiredPositionPerPlayer: Int

    init(
        players: [Player],
        fatePerPlayer: Int = 3,
        positionPerPlayer: Int = 2
    ) {
        self.requiredFatePerPlayer = fatePerPlayer
        self.requiredPositionPerPlayer = positionPerPlayer
        self.schedule = Self.buildSchedule(
            playerCount: players.count,
            fatePerPlayer: fatePerPlayer,
            positionPerPlayer: positionPerPlayer
        )
        self.scheduleIndex = 0
        self.fateCompleted = Dictionary(uniqueKeysWithValues: players.map { ($0.id, 0) })
        self.positionCompleted = Dictionary(uniqueKeysWithValues: players.map { ($0.id, 0) })
    }

    var currentTurn: DiceScheduledTurn? {
        guard scheduleIndex >= 0, scheduleIndex < schedule.count else { return nil }
        return schedule[scheduleIndex]
    }

    var nextTurn: DiceScheduledTurn? {
        guard scheduleIndex >= 0, scheduleIndex < schedule.count - 1 else { return nil }
        return schedule[scheduleIndex + 1]
    }

    var isComplete: Bool {
        scheduleIndex >= schedule.count
    }

    /// İlerleme çubuğu için oyuncu başına toplam tur.
    var requiredTurnsPerPlayer: Int {
        requiredFatePerPlayer + requiredPositionPerPlayer
    }

    func completedTurns(for playerId: UUID) -> Int {
        fateCompleted[playerId, default: 0] + positionCompleted[playerId, default: 0]
    }

    mutating func advanceSchedule() {
        scheduleIndex += 1
    }

    mutating func recordFateCompletion(playerId: UUID) {
        fateCompleted[playerId, default: 0] += 1
    }

    mutating func recordPositionCompletion(playerId: UUID) {
        positionCompleted[playerId, default: 0] += 1
    }

    /// Kader ve pozisyon turlarını aralara serpiştirir: 2 kader → 1 pozisyon döngüsü.
    static func buildSchedule(
        playerCount: Int,
        fatePerPlayer: Int,
        positionPerPlayer: Int
    ) -> [DiceScheduledTurn] {
        guard playerCount > 0 else { return [] }

        var fateTurns: [DiceScheduledTurn] = []
        var positionTurns: [DiceScheduledTurn] = []

        for _ in 0..<fatePerPlayer {
            for playerIndex in 0..<playerCount {
                fateTurns.append(DiceScheduledTurn(playerIndex: playerIndex, kind: .fate))
            }
        }
        for _ in 0..<positionPerPlayer {
            for playerIndex in 0..<playerCount {
                positionTurns.append(DiceScheduledTurn(playerIndex: playerIndex, kind: .position))
            }
        }

        var result: [DiceScheduledTurn] = []
        var fateIndex = 0
        var positionIndex = 0

        while fateIndex < fateTurns.count || positionIndex < positionTurns.count {
            for _ in 0..<2 {
                guard fateIndex < fateTurns.count else { break }
                result.append(fateTurns[fateIndex])
                fateIndex += 1
            }
            if positionIndex < positionTurns.count {
                result.append(positionTurns[positionIndex])
                positionIndex += 1
            }
        }

        return result
    }
}

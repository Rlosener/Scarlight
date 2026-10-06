import Foundation

enum GameSessionRestoreStore {
    private static let filename = "active_game_session.json"
    private static let store = LocalJSONStore.shared

    static func load() -> GameSessionSnapshot? {
        guard store.fileExists(filename) else { return nil }
        return try? store.load(from: filename, as: GameSessionSnapshot.self)
    }

    /// Bozuk veya uyumsuz kayıtları temizleyerek güvenli yükleme.
    static func loadValidated() -> GameSessionSnapshot? {
        guard let snapshot = load() else {
            clear()
            return nil
        }
        guard snapshot.version == 1, (0...3600).contains(snapshot.timerSeconds),
              snapshot.totalCompletedTurns >= 0, snapshot.completedFullCycles >= 0,
              snapshot.diceRollToken >= 0 else {
            clear()
            return nil
        }

        guard snapshot.players.count >= 2 else {
            clear()
            return nil
        }

        let playerIds = Set(snapshot.players.map(\.id))
        guard playerIds.count == snapshot.players.count else {
            clear()
            return nil
        }

        func validCounts(_ counts: [UUID: Int]) -> Bool {
            counts.allSatisfy { playerIds.contains($0.key) && $0.value >= 0 }
        }
        guard validCounts(snapshot.phaseProgress.completedTurns),
              snapshot.phaseProgress.requiredTurnsPerPlayer > 0,
              snapshot.players.allSatisfy({ $0.jokersRemaining >= 0 }),
              validCounts(snapshot.sessionTurnCounts) else {
            clear()
            return nil
        }

        if let actorId = snapshot.actorPlayerId, !playerIds.contains(actorId) {
            clear()
            return nil
        }
        if let targetId = snapshot.targetPlayerId, !playerIds.contains(targetId) {
            clear()
            return nil
        }
        if let rollerId = snapshot.diceRollerId, !playerIds.contains(rollerId) {
            clear()
            return nil
        }

        if let diceState = snapshot.diceState {
            let count = snapshot.players.count
            let invalidSchedule = diceState.schedule.contains { turn in
                turn.playerIndex < 0 || turn.playerIndex >= count
            }
            if invalidSchedule || diceState.scheduleIndex < 0 || diceState.scheduleIndex > diceState.schedule.count
                || !validCounts(diceState.fateCompleted) || !validCounts(diceState.positionCompleted)
                || !(0...100).contains(diceState.requiredFatePerPlayer)
                || !(0...100).contains(diceState.requiredPositionPerPlayer) {
                clear()
                return nil
            }
        }

        if let wheelState = snapshot.wheelState {
            let invalidTurn = wheelState.completedTurns.keys.contains { !playerIds.contains($0) }
            if invalidTurn || !validCounts(wheelState.completedTurns)
                || wheelState.remainingBag.contains(where: { !playerIds.contains($0) })
                || !(1...100).contains(wheelState.requiredTurnsPerPlayer) {
                clear()
                return nil
            }
        }

        let invalidSessionCounts = snapshot.sessionTurnCounts.keys.contains { !playerIds.contains($0) }
        if invalidSessionCounts {
            clear()
            return nil
        }

        return snapshot
    }

    @discardableResult
    static func save(_ snapshot: GameSessionSnapshot) -> Bool {
        do {
            try store.save(snapshot, to: filename)
            return true
        } catch {
            return false
        }
    }

    static func clear() {
        guard store.fileExists(filename) else { return }
        try? store.delete(filename)
    }
}

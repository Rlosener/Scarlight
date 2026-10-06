import Foundation
import Combine

enum LighterTurnPhase {
    case composing
    case waitingReveal
    case answering
}

enum LighterTurnDefaults {
    static func defaultTargetId(in players: [Player], excluding holderIndex: Int) -> UUID? {
        players.indices.first { $0 != holderIndex }.map { players[$0].id }
    }
}

@MainActor
final class LighterGameViewModel: ObservableObject {
    @Published var players: [Player]
    @Published var holderIndex: Int = 0
    @Published var questionText: String = ""
    @Published var selectedTargetId: UUID?
    @Published var turnPhase: LighterTurnPhase = .composing
    @Published var activeQuestion: String?

    private var answerTargetIndex: Int?

    let sessionId = UUID()

    init(players: [Player]) {
        self.players = players
        selectedTargetId = LighterTurnDefaults.defaultTargetId(in: players, excluding: holderIndex)
    }

    var holder: Player {
        players[holderIndex]
    }

    var answerTarget: Player? {
        guard let answerTargetIndex else { return nil }
        return players[answerTargetIndex]
    }

    var canGiveQuestion: Bool {
        guard turnPhase == .composing else { return false }
        let text = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        return !text.isEmpty && selectedTargetId != nil
    }

    func suggestQuestion() {
        guard TapThrottle.tryFire(key: "lighter.suggest", cooldown: 0.18) else { return }
        questionText = LighterQuestionPool.randomQuestion(excluding: questionText)
    }

    func giveQuestion() {
        guard TapThrottle.tryFire(key: "lighter.give", cooldown: 0.22) else { return }
        guard canGiveQuestion,
              let targetId = selectedTargetId,
              let targetIndex = players.firstIndex(where: { $0.id == targetId }) else { return }

        let text = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        activeQuestion = text
        answerTargetIndex = targetIndex
        turnPhase = .waitingReveal
    }

    func revealQuestion() {
        guard TapThrottle.tryFire(key: "lighter.reveal", cooldown: 0.22) else { return }
        guard turnPhase == .waitingReveal else { return }
        turnPhase = .answering
    }

    func completeAnswer() {
        guard TapThrottle.tryFire(key: "lighter.complete", cooldown: 0.22) else { return }
        guard let targetIndex = answerTargetIndex else { return }
        holderIndex = targetIndex
        questionText = ""
        selectedTargetId = LighterTurnDefaults.defaultTargetId(in: players, excluding: holderIndex)
        activeQuestion = nil
        answerTargetIndex = nil
        turnPhase = .composing
    }

    func selectTarget(_ player: Player) {
        guard player.id != holder.id, turnPhase == .composing else { return }
        selectedTargetId = player.id
    }
}

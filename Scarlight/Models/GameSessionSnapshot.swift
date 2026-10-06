import Foundation

struct GameSessionSnapshot: Codable, Equatable {
    let version: Int
    let players: [Player]
    let session: GameSessionConfig
    let currentPhase: GamePhase
    let phaseProgress: PhaseProgress
    let currentCard: GameCard?
    let currentPenalty: PenaltyCard?
    let actorPlayerId: UUID?
    let targetPlayerId: UUID?
    let gameState: GameState
    let timerSeconds: Int
    let wheelState: WheelTurnState?
    let diceState: DiceTurnState?
    let diceRollerId: UUID?
    let lastDiceRoll: Int?
    let diceRollToken: Int
    let showPartnerConsent: Bool
    let showSafeStop: Bool
    let renderedCardText: String
    let renderedPenaltyText: String
    let currentIntensityLevel: IntensityLevel
    let totalCompletedTurns: Int
    let showSurpriseTask: Bool
    let currentSurprisePosition: SurprisePosition?
    let renderedSurpriseTaskText: String
    let canRollPositionDice: Bool
    let canUseTimeBonus: Bool
    let activeItemName: String?
    let currentIntensity: Int
    let completedFullCycles: Int
    let awaitingPostHardcoreCycle: Bool
    let sessionTurnCounts: [UUID: Int]
    /// Tekrarları azaltmak için oynatılan kart geçmişi.
    let playedCardIds: Set<String>

    // Optional fields keep version 1 snapshots readable.
    let isTimedTaskActive: Bool?
    let sessionStartedAt: Date?
    let passCount: Int?
    let penaltyCount: Int?
    let initialJokerTotal: Int?
    let phasesVisited: Set<GamePhase>?

    init(
        version: Int = 1,
        players: [Player],
        session: GameSessionConfig,
        currentPhase: GamePhase,
        phaseProgress: PhaseProgress,
        currentCard: GameCard?,
        currentPenalty: PenaltyCard?,
        actorPlayerId: UUID?,
        targetPlayerId: UUID?,
        gameState: GameState,
        timerSeconds: Int,
        wheelState: WheelTurnState?,
        diceState: DiceTurnState?,
        diceRollerId: UUID?,
        lastDiceRoll: Int?,
        diceRollToken: Int,
        showPartnerConsent: Bool,
        showSafeStop: Bool,
        renderedCardText: String,
        renderedPenaltyText: String,
        currentIntensityLevel: IntensityLevel,
        totalCompletedTurns: Int,
        showSurpriseTask: Bool,
        currentSurprisePosition: SurprisePosition?,
        renderedSurpriseTaskText: String,
        canRollPositionDice: Bool,
        canUseTimeBonus: Bool,
        activeItemName: String?,
        currentIntensity: Int,
        completedFullCycles: Int,
        awaitingPostHardcoreCycle: Bool,
        sessionTurnCounts: [UUID: Int],
        playedCardIds: Set<String> = [],
        isTimedTaskActive: Bool? = nil,
        sessionStartedAt: Date? = nil,
        passCount: Int? = nil,
        penaltyCount: Int? = nil,
        initialJokerTotal: Int? = nil,
        phasesVisited: Set<GamePhase>? = nil
    ) {
        self.version = version
        self.players = players
        self.session = session
        self.currentPhase = currentPhase
        self.phaseProgress = phaseProgress
        self.currentCard = currentCard
        self.currentPenalty = currentPenalty
        self.actorPlayerId = actorPlayerId
        self.targetPlayerId = targetPlayerId
        self.gameState = gameState
        self.timerSeconds = timerSeconds
        self.wheelState = wheelState
        self.diceState = diceState
        self.diceRollerId = diceRollerId
        self.lastDiceRoll = lastDiceRoll
        self.diceRollToken = diceRollToken
        self.showPartnerConsent = showPartnerConsent
        self.showSafeStop = showSafeStop
        self.renderedCardText = renderedCardText
        self.renderedPenaltyText = renderedPenaltyText
        self.currentIntensityLevel = currentIntensityLevel
        self.totalCompletedTurns = totalCompletedTurns
        self.showSurpriseTask = showSurpriseTask
        self.currentSurprisePosition = currentSurprisePosition
        self.renderedSurpriseTaskText = renderedSurpriseTaskText
        self.canRollPositionDice = canRollPositionDice
        self.canUseTimeBonus = canUseTimeBonus
        self.activeItemName = activeItemName
        self.currentIntensity = currentIntensity
        self.completedFullCycles = completedFullCycles
        self.awaitingPostHardcoreCycle = awaitingPostHardcoreCycle
        self.sessionTurnCounts = sessionTurnCounts
        self.playedCardIds = playedCardIds
        self.isTimedTaskActive = isTimedTaskActive
        self.sessionStartedAt = sessionStartedAt
        self.passCount = passCount
        self.penaltyCount = penaltyCount
        self.initialJokerTotal = initialJokerTotal
        self.phasesVisited = phasesVisited
    }
}

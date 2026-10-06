import Foundation
import Combine

class GameEngineViewModel: ObservableObject {
    let sessionId = UUID()
    @Published var saveErrorMessage: String?
    @Published var currentPhase: GamePhase = .boldQuestion
    @Published var phaseProgress: PhaseProgress
    @Published var currentCard: GameCard?
    @Published var currentPenalty: PenaltyCard?
    @Published var actorPlayer: Player?
    @Published var targetPlayer: Player?
    @Published var gameState: GameState = .idle
    @Published var timerSeconds: Int = 0
    @Published var wheelState: WheelTurnState?
    @Published var diceState: DiceTurnState?
    @Published var diceRoller: Player?
    @Published var lastDiceRoll: Int?
    @Published var diceRollToken: Int = 0
    @Published var showPartnerConsent: Bool = false
    @Published var showSafeStop: Bool = false
    @Published var renderedCardText: String = ""
    @Published var renderedPenaltyText: String = ""
    @Published var currentIntensityLevel: IntensityLevel = .soft
    @Published var totalCompletedTurns: Int = 0
    @Published var showSurpriseTask: Bool = false
    @Published var currentSurprisePosition: SurprisePosition?
    @Published var renderedSurpriseTaskText: String = ""

    var currentDiceTurnKind: DiceTurnKind? {
        diceState?.currentTurn?.kind
    }

    var isDiceFateTurn: Bool { currentDiceTurnKind == .fate }
    var isDicePositionTurn: Bool { currentDiceTurnKind == .position }
    @Published var canUseTimeBonus: Bool = true
    @Published var activeItemName: String?
    @Published var sessionSummary: GameSessionSummary?
    /// Görev ekranında süre zorunlu mu (süreli kart, Ben Hiç görevi, pozisyon zarı vb.)
    @Published private(set) var isTimedTaskActive: Bool = false

    private var sessionStartedAt = Date()
    private var passCount = 0
    private var penaltyCount = 0
    private var initialJokerTotal = 0
    private var phasesVisited: Set<GamePhase> = []

    private var players: [Player]
    private var session: GameSessionConfig
    private var gameEngine = GameEngine()
    private var timerCancellable: AnyCancellable?
    private var timerDeadline: TimeInterval?
    private var resumeTimerAfterStop = false
    private var countdownSoundPlayed = false
    private var currentIntensity: Int = 3
    private var completedFullCycles = 0
    private var awaitingPostHardcoreCycle = false
    private var sessionTurnCounts: [UUID: Int] = [:]
    private let store = LocalJSONStore.shared
    private var isApplyingRestoredSnapshot = false
    private var isSnapshotEnabled = true

    var allPlayers: [Player] { players }

    var playedCardIdsForTesting: Set<String> {
        gameEngine.playedCardIdsSnapshot()
    }

    /// Görevi şu an yapacak oyuncu.
    var currentTurnPlayer: Player? { actorPlayer }

    /// Bu karttan sonra sıradaki oyuncu (faz tur mantığına göre).
    var nextTurnPlayer: Player? {
        guard !players.isEmpty else { return nil }
        let required = phaseTurnsRequired

        if let actor = actorPlayer,
           let index = players.firstIndex(where: { $0.id == actor.id }) {
            for offset in 1..<players.count {
                let candidate = players[(index + offset) % players.count]
                if phaseTurnCount(for: candidate.id) < required {
                    return candidate
                }
            }
            return players[(index + 1) % players.count]
        }

        if currentPhase == .dice, let state = diceState, let nextTurn = state.nextTurn {
            return players[nextTurn.playerIndex % players.count]
        }

        return resolveTurnPlayer()
    }

    var phaseTurnsRequired: Int {
        switch currentPhase {
        case .wheel:
            return wheelState?.requiredTurnsPerPlayer ?? phaseProgress.requiredTurnsPerPlayer
        case .dice:
            return diceState?.requiredTurnsPerPlayer ?? phaseProgress.requiredTurnsPerPlayer
        default:
            return phaseProgress.requiredTurnsPerPlayer
        }
    }

    func phaseTurnCount(for playerId: UUID) -> Int {
        switch currentPhase {
        case .wheel:
            return wheelState?.completedTurns[playerId, default: 0] ?? 0
        case .dice:
            return diceState?.completedTurns(for: playerId) ?? 0
        default:
            return phaseProgress.completedTurns[playerId, default: 0]
        }
    }

    var showsQuickAddButton: Bool {
        guard !showPartnerConsent, gameState != .roundSetup else { return false }
        switch gameState {
        case .cardDisplay, .neverHaveIChoice, .timerRunning, .waitingForCompletion:
            return true
        default:
            return false
        }
    }

    var thirdPlayer: Player? {
        guard let actor = actorPlayer else { return nil }
        return players.first { $0.id != actor.id && $0.id != targetPlayer?.id }
    }

    var isTwoPlayerGame: Bool { players.count == 2 }

    /// Kart başlığında gösterilecek hedef — 2 kişide her zaman diğer oyuncu.
    var displayTargetPlayer: Player? {
        if let targetPlayer { return targetPlayer }
        if let actor = actorPlayer, let partner = resolvePartner(for: actor) {
            return partner
        }
        guard isTwoPlayerGame, let actor = actorPlayer else { return nil }
        return players.first { $0.id != actor.id }
    }

    var displayTargetName: String? { displayTargetPlayer?.name }

    private var cardsChangeObserver: NSObjectProtocol?

    var currentSessionConfig: GameSessionConfig { session }

    init(players: [Player], session: GameSessionConfig = .default) {
        self.players = players
        var config = session
        if config.partnerPlayerIds.isEmpty, players.count == 3 {
            config.partnerPlayerIds = PartnerPairingStore.load()
        }
        self.session = config
        self.currentIntensityLevel = config.playIntensityLevel
        self.currentIntensity = config.maxCardIntensity
        self.sessionTurnCounts = Dictionary(uniqueKeysWithValues: players.map { ($0.id, 0) })
        self.initialJokerTotal = players.reduce(0) { $0 + $1.jokersRemaining }
        let startPhase = GameSessionConfig.firstEnabledPhase(in: config)
        self.currentPhase = startPhase
        self.phaseProgress = PhaseProgress(phase: startPhase, players: players)
        loadGameData()
        applyRepeatPolicyFromConfig()
        cardsChangeObserver = NotificationCenter.default.addObserver(
            forName: .cardsDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reloadCardsFromStore()
        }
    }

    convenience init(restoring snapshot: GameSessionSnapshot) {
        self.init(players: snapshot.players, session: snapshot.session)
        gameEngine.seedPlayedCardIds(snapshot.playedCardIds)
        applyRestoredSnapshot(snapshot)
    }

    deinit {
        if let cardsChangeObserver {
            NotificationCenter.default.removeObserver(cardsChangeObserver)
        }
    }

    func startGameIfNeeded() {
        guard gameState == .idle else { return }
        startGame()
    }

    func discardSavedSession() {
        isSnapshotEnabled = false
        stopTimer()
        GameSessionRestoreStore.clear()
    }

    private func player(with id: UUID?) -> Player? {
        guard let id else { return nil }
        return players.first { $0.id == id }
    }

    private func restoredDisplayState(from state: GameState, hasPenalty: Bool) -> GameState {
        if state == .timerRunning {
            return hasPenalty ? .penaltyDisplay : .cardDisplay
        }
        return state
    }

    private func applyRestoredSnapshot(_ snapshot: GameSessionSnapshot) {
        isApplyingRestoredSnapshot = true
        defer {
            isApplyingRestoredSnapshot = false
            persistSnapshot()
        }

        players = snapshot.players
        session = snapshot.session
        currentPhase = snapshot.currentPhase
        phaseProgress = snapshot.phaseProgress
        currentCard = snapshot.currentCard
        currentPenalty = snapshot.currentPenalty
        actorPlayer = player(with: snapshot.actorPlayerId)
        targetPlayer = player(with: snapshot.targetPlayerId)
        gameState = restoredDisplayState(from: snapshot.gameState, hasPenalty: snapshot.currentPenalty != nil)
        timerSeconds = snapshot.timerSeconds
        wheelState = snapshot.wheelState
        diceState = snapshot.diceState
        diceRoller = player(with: snapshot.diceRollerId)
        lastDiceRoll = snapshot.lastDiceRoll
        diceRollToken = snapshot.diceRollToken
        showPartnerConsent = snapshot.showPartnerConsent
        showSafeStop = snapshot.showSafeStop
        renderedCardText = snapshot.renderedCardText
        renderedPenaltyText = snapshot.renderedPenaltyText
        currentIntensityLevel = snapshot.currentIntensityLevel
        totalCompletedTurns = snapshot.totalCompletedTurns
        showSurpriseTask = snapshot.showSurpriseTask
        currentSurprisePosition = snapshot.currentSurprisePosition
        renderedSurpriseTaskText = snapshot.renderedSurpriseTaskText
        canUseTimeBonus = snapshot.canUseTimeBonus
        activeItemName = snapshot.activeItemName
        currentIntensity = snapshot.currentIntensity
        completedFullCycles = snapshot.completedFullCycles
        awaitingPostHardcoreCycle = snapshot.awaitingPostHardcoreCycle
        sessionTurnCounts = snapshot.sessionTurnCounts
        sessionStartedAt = snapshot.sessionStartedAt ?? Date()
        passCount = snapshot.passCount ?? 0
        penaltyCount = snapshot.penaltyCount ?? 0
        initialJokerTotal = snapshot.initialJokerTotal ?? initialJokerTotal
        phasesVisited = snapshot.phasesVisited ?? [snapshot.currentPhase]
        isTimedTaskActive = resolveTimedTaskActive(from: snapshot)
    }

    private func resolveTimedTaskActive(from snapshot: GameSessionSnapshot) -> Bool {
        if let active = snapshot.isTimedTaskActive { return active }
        if snapshot.currentPenalty != nil {
            return true
        }
        if snapshot.currentSurprisePosition != nil, snapshot.currentCard == nil {
            return true
        }
        if snapshot.currentCard?.isTimedTaskCard == true {
            return true
        }
        if snapshot.currentCard?.isNeverHaveI == true,
           [.cardDisplay, .timerRunning, .waitingForCompletion].contains(snapshot.gameState),
           snapshot.timerSeconds > 0 {
            return true
        }
        return false
    }

    var requiresTaskTimer: Bool {
        if currentPenalty != nil {
            return true
        }
        if isSurpriseTimed {
            return true
        }
        return isTimedTaskActive
    }

    private func makeSnapshot() -> GameSessionSnapshot {
        GameSessionSnapshot(
            players: players,
            session: session,
            currentPhase: currentPhase,
            phaseProgress: phaseProgress,
            currentCard: currentCard,
            currentPenalty: currentPenalty,
            actorPlayerId: actorPlayer?.id,
            targetPlayerId: targetPlayer?.id,
            gameState: gameState,
            timerSeconds: timerSeconds,
            wheelState: wheelState,
            diceState: diceState,
            diceRollerId: diceRoller?.id,
            lastDiceRoll: lastDiceRoll,
            diceRollToken: diceRollToken,
            showPartnerConsent: showPartnerConsent,
            showSafeStop: showSafeStop,
            renderedCardText: renderedCardText,
            renderedPenaltyText: renderedPenaltyText,
            currentIntensityLevel: currentIntensityLevel,
            totalCompletedTurns: totalCompletedTurns,
            showSurpriseTask: showSurpriseTask,
            currentSurprisePosition: currentSurprisePosition,
            renderedSurpriseTaskText: renderedSurpriseTaskText,
            canRollPositionDice: false,
            canUseTimeBonus: canUseTimeBonus,
            activeItemName: activeItemName,
            currentIntensity: currentIntensity,
            completedFullCycles: completedFullCycles,
            awaitingPostHardcoreCycle: awaitingPostHardcoreCycle,
            sessionTurnCounts: sessionTurnCounts,
            playedCardIds: gameEngine.playedCardIdsSnapshot(),
            isTimedTaskActive: isTimedTaskActive,
            sessionStartedAt: sessionStartedAt,
            passCount: passCount,
            penaltyCount: penaltyCount,
            initialJokerTotal: initialJokerTotal,
            phasesVisited: phasesVisited
        )
    }

    private func applyRepeatPolicyFromConfig() {
        if session.resetDrawnCardsOnStart {
            PlayedCardHistoryStore.clear()
            gameEngine.resetPlayedCards()
            return
        }
        let previous = PlayedCardHistoryStore.load()
        if !previous.isEmpty {
            gameEngine.seedPlayedCardIds(previous)
        }
    }

    private func persistSnapshot() {
        guard isSnapshotEnabled, !isApplyingRestoredSnapshot else { return }
        guard gameState != .idle, gameState != .gameComplete else { return }
        if !GameSessionRestoreStore.save(makeSnapshot()) {
            saveErrorMessage = "Oyun bu cihaza kaydedilemedi. Boş depolama alanını kontrol edin; uygulamayı kapatırsanız son ilerleme kaybolabilir."
        }
    }

    private var selectionContext: CardSelectionContext {
        CardSelectionContext(
            session: session,
            playerCount: players.count,
            activeItemName: activeItemName
        )
    }

    func reloadCardsFromStore() {
        loadGameData()
    }

    private func loadGameData() {
        gameEngine.loadCards(CardCatalog.loadForGameplay())
        gameEngine.loadPenalties(PenaltyCatalog.loadForGameplay())
    }

    func startGame() {
        sessionStartedAt = Date()
        phasesVisited.insert(currentPhase)
        drawNextCard()
    }

    func drawNextCard() {
        canUseTimeBonus = true

        if currentPhase == .wheel {
            startWheelPhase()
            return
        }

        if currentPhase == .dice {
            startDicePhase()
            return
        }

        guard let card = gameEngine.selectCard(
            for: currentPhase,
            intensity: currentIntensity,
            intensityLevel: currentIntensityLevel,
            context: selectionContext
        ) else {
            advancePhase()
            return
        }

        presentCard(card)
    }

    private func presentCard(_ card: GameCard) {
        stopTimer()
        currentCard = card
        assignCardRoles(for: card)
        applyCardPresentation(card)
        PlayedCardHistoryStore.save(gameEngine.playedCardIdsSnapshot())
    }

    /// Faz ilerlemesine göre sırası gelen oyuncu.
    private func resolveTurnPlayer() -> Player? {
        guard !players.isEmpty else { return nil }
        let minCompleted = players.map { phaseProgress.completedTurns[$0.id, default: 0] }.min() ?? 0
        return players.first { phaseProgress.completedTurns[$0.id, default: 0] == minCompleted }
    }

    private func assignCardRoles(for card: GameCard, forcedActor: Player? = nil) {
        if let forcedActor {
            actorPlayer = forcedActor
        } else {
            actorPlayer = gameEngine.selectActor(
                rule: card.actorRule,
                currentPlayer: resolveTurnPlayer(),
                players: players,
                wheelSelectedId: nil
            )
        }

        if card.isTwoPlayerContent || isTwoPlayerGame || players.count == 3 {
            targetPlayer = resolvePartner(for: actorPlayer) ?? pickRandomOther(than: actorPlayer)
        } else {
            targetPlayer = gameEngine.selectTarget(
                rule: card.targetRule,
                actor: actorPlayer,
                players: players,
                partnerId: resolvePartner(for: actorPlayer)?.id
            )
            let combinedText = [card.text, card.onYesTask].compactMap { $0 }.joined(separator: " ")
            if targetPlayer == nil,
               PlaceholderRenderer.textReferencesTarget(combinedText)
                || PlaceholderRenderer.textReferencesThird(combinedText) {
                targetPlayer = resolvePartner(for: actorPlayer) ?? pickRandomOther(than: actorPlayer)
            }
        }
    }

    private func resolvePartner(for actor: Player?) -> Player? {
        guard let actor else { return nil }

        if players.count == 2 {
            return players.first { $0.id != actor.id }
        }

        let pair = session.partnerPairSet
        guard players.count == 3, pair.count == 2 else { return nil }

        if pair.contains(actor.id) {
            return players.first { $0.id != actor.id && pair.contains($0.id) }
        }

        return players.first { pair.contains($0.id) }
    }

    private func recordSessionTurn(for playerId: UUID?) {
        guard let playerId else { return }
        sessionTurnCounts[playerId, default: 0] += 1
    }

    private func buildSessionSummary() -> GameSessionSummary {
        let remainingJokers = players.reduce(0) { $0 + $1.jokersRemaining }
        let duration = max(0, Int(Date().timeIntervalSince(sessionStartedAt)))
        return GameSessionSummary(
            totalTurns: totalCompletedTurns,
            finalIntensity: currentIntensityLevel,
            completedCycles: completedFullCycles,
            durationSeconds: duration,
            passCount: passCount,
            penaltyCount: penaltyCount,
            jokersUsed: max(0, initialJokerTotal - remainingJokers),
            phasesPlayed: phasesVisited.map(\.rawValue).sorted(),
            playerNames: players.map(\.name),
            enabledDeckCount: session.enabledDeckTypes.count,
            propCount: session.selectedPropIds.count,
            contentProfile: session.contentProfile,
            enabledDeckNames: session.enabledDeckTypes
                .map(\.displayName)
                .sorted(),
            selectedPropNames: session.selectedPropIds
                .compactMap { PropCatalog.resolveProp(id: $0)?.name }
                .sorted(),
            playerStats: players.map { player in
                GameSessionSummary.PlayerTurnStat(
                    id: player.id,
                    name: player.name,
                    turnCount: sessionTurnCounts[player.id, default: 0],
                    jokersRemaining: player.jokersRemaining
                )
            },
            replayPlayers: players,
            replayConfig: session
        )
    }

    private func finishSession() {
        guard gameState != .gameComplete else { return }
        stopTimer()
        currentCard = nil
        currentPenalty = nil
        showPartnerConsent = false
        showSurpriseTask = false
        let summary = buildSessionSummary()
        sessionSummary = summary
        PlayedHistoryStore.append(summary)
        gameState = .gameComplete
        GameSessionRestoreStore.clear()
        FeedbackManager.success()
    }

    private func pickRandomOther(than actor: Player?) -> Player? {
        guard let actor else { return nil }
        let others = players.filter { $0.id != actor.id }
        return others.randomElement()
    }

    private func applyCardPresentation(_ card: GameCard) {
        if card.text.contains("{item}") || card.effectiveDeckType == .propTask {
            activeItemName = session.randomSelectedPropName(matching: card.propCategory)
        } else {
            activeItemName = nil
        }

        isTimedTaskActive = card.isTimedTaskCard
        renderedCardText = renderCardText(
            card.text,
            duration: card.durationSeconds,
            isTimed: isTimedTaskActive
        )
        timerSeconds = isTimedTaskActive ? taskDurationSeconds(for: card) : 0
        canUseTimeBonus = true

        if card.requiresTargetConsent && targetPlayer != nil {
            showPartnerConsent = true
            gameState = .partnerConsent
        } else if card.isNeverHaveI {
            gameState = .neverHaveIChoice
            FeedbackManager.cardReveal()
        } else {
            gameState = .cardDisplay
            FeedbackManager.cardReveal()
        }
        persistSnapshot()
    }

    private func renderCardText(_ text: String, duration: Int, isTimed: Bool = true) -> String {
        PlaceholderRenderer.renderGameplayText(
            text,
            duration: duration,
            phase: currentPhase,
            itemName: activeItemName,
            stripDuration: isTimed
        )
    }

    func answerNeverHaveINo() {
        FeedbackManager.lightTap()
        completeCard()
    }

    func answerNeverHaveIYes() {
        guard let card = currentCard, let task = card.onYesTask else {
            completeCard()
            return
        }
        FeedbackManager.warning()
        isTimedTaskActive = true
        timerSeconds = taskDurationSeconds(for: card)
        renderedCardText = renderCardText(
            task,
            duration: card.durationSeconds,
            isTimed: true
        )
        gameState = .cardDisplay
        persistSnapshot()
    }

    private func taskDurationSeconds(for card: GameCard) -> Int {
        let defaults = TimerDefaultsStore.load()
        let base = card.durationSeconds > 0
            ? card.durationSeconds
            : defaults.seconds(for: card.contentTier)
        return max(base, defaults.penaltyFloorSeconds)
    }

    func startTimer() {
        guard !showSafeStop, [.cardDisplay, .penaltyDisplay].contains(gameState) else { return }
        if timerSeconds <= 0 {
            if let card = currentCard {
                timerSeconds = taskDurationSeconds(for: card)
            } else if let position = currentSurprisePosition {
                timerSeconds = max(position.durationSeconds, 30)
            } else if let penalty = currentPenalty {
                timerSeconds = max(penalty.durationSeconds, 30)
            } else {
                timerSeconds = 60
            }
        }
        gameState = .timerRunning
        countdownSoundPlayed = false
        FeedbackManager.lightTap()
        persistSnapshot()

        timerDeadline = ProcessInfo.processInfo.systemUptime + TimeInterval(timerSeconds)
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimer()
            }
    }

    /// Monotonic time avoids drift when rendering or file IO delays a timer callback.
    func updateTimer(at uptime: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        guard gameState == .timerRunning, let deadline = timerDeadline else { return }
        let remaining = max(0, Int(ceil(deadline - uptime)))
        guard remaining != timerSeconds else { return }
        timerSeconds = remaining
        if remaining == 0 {
            stopTimer()
            gameState = .waitingForCompletion
            FeedbackManager.timerEnded()
            persistSnapshot()
        } else if remaining <= 5, !countdownSoundPlayed {
            countdownSoundPlayed = true
            FeedbackManager.timerWarning()
        } else if remaining < 5 {
            FeedbackManager.selection()
        }
        // Save at transitions and scene changes instead of writing JSON every second.
    }

    func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
        timerDeadline = nil
    }

    func completeCard() {
        guard TapThrottle.tryFire(key: "game.completeCard", cooldown: 0.22) else { return }
        FeedbackManager.success()
        stopTimer()
        isTimedTaskActive = false

        if currentPhase == .dice, diceState != nil {
            completeDiceCard()
            return
        }

        recordSessionTurn(for: actorPlayer?.id)
        checkIntensityLevelUp()
        currentCard = nil
        currentPenalty = nil
        let phaseAdvanced = incrementProgress()
        if !phaseAdvanced {
            drawNextCard()
        }
    }

    func useJoker() {
        guard TapThrottle.tryFire(key: "game.useJoker", cooldown: 0.22) else { return }
        guard let actorId = actorPlayer?.id,
              let playerIndex = players.firstIndex(where: { $0.id == actorId }),
              players[playerIndex].jokersRemaining > 0 else {
            return
        }

        FeedbackManager.warning()
        stopTimer()
        isTimedTaskActive = false
        players[playerIndex].jokersRemaining -= 1
        currentPenalty = nil
        if currentPhase == .dice, diceState != nil {
            completeDiceCard()
            return
        }
        if currentPhase == .wheel, wheelState != nil {
            completeWheelCard()
            return
        }

        recordSessionTurn(for: actorPlayer?.id)
        checkIntensityLevelUp()
        currentCard = nil
        let phaseAdvanced = incrementProgress()
        if !phaseAdvanced {
            drawNextCard()
        }
    }

    private func returnToDiceRoll() {
        currentCard = nil
        currentPenalty = nil
        updateDiceRoller()
        diceRollToken += 1
        gameState = .diceRoll
        persistSnapshot()
    }

    func addTimeBonus() {
        guard canUseTimeBonus else { return }
        FeedbackManager.lightTap()
        timerSeconds += 30
        if let deadline = timerDeadline { timerDeadline = deadline + 30 }
        canUseTimeBonus = false
        persistSnapshot()
    }

    private func checkIntensityLevelUp() {
        totalCompletedTurns += 1

        if session.contentProfile == .social {
            if currentIntensityLevel == .soft,
               totalCompletedTurns >= IntensityLevel.soft.turnsRequired {
                currentIntensityLevel = .medium
                FeedbackManager.success()
            }
            return
        }

        switch currentIntensityLevel {
        case .soft:
            if totalCompletedTurns >= IntensityLevel.soft.turnsRequired {
                currentIntensityLevel = .medium
                FeedbackManager.success()
            }
        case .medium:
            if totalCompletedTurns >= (IntensityLevel.soft.turnsRequired + IntensityLevel.medium.turnsRequired) {
                currentIntensityLevel = .hot
                FeedbackManager.success()
            }
        case .hot:
            if totalCompletedTurns >= (IntensityLevel.soft.turnsRequired + IntensityLevel.medium.turnsRequired + IntensityLevel.hot.turnsRequired) {
                currentIntensityLevel = .hardcore
                FeedbackManager.success()
            }
        case .hardcore:
            break
        }
    }

    func manuallySetIntensity(_ level: IntensityLevel) {
        let allowed = IntensityLevel.playableLevels(for: session.contentProfile)
        guard allowed.contains(level), level.rawValue >= currentIntensityLevel.rawValue else { return }
        currentIntensityLevel = level
        persistSnapshot()
        FeedbackManager.success()
    }

    func passCard() {
        guard TapThrottle.tryFire(key: "game.passCard", cooldown: 0.22) else { return }
        passCount += 1
        FeedbackManager.warning()
        stopTimer()
        gameState = .penaltyChoice
        persistSnapshot()
    }

    func skipPenalty() {
        advanceAfterPassWithoutPenalty()
    }

    private func advanceAfterPassWithoutPenalty() {
        stopTimer()
        isTimedTaskActive = false
        currentPenalty = nil

        if currentPhase == .dice, diceState != nil {
            completeDiceCard()
            return
        }
        if currentPhase == .wheel, wheelState != nil {
            completeWheelCard()
            return
        }

        currentCard = nil
        recordSessionTurn(for: actorPlayer?.id)
        checkIntensityLevelUp()
        let phaseAdvanced = incrementProgress()
        if !phaseAdvanced {
            drawNextCard()
        }
    }

    func selectPenaltyReason(isRelated: Bool) {
        guard currentCard != nil else { return }

        let penalty: PenaltyCard?
        if isRelated {
            // Hafif alternatif — ilişkili ceza havuzu
            if let id = currentCard?.relatedPenaltyId,
               let linked = gameEngine.selectPenalty(id: id),
               linked.type == .related {
                penalty = linked
            } else {
                penalty = gameEngine.selectRandomPenalty(type: .related, maxIntensity: currentIntensity)
            }
        } else {
            // Kart reddi — her seferinde farklı red cezası havuzundan
            penalty = gameEngine.selectRandomPenalty(
                type: .refusal,
                maxIntensity: max(currentIntensity, currentIntensityLevel.rawValue)
            )
        }

        guard let penalty else {
            skipPenalty()
            return
        }

        penaltyCount += 1
        currentPenalty = penalty
        isTimedTaskActive = true
        let defaults = TimerDefaultsStore.load()
        renderedPenaltyText = renderCardText(
            penalty.text,
            duration: penalty.durationSeconds,
            isTimed: true
        )
        timerSeconds = max(penalty.durationSeconds, defaults.penaltyFloorSeconds)
        gameState = .penaltyDisplay
        persistSnapshot()
        FeedbackManager.cardReveal()
    }

    func completePenalty() {
        FeedbackManager.success()
        stopTimer()
        isTimedTaskActive = false
        currentPenalty = nil

        if currentPhase == .wheel, wheelState != nil {
            completeWheelCard()
            return
        }
        if currentPhase == .dice, diceState != nil {
            completeDiceCard()
            return
        }

        recordSessionTurn(for: actorPlayer?.id)
        checkIntensityLevelUp()
        currentCard = nil
        let phaseAdvanced = incrementProgress()
        if !phaseAdvanced {
            drawNextCard()
        }
    }

    func rejectPenalty() {
        FeedbackManager.warning()
        advanceAfterPassWithoutPenalty()
    }

    func partnerAccepted() {
        showPartnerConsent = false
        FeedbackManager.cardReveal()
        if currentCard?.isNeverHaveI == true {
            gameState = .neverHaveIChoice
        } else {
            gameState = .cardDisplay
        }
        persistSnapshot()
    }

    func partnerRejected() {
        showPartnerConsent = false
        FeedbackManager.error()
        persistSnapshot()
        selectPenaltyReason(isRelated: false)
    }

    @discardableResult
    private func incrementProgress() -> Bool {
        guard let actorId = actorPlayer?.id else { return false }
        phaseProgress.completedTurns[actorId, default: 0] += 1

        if phaseProgress.isComplete(for: players) {
            advancePhase()
            return true
        }
        return false
    }

    private func advancePhase() {
        if let next = nextEnabledPhase(after: currentPhase) {
            currentPhase = next
            phasesVisited.insert(next)
            phaseProgress = PhaseProgress(phase: currentPhase, players: players)
            persistSnapshot()
            drawNextCard()
            return
        }

        completedFullCycles += 1

        if currentIntensityLevel == .hardcore && !awaitingPostHardcoreCycle {
            stopTimer()
            currentCard = nil
            currentPenalty = nil
            awaitingPostHardcoreCycle = true
            gameState = .roundSetup
            persistSnapshot()
            return
        }

        finishSession()
    }

    private func nextEnabledPhase(after phase: GamePhase) -> GamePhase? {
        let allPhases = GamePhase.allCases
        guard let currentIndex = allPhases.firstIndex(of: phase) else { return nil }
        for index in (currentIndex + 1)..<allPhases.count {
            let candidate = allPhases[index]
            if session.isPhaseEnabled(candidate) {
                return candidate
            }
        }
        return nil
    }

    func applyRoundSetup(_ config: GameSessionConfig) {
        session = config
        if session.partnerPlayerIds.isEmpty, players.count == 3 {
            session.partnerPlayerIds = PartnerPairingStore.load()
        }
        currentIntensityLevel = config.playIntensityLevel
        currentIntensity = config.maxCardIntensity
        totalCompletedTurns = 0
        passCount = 0
        penaltyCount = 0
        phasesVisited = [GameSessionConfig.firstEnabledPhase(in: config)]
        sessionStartedAt = Date()
        currentPhase = GameSessionConfig.firstEnabledPhase(in: config)
        phaseProgress = PhaseProgress(phase: currentPhase, players: players)
        wheelState = nil
        diceState = nil
        diceRoller = nil
        lastDiceRoll = nil
        showSurpriseTask = false
        currentSurprisePosition = nil
        gameEngine.resetPlayedCards()
        stopTimer()
        currentCard = nil
        currentPenalty = nil
        canUseTimeBonus = true
        FeedbackManager.success()
        drawNextCard()
    }

    private func startWheelPhase() {
        if wheelState == nil {
            wheelState = WheelTurnState(players: players)
        }
        gameState = .wheelSpin
        persistSnapshot()
    }

    func spinWheel() -> Player? {
        guard var state = wheelState else { return nil }

        state.refillBagIfNeeded(players: players)

        guard !state.remainingBag.isEmpty else { return nil }

        let selectedId = state.remainingBag.removeFirst()
        wheelState?.remainingBag = state.remainingBag

        return players.first { $0.id == selectedId }
    }

    func wheelPlayerSelected(_ player: Player) {
        guard let card = gameEngine.selectWheelCard(
            intensity: currentIntensity,
            intensityLevel: currentIntensityLevel,
            context: selectionContext
        ) else { return }

        stopTimer()
        currentCard = card
        assignCardRoles(for: card, forcedActor: player)
        applyCardPresentation(card)
    }

    func completeWheelCard() {
        guard let actorId = actorPlayer?.id else { return }
        recordSessionTurn(for: actorId)
        checkIntensityLevelUp()
        wheelState?.completedTurns[actorId, default: 0] += 1

        if wheelState?.isComplete() == true {
            wheelState = nil
            currentCard = nil
            advancePhase()
        } else {
            currentCard = nil
            gameState = .wheelSpin
            persistSnapshot()
        }
    }

    func passWheelCard() {
        gameState = .penaltyChoice
        persistSnapshot()
    }

    // MARK: - Dice / Fate

    private func startDicePhase() {
        if diceState == nil {
            diceState = DiceTurnState(players: players)
        }
        updateDiceRoller()
        diceRollToken += 1
        gameState = .diceRoll
        persistSnapshot()
    }

    private func updateDiceRoller() {
        guard let state = diceState,
              let turn = state.currentTurn,
              !players.isEmpty else { return }

        let index = turn.playerIndex % players.count
        diceRoller = players[index]
        actorPlayer = diceRoller

        if turn.kind == .fate {
            clearSurprisePosition()
            currentCard = nil
        }
    }

    func rollFateDice() -> Int {
        guard isDiceFateTurn else { return 1 }

        let value = Int.random(in: 1...6)
        lastDiceRoll = value
        persistSnapshot()
        return value
    }

    @discardableResult
    func rollPositionDice() -> SurprisePosition? {
        guard isDicePositionTurn,
              let position = SurprisePositionCatalog.randomPosition() else {
            return nil
        }

        currentSurprisePosition = position
        timerSeconds = max(position.durationSeconds, 30)
        refreshSurpriseTaskText()
        showSurpriseTask = true
        persistSnapshot()
        return position
    }

    func openPositionTurn() {
        guard isDicePositionTurn, currentSurprisePosition != nil else { return }

        actorPlayer = diceRoller
        if let roller = diceRoller {
            targetPlayer = resolvePartner(for: roller) ?? pickRandomOther(than: roller)
        }
        currentCard = nil
        gameState = .cardDisplay
        FeedbackManager.cardReveal()
        persistSnapshot()
    }

    func clearSurprisePosition() {
        currentSurprisePosition = nil
        renderedSurpriseTaskText = ""
        showSurpriseTask = false
        persistSnapshot()
    }

    private func refreshSurpriseTaskText() {
        guard let position = currentSurprisePosition else {
            renderedSurpriseTaskText = ""
            return
        }
        renderedSurpriseTaskText = PlaceholderRenderer.renderSurpriseTaskText(position.taskText)
    }

    func enterWildChoice() {
        gameState = .diceWildChoice
        persistSnapshot()
    }

    func exitWildChoice() {
        gameState = .diceRoll
        persistSnapshot()
    }

    func openFateCard(category: FateCategory) {
        guard isDiceFateTurn else { return }

        guard let card = gameEngine.selectFateCard(
            category: category,
            intensity: currentIntensity,
            intensityLevel: currentIntensityLevel,
            context: selectionContext
        ) else {
            advancePhase()
            return
        }

        stopTimer()
        currentCard = card
        assignCardRoles(for: card, forcedActor: diceRoller)
        applyCardPresentation(card)
        showSurpriseTask = false
        persistSnapshot()
    }

    var isSurpriseTimed: Bool {
        currentSurprisePosition != nil && currentCard == nil
    }

    func completeDiceCard() {
        guard let actorId = actorPlayer?.id, let kind = currentDiceTurnKind else { return }

        recordSessionTurn(for: actorId)
        checkIntensityLevelUp()

        if kind == .fate {
            diceState?.recordFateCompletion(playerId: actorId)
        } else {
            diceState?.recordPositionCompletion(playerId: actorId)
        }

        clearSurprisePosition()
        currentCard = nil

        diceState?.advanceSchedule()

        if diceState?.isComplete == true {
            diceState = nil
            diceRoller = nil
            advancePhase()
        } else {
            updateDiceRoller()
            diceRollToken += 1
            gameState = .diceRoll
            persistSnapshot()
        }
    }

    func passDiceCard() {
        gameState = .penaltyChoice
        persistSnapshot()
    }

    func safeStop() {
        guard !showSafeStop, gameState != .gameComplete else { return }
        updateTimer()
        resumeTimerAfterStop = gameState == .timerRunning
        if resumeTimerAfterStop {
            gameState = currentPenalty != nil ? .penaltyDisplay : .cardDisplay
        }
        stopTimer()
        SoundManager.shared.stopAll()
        showSafeStop = true
        persistSnapshot()
    }

    func pauseForInactivity() {
        guard gameState != .idle, gameState != .gameComplete else { return }
        safeStop()
    }

    func resumeGame() {
        showSafeStop = false
        let shouldResume = resumeTimerAfterStop
        resumeTimerAfterStop = false
        if shouldResume { startTimer() }
        persistSnapshot()
    }

    func endGame() {
        finishSession()
    }
}

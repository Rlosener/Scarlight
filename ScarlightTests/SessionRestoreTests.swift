import XCTest
@testable import Scarlight

final class SessionRestoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        GameSessionRestoreStore.clear()
    }

    override func tearDown() {
        GameSessionRestoreStore.clear()
        super.tearDown()
    }

    func testValidSnapshotLoads() {
        let players = makePlayers()
        let snapshot = makeSnapshot(players: players, actorPlayerId: players[0].id, targetPlayerId: players[1].id)

        GameSessionRestoreStore.save(snapshot)

        XCTAssertEqual(GameSessionRestoreStore.loadValidated(), snapshot)
    }

    func testSnapshotWithLessThanTwoPlayersIsCleared() {
        let players = [makePlayer("Solo")]
        let snapshot = makeSnapshot(players: players, actorPlayerId: players[0].id, targetPlayerId: nil)

        GameSessionRestoreStore.save(snapshot)

        XCTAssertNil(GameSessionRestoreStore.loadValidated())
        XCTAssertNil(GameSessionRestoreStore.load())
    }

    func testSnapshotWithDuplicatePlayerIdsIsCleared() {
        let sharedId = UUID()
        let players = [
            makePlayer("Efe", id: sharedId),
            makePlayer("Ada", id: sharedId)
        ]
        let snapshot = makeSnapshot(players: players, actorPlayerId: sharedId, targetPlayerId: sharedId)

        GameSessionRestoreStore.save(snapshot)

        XCTAssertNil(GameSessionRestoreStore.loadValidated())
        XCTAssertNil(GameSessionRestoreStore.load())
    }

    func testSnapshotWithInvalidActorOrTargetIsCleared() {
        let players = makePlayers()
        let invalidActor = makeSnapshot(players: players, actorPlayerId: UUID(), targetPlayerId: players[1].id)
        GameSessionRestoreStore.save(invalidActor)
        XCTAssertNil(GameSessionRestoreStore.loadValidated())

        let invalidTarget = makeSnapshot(players: players, actorPlayerId: players[0].id, targetPlayerId: UUID())
        GameSessionRestoreStore.save(invalidTarget)
        XCTAssertNil(GameSessionRestoreStore.loadValidated())
    }

    func testSnapshotWithInvalidDiceStateIsCleared() {
        let players = makePlayers()
        var diceState = DiceTurnState(players: players)
        diceState.schedule = [DiceScheduledTurn(playerIndex: players.count, kind: .fate)]
        let snapshot = makeSnapshot(
            players: players,
            actorPlayerId: players[0].id,
            targetPlayerId: players[1].id,
            diceState: diceState
        )

        GameSessionRestoreStore.save(snapshot)

        XCTAssertNil(GameSessionRestoreStore.loadValidated())
        XCTAssertNil(GameSessionRestoreStore.load())
    }

    func testSnapshotWithInvalidWheelStateIsCleared() {
        let players = makePlayers()
        var wheelState = WheelTurnState(players: players)
        wheelState.completedTurns[UUID()] = 1
        let snapshot = makeSnapshot(
            players: players,
            actorPlayerId: players[0].id,
            targetPlayerId: players[1].id,
            wheelState: wheelState
        )

        GameSessionRestoreStore.save(snapshot)

        XCTAssertNil(GameSessionRestoreStore.loadValidated())
        XCTAssertNil(GameSessionRestoreStore.load())
    }

    func testRestoringTimerRunningSnapshotUsesSafeDisplayStateAndPlayedCards() {
        let players = makePlayers()
        let card = makeCard(id: "restore_card")
        let snapshot = makeSnapshot(
            players: players,
            currentCard: card,
            actorPlayerId: players[0].id,
            targetPlayerId: players[1].id,
            gameState: .timerRunning,
            timerSeconds: 25,
            playedCardIds: ["restore_card", "previous_card"]
        )

        let viewModel = GameEngineViewModel(restoring: snapshot)

        XCTAssertEqual(viewModel.gameState, .cardDisplay)
        XCTAssertEqual(viewModel.currentCard, card)
        XCTAssertEqual(viewModel.timerSeconds, 25)
        XCTAssertEqual(viewModel.playedCardIdsForTesting, ["restore_card", "previous_card"])
    }

    func testSafeStopResumesRunningTimerAndCanCompleteAtZero() {
        let players = makePlayers()
        let vm = GameEngineViewModel(restoring: makeSnapshot(
            players: players, currentCard: makeCard(), actorPlayerId: players[0].id,
            targetPlayerId: players[1].id, timerSeconds: 30
        ))
        vm.startTimer()
        vm.safeStop()
        XCTAssertTrue(vm.showSafeStop)
        XCTAssertEqual(vm.gameState, .cardDisplay)
        vm.resumeGame()
        XCTAssertEqual(vm.gameState, .timerRunning)
        vm.updateTimer(at: ProcessInfo.processInfo.systemUptime + 31)
        XCTAssertEqual(vm.timerSeconds, 0)
        XCTAssertEqual(vm.gameState, .waitingForCompletion)
    }

    func testDelayedTimerCallbackAccountsForElapsedTimeAndBonus() {
        let players = makePlayers()
        let vm = GameEngineViewModel(restoring: makeSnapshot(
            players: players, currentCard: makeCard(), actorPlayerId: players[0].id,
            targetPlayerId: players[1].id, timerSeconds: 30
        ))
        vm.startTimer()
        let now = ProcessInfo.processInfo.systemUptime
        vm.updateTimer(at: now + 9)
        XCTAssertEqual(vm.timerSeconds, 21)
        vm.addTimeBonus()
        vm.updateTimer(at: now + 10)
        XCTAssertEqual(vm.timerSeconds, 50)
        vm.stopTimer()
    }

    func testBackgroundPauseSavesRemainingTimerAndDoesNotWriteOnEveryTick() throws {
        let players = makePlayers()
        let vm = GameEngineViewModel(restoring: makeSnapshot(
            players: players, currentCard: makeCard(), actorPlayerId: players[0].id,
            targetPlayerId: players[1].id, timerSeconds: 30
        ))
        vm.startTimer()
        vm.updateTimer(at: ProcessInfo.processInfo.systemUptime + 5)
        XCTAssertEqual(vm.timerSeconds, 25)
        XCTAssertEqual(GameSessionRestoreStore.load()?.timerSeconds, 30)
        vm.pauseForInactivity()
        XCTAssertTrue(vm.showSafeStop)
        XCTAssertNotEqual(GameSessionRestoreStore.load()?.gameState, .timerRunning)
    }

    func testRestoredPlayedHistoryIsPersistedBeforeAnyFurtherAction() {
        let players = makePlayers()
        let snapshot = makeSnapshot(players: players, actorPlayerId: players[0].id,
                                    targetPlayerId: players[1].id, playedCardIds: ["kept"])
        let vm = GameEngineViewModel(restoring: snapshot)
        XCTAssertEqual(GameSessionRestoreStore.load()?.playedCardIds, ["kept"])
        vm.reloadCardsFromStore()
        XCTAssertEqual(vm.playedCardIdsForTesting, ["kept"])
    }

    func testRestoreRejectsNegativeTimerAndUnknownWheelPlayer() {
        let players = makePlayers()
        GameSessionRestoreStore.save(makeSnapshot(players: players, actorPlayerId: players[0].id,
                                                  targetPlayerId: players[1].id, timerSeconds: -1))
        XCTAssertNil(GameSessionRestoreStore.loadValidated())
        var wheel = WheelTurnState(players: players)
        wheel.remainingBag.append(UUID())
        GameSessionRestoreStore.save(makeSnapshot(players: players, actorPlayerId: players[0].id,
                                                  targetPlayerId: players[1].id, wheelState: wheel))
        XCTAssertNil(GameSessionRestoreStore.loadValidated())
    }

    func testInvalidDiceIndicesAreSafeToRead() {
        var dice = DiceTurnState(players: makePlayers())
        dice.scheduleIndex = -1
        XCTAssertNil(dice.currentTurn)
        XCTAssertNil(dice.nextTurn)
        dice.scheduleIndex = Int.max
        XCTAssertNil(dice.currentTurn)
        XCTAssertNil(dice.nextTurn)
    }

    func testDiscardThenDisappearDoesNotRecreateSession() {
        let players = makePlayers()
        let vm = GameEngineViewModel(restoring: makeSnapshot(players: players,
            actorPlayerId: players[0].id, targetPlayerId: players[1].id))
        vm.discardSavedSession()
        vm.pauseForInactivity()
        XCTAssertNil(GameSessionRestoreStore.load())
    }

    private func makePlayers() -> [Player] {
        [
            makePlayer("Efe", colorHex: "#E02B3F"),
            makePlayer("Ada", colorHex: "#F2A6B3")
        ]
    }

    private func makePlayer(_ name: String, id: UUID = UUID(), colorHex: String = "#E02B3F") -> Player {
        Player(id: id, name: name, gender: .other, role: .mixed, colorHex: colorHex)
    }

    private func makeCard(id: String = "card") -> GameCard {
        GameCard(
            id: id,
            title: "Restore Test",
            type: .task,
            phase: .timedTask,
            intensity: 3,
            minIntensity: .soft,
            maxIntensity: .medium,
            durationSeconds: 30,
            text: "Restore test görevi",
            deckType: .hardAction,
            contentTier: .beginning,
            minPlayers: 2,
            maxPlayers: 2,
            isActive: true
        )
    }

    private func makeSnapshot(
        players: [Player],
        currentCard: GameCard? = nil,
        actorPlayerId: UUID?,
        targetPlayerId: UUID?,
        gameState: GameState = .cardDisplay,
        timerSeconds: Int = 0,
        diceState: DiceTurnState? = nil,
        wheelState: WheelTurnState? = nil,
        playedCardIds: Set<String> = []
    ) -> GameSessionSnapshot {
        let progressPlayers = uniquePlayers(from: players)
        return GameSessionSnapshot(
            players: players,
            session: .default,
            currentPhase: .boldQuestion,
            phaseProgress: PhaseProgress(phase: .boldQuestion, players: progressPlayers),
            currentCard: currentCard,
            currentPenalty: nil,
            actorPlayerId: actorPlayerId,
            targetPlayerId: targetPlayerId,
            gameState: gameState,
            timerSeconds: timerSeconds,
            wheelState: wheelState,
            diceState: diceState,
            diceRollerId: nil,
            lastDiceRoll: nil,
            diceRollToken: 0,
            showPartnerConsent: false,
            showSafeStop: false,
            renderedCardText: currentCard?.text ?? "",
            renderedPenaltyText: "",
            currentIntensityLevel: .soft,
            totalCompletedTurns: 0,
            showSurpriseTask: false,
            currentSurprisePosition: nil,
            renderedSurpriseTaskText: "",
            canRollPositionDice: false,
            canUseTimeBonus: true,
            activeItemName: nil,
            currentIntensity: 3,
            completedFullCycles: 0,
            awaitingPostHardcoreCycle: false,
            sessionTurnCounts: Dictionary(uniqueKeysWithValues: progressPlayers.map { ($0.id, 0) }),
            playedCardIds: playedCardIds
        )
    }

    private func uniquePlayers(from players: [Player]) -> [Player] {
        var seen: Set<UUID> = []
        return players.filter { player in
            if seen.contains(player.id) {
                return false
            }
            seen.insert(player.id)
            return true
        }
    }
}

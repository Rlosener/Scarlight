import XCTest
@testable import Scarlight

final class CardSelectionRuleTests: XCTestCase {
    func testTwoPlayerContentIsAvailableInTwoAndThreePlayerGames() {
        XCTAssertTrue(GameCard.supportsPlayerCount(minPlayers: 2, maxPlayers: 2, count: 2))
        XCTAssertTrue(GameCard.supportsPlayerCount(minPlayers: 2, maxPlayers: 2, count: 3))
    }

    func testThreePlayerOnlyContentDoesNotAppearInTwoPlayerGames() {
        XCTAssertFalse(GameCard.supportsPlayerCount(minPlayers: 3, maxPlayers: 3, count: 2))
        XCTAssertTrue(GameCard.supportsPlayerCount(minPlayers: 3, maxPlayers: 3, count: 3))
    }

    func testQuestionsAreUntimedAndTasksAreTimed() {
        let question = makeCard(
            id: "question",
            type: .question,
            phase: .boldQuestion,
            deckType: .hardTruth
        )
        let task = makeCard(
            id: "task",
            type: .task,
            phase: .timedTask,
            deckType: .hardAction
        )
        let neverHaveI = makeCard(
            id: "never_have_i",
            type: .question,
            phase: .boldQuestion,
            deckType: .neverHaveI
        )

        XCTAssertFalse(question.isTimedTaskCard)
        XCTAssertTrue(task.isTimedTaskCard)
        XCTAssertFalse(neverHaveI.isTimedTaskCard)
    }

    func testDeckAndPropFiltersRespectSession() {
        let hardTruth = makeCard(
            id: "truth",
            type: .question,
            phase: .boldQuestion,
            deckType: .hardTruth
        )
        let propTask = makeCard(
            id: "prop",
            type: .question,
            phase: .boldQuestion,
            deckType: .propTask,
            requiredPropIds: ["ice"]
        )
        let truthOnlySession = GameSessionConfig(
            selectedPropIds: [],
            enabledDeckTypes: [.hardTruth],
            playIntensityLevel: .soft,
            maxCardIntensity: 3,
            enabledContentTiers: [.beginning]
        )
        let propSession = GameSessionConfig(
            selectedPropIds: ["ice"],
            enabledDeckTypes: [.propTask],
            playIntensityLevel: .soft,
            maxCardIntensity: 3,
            enabledContentTiers: [.beginning]
        )

        XCTAssertTrue(hardTruth.matchesSession(truthOnlySession, playerCount: 2))
        XCTAssertFalse(propTask.matchesSession(truthOnlySession, playerCount: 2))
        XCTAssertTrue(propTask.matchesSession(propSession, playerCount: 2))
    }

    func testOpeningQuestionFlowSkipsNeverHaveIWhenTruthQuestionsExist() {
        var engine = GameEngine()
        let neverHaveI = makeCard(
            id: "never_have_i",
            type: .question,
            phase: .boldQuestion,
            deckType: .neverHaveI
        )
        let hardTruth = makeCard(
            id: "truth",
            type: .question,
            phase: .boldQuestion,
            deckType: .hardTruth
        )
        let session = GameSessionConfig(
            selectedPropIds: [],
            enabledDeckTypes: [.neverHaveI, .hardTruth],
            playIntensityLevel: .soft,
            maxCardIntensity: 3,
            enabledContentTiers: [.beginning]
        )

        engine.loadCards([neverHaveI, hardTruth])

        let selected = engine.selectCard(
            for: .boldQuestion,
            intensity: 3,
            intensityLevel: .soft,
            context: CardSelectionContext(session: session, playerCount: 2)
        )

        XCTAssertEqual(selected?.effectiveDeckType, .hardTruth)
    }

    func testOpeningSocialQuestionFlowSkipsBarNeverHaveIWhenTruthQuestionsExist() {
        var engine = GameEngine()
        let barNeverHaveI = makeCard(
            id: "bar_never_have_i",
            type: .question,
            phase: .boldQuestion,
            deckType: .barNeverHaveI
        )
        let barTruth = makeCard(
            id: "bar_truth",
            type: .question,
            phase: .boldQuestion,
            deckType: .barTruth
        )
        let session = GameSessionConfig(
            selectedPropIds: [],
            enabledDeckTypes: [.barNeverHaveI, .barTruth],
            contentProfile: .social,
            playIntensityLevel: .soft,
            maxCardIntensity: 3,
            enabledContentTiers: [.beginning]
        )

        engine.loadCards([barNeverHaveI, barTruth])

        let selected = engine.selectCard(
            for: .boldQuestion,
            intensity: 3,
            intensityLevel: .soft,
            context: CardSelectionContext(session: session, playerCount: 2)
        )

        XCTAssertEqual(selected?.effectiveDeckType, .barTruth)
    }

    func testTimedTaskRendererRemovesEmbeddedDurationSuffixes() {
        let rendered = PlaceholderRenderer.renderGameplayText(
            "Son rezil anını 30 saniyede özetle",
            duration: 30,
            phase: .timedTask,
            stripDuration: true
        )

        XCTAssertEqual(rendered, "Son rezil anını özetle")
    }

    func testActionFlowUsesTaskDeckAfterQuestionOpening() {
        var engine = GameEngine()
        let hardTruth = makeCard(
            id: "truth",
            type: .question,
            phase: .boldQuestion,
            deckType: .hardTruth
        )
        let hardAction = makeCard(
            id: "action",
            type: .task,
            phase: .timedTask,
            deckType: .hardAction
        )
        let session = GameSessionConfig(
            selectedPropIds: [],
            enabledDeckTypes: [.hardTruth, .hardAction],
            playIntensityLevel: .medium,
            maxCardIntensity: 3,
            enabledContentTiers: [.beginning]
        )

        engine.loadCards([hardTruth, hardAction])

        let selected = engine.selectCard(
            for: .timedTask,
            intensity: 3,
            intensityLevel: .medium,
            context: CardSelectionContext(session: session, playerCount: 2)
        )

        XCTAssertEqual(selected?.effectiveDeckType, .hardAction)
        XCTAssertTrue(selected?.isTimedTaskCard == true)
    }

    private func makeCard(
        id: String,
        type: CardType,
        phase: GamePhase,
        deckType: CardDeckType,
        requiredPropIds: [String]? = nil
    ) -> GameCard {
        GameCard(
            id: id,
            title: "Test",
            type: type,
            phase: phase,
            intensity: 3,
            minIntensity: .soft,
            maxIntensity: .medium,
            durationSeconds: 45,
            text: "Test metni",
            deckType: deckType,
            contentTier: .beginning,
            minPlayers: 2,
            maxPlayers: 2,
            requiredPropIds: requiredPropIds,
            isActive: true
        )
    }
}

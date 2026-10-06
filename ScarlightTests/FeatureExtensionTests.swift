import XCTest
@testable import Scarlight

final class FeatureExtensionTests: XCTestCase {
    func testSessionConfigDecodesMissingPhasesWithDefaults() throws {
        let json = """
        {
            "selectedPropIds": [],
            "enabledDeckTypes": ["neverHaveI"],
            "playIntensityLevel": 1,
            "maxCardIntensity": 3,
            "enabledContentTiers": ["beginning"]
        }
        """.data(using: .utf8)!

        let config = try JSONDecoder().decode(GameSessionConfig.self, from: json)
        XCTAssertTrue(config.isPhaseEnabled(.wheel))
        XCTAssertTrue(config.isPhaseEnabled(.dice))
        XCTAssertEqual(config.boundaryPreferences, BoundaryPreferences.default)
    }

    func testFirstEnabledPhaseSkipsDisabledPhases() {
        let config = GameSessionConfig(
            selectedPropIds: [],
            enabledDeckTypes: Set(CardDeckType.playableDefaults),
            playIntensityLevel: .soft,
            maxCardIntensity: 3,
            enabledContentTiers: Set(ContentTier.allCases),
            enabledPhases: [.boldQuestion, .dice, .finalFocus]
        )

        XCTAssertEqual(GameSessionConfig.firstEnabledPhase(in: config), .boldQuestion)
    }

    func testPlayableCardCounterRespectsDeckFilter() {
        let card = GameCard(
            id: "truth_only",
            title: "Test",
            type: .question,
            phase: .boldQuestion,
            intensity: 3,
            minIntensity: .soft,
            maxIntensity: .hardcore,
            durationSeconds: 30,
            text: "Soru",
            deckType: .hardTruth,
            contentTier: .beginning,
            minPlayers: 2,
            maxPlayers: 2,
            isActive: true
        )

        let config = GameSessionConfig(
            selectedPropIds: [],
            enabledDeckTypes: [.hardTruth],
            playIntensityLevel: .soft,
            maxCardIntensity: 5,
            enabledContentTiers: [.beginning]
        )

        XCTAssertTrue(card.matchesSession(config, playerCount: 2))
        XCTAssertFalse(
            card.matchesSession(
                GameSessionConfig(
                    selectedPropIds: [],
                    enabledDeckTypes: [.hardAction],
                    playIntensityLevel: .soft,
                    maxCardIntensity: 5,
                    enabledContentTiers: [.beginning]
                ),
                playerCount: 2
            )
        )
    }

    func testBoundaryPreferencesFilterTimedAndPropCards() {
        let timed = GameCard(
            id: "timed",
            title: "Timed",
            type: .task,
            phase: .timedTask,
            intensity: 3,
            minIntensity: .soft,
            maxIntensity: .medium,
            durationSeconds: 45,
            text: "Bir görev yap.",
            deckType: .hardAction,
            contentTier: .beginning,
            minPlayers: 2,
            maxPlayers: 2,
            isActive: true
        )
        let prop = makeFeatureCard(
            id: "prop",
            deckType: .propTask,
            requiredPropIds: ["ice"]
        )
        let safeQuestion = makeFeatureCard(id: "question", deckType: .hardTruth)

        let boundaries = BoundaryPreferences(
            allowsProps: false,
            allowsTimedCards: false,
            maximumCardIntensity: 3,
            disabledDeckTypes: []
        )
        let config = GameSessionConfig(
            selectedPropIds: ["ice"],
            enabledDeckTypes: [.hardTruth, .hardAction, .propTask],
            playIntensityLevel: .soft,
            maxCardIntensity: 5,
            enabledContentTiers: [.beginning],
            boundaryPreferences: boundaries
        )

        XCTAssertTrue(safeQuestion.matchesSession(config, playerCount: 2))
        XCTAssertFalse(timed.matchesSession(config, playerCount: 2))
        XCTAssertFalse(prop.matchesSession(config, playerCount: 2))
        XCTAssertFalse(config.enabledDeckTypes.contains(.propTask))
    }

    func testBuiltInSessionPresetsExist() {
        XCTAssertFalse(SessionPreset.builtIns.isEmpty)
        XCTAssertTrue(SessionPreset.builtIns.contains { $0.name == "Tam Paket" })
        XCTAssertTrue(SessionPreset.builtIns.contains { $0.name == "Yumuşak Başlangıç" })
        XCTAssertTrue(SessionPreset.builtIns.contains { $0.name == "Bar" })
        XCTAssertTrue(SessionPreset.builtIns.contains { $0.name == "Çakmak" })
        XCTAssertTrue(SessionPreset.builtIns.contains { $0.name == "3 Kişilik" })
        XCTAssertTrue(SessionPreset.builtIns.contains { $0.name == "Propsuz" })
    }

    func testPlayAtmosphereDefaults() {
        XCTAssertEqual(PlayAtmosphere.selectionOptions.count, 3)
        XCTAssertTrue(PlayAtmosphere.lighter.isLighterGame)
        XCTAssertFalse(PlayAtmosphere.friends.isLighterGame)

        let friends = PlayAtmosphere.friends.preparedConfig()
        XCTAssertEqual(friends.contentProfile, .social)
        XCTAssertTrue(friends.enabledDeckTypes.contains(.barNeverHaveI))
        XCTAssertFalse(friends.enabledDeckTypes.contains(.neverHaveI))
        XCTAssertEqual(friends.playIntensityLevel, .soft)

        let hot = PlayAtmosphere.hot.preparedConfig()
        XCTAssertEqual(hot.contentProfile, .intimate)
        XCTAssertTrue(hot.enabledDeckTypes.contains(.neverHaveI))
        XCTAssertFalse(hot.enabledDeckTypes.contains(.barNeverHaveI))
        XCTAssertEqual(hot.playIntensityLevel, .hot)
        if !CardCatalog.propIdsWithCards().isEmpty {
            XCTAssertFalse(hot.selectedPropIds.isEmpty)
        }
    }

    func testModeExperienceSpecsAreDistinct() {
        let specs = PlayAtmosphere.selectionOptions.map(\.experience)

        XCTAssertEqual(Set(specs.map(\.conceptName)).count, 3)
        XCTAssertEqual(PlayAtmosphere.friends.experience.sceneTreatment, .bar)
        XCTAssertEqual(PlayAtmosphere.lighter.experience.sceneTreatment, .flame)
        XCTAssertEqual(PlayAtmosphere.hot.experience.sceneTreatment, .privateRoom)
        XCTAssertEqual(PlayAtmosphere.lighter.experience.cardChromeLabel, "ÇAKMAK TURU")
    }

    func testVisualEffectBudgetRespectsPerformanceMode() {
        XCTAssertEqual(VisualEffectBudget.resolved(performanceModeEnabled: true), .reduced)
        XCTAssertEqual(VisualEffectBudget.resolved(performanceModeEnabled: false), .balanced)
        XCTAssertFalse(VisualEffectBudget.reduced.allowsAmbientTexture)
        XCTAssertTrue(VisualEffectBudget.balanced.allowsAmbientTexture)
    }

    func testPerformanceDefaultsEnableMVPModeOnce() {
        let suiteName = "PerformanceDefaultsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        PerformanceDefaults.registerAndApplyMVPDefaults(userDefaults: defaults)
        XCTAssertTrue(defaults.bool(forKey: PerformanceDefaults.performanceModeKey))

        defaults.set(false, forKey: PerformanceDefaults.performanceModeKey)
        PerformanceDefaults.registerAndApplyMVPDefaults(userDefaults: defaults)
        XCTAssertFalse(defaults.bool(forKey: PerformanceDefaults.performanceModeKey))

        defaults.removePersistentDomain(forName: suiteName)
    }

    func testLighterQuestionPoolReturnsText() {
        let question = LighterQuestionPool.randomQuestion()
        XCTAssertFalse(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    func testLighterDefaultTargetSkipsCurrentHolder() {
        let players = [
            Player(name: "A", gender: .female, role: .mixed, colorHex: "#FFFFFF"),
            Player(name: "B", gender: .male, role: .mixed, colorHex: "#000000")
        ]

        XCTAssertEqual(
            LighterTurnDefaults.defaultTargetId(in: players, excluding: 0),
            players[1].id
        )
        XCTAssertEqual(
            LighterTurnDefaults.defaultTargetId(in: players, excluding: 1),
            players[0].id
        )
        XCTAssertNil(LighterTurnDefaults.defaultTargetId(in: [players[0]], excluding: 0))
    }

    func testPropSetupAssistantDetectsMissingPropSelection() {
        let propCard = makeFeatureCard(
            id: "prop_card",
            deckType: .propTask,
            requiredPropIds: ["ice"]
        )
        let config = GameSessionConfig(
            selectedPropIds: [],
            enabledDeckTypes: [.propTask],
            playIntensityLevel: .soft,
            maxCardIntensity: 3,
            enabledContentTiers: [.beginning]
        )

        let analysis = PropSetupAssistant.analyze(config: config, playerCount: 2, cards: [propCard])

        XCTAssertTrue(analysis.missingPropSelection)
        XCTAssertTrue(analysis.recommendedPropIds.contains("ice"))
    }

    func testContentAuditorFlagsDuplicateAndUnresolvedPlaceholder() {
        let first = makeFeatureCard(id: "first", text: "Aynı metin")
        let duplicate = makeFeatureCard(id: "second", text: "Aynı metin")
        let unresolved = makeFeatureCard(id: "placeholder", text: "Bunu {bilinmeyen} ile yap")

        let issues = CardContentAuditor.analyze([first, duplicate, unresolved])

        XCTAssertTrue(issues.contains { $0.cardId == "second" && $0.kind == .duplicateText })
        XCTAssertTrue(issues.contains { $0.cardId == "placeholder" && $0.kind == .unresolvedPlaceholder })
    }

    func testPlayedSessionRecordDecodesLegacyPayload() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "playedAt": 0,
            "playerNames": ["A", "B"],
            "totalTurns": 4,
            "durationSeconds": 120,
            "finalIntensity": 1,
            "completedCycles": 1,
            "passCount": 0,
            "penaltyCount": 0,
            "jokersUsed": 0,
            "enabledDeckCount": 2,
            "propCount": 0
        }
        """.data(using: .utf8)!

        let record = try JSONDecoder().decode(PlayedSessionRecord.self, from: json)

        XCTAssertEqual(record.contentProfile, .intimate)
        XCTAssertTrue(record.phaseNames.isEmpty)
        XCTAssertTrue(record.enabledDeckNames.isEmpty)
        XCTAssertTrue(record.playerStats.isEmpty)
        XCTAssertFalse(record.canReplay)
    }

    func testPlayedSessionRecordStoresReplayMetadata() {
        let players = [
            Player(name: "A", gender: .female, role: .mixed, colorHex: "#FFFFFF"),
            Player(name: "B", gender: .male, role: .mixed, colorHex: "#000000")
        ]
        let config = GameSessionConfig.default
        let summary = GameSessionSummary(
            totalTurns: 2,
            finalIntensity: .soft,
            completedCycles: 0,
            durationSeconds: 30,
            passCount: 0,
            penaltyCount: 0,
            jokersUsed: 0,
            phasesPlayed: ["Cesur Soru"],
            playerNames: players.map(\.name),
            enabledDeckCount: config.enabledDeckTypes.count,
            propCount: config.selectedPropIds.count,
            contentProfile: config.contentProfile,
            enabledDeckNames: config.enabledDeckTypes.map(\.displayName),
            selectedPropNames: [],
            playerStats: [],
            replayPlayers: players,
            replayConfig: config
        )

        let record = PlayedSessionRecord(summary: summary)

        XCTAssertTrue(record.canReplay)
        XCTAssertEqual(record.replayPlayers, players)
        XCTAssertEqual(record.replayConfig, config)
    }

    func testLocalBackupImportReportSummarizesWarnings() {
        let package = LocalBackupPackage(
            version: 1,
            userCards: [
                makeFeatureCard(id: "duplicate"),
                makeFeatureCard(id: "duplicate")
            ],
            cardPreferences: [:],
            penalties: [],
            history: [],
            sessionPresets: [],
            userProps: [],
            sessionConfig: .default,
            timerDefaults: TimerDefaults()
        )

        let report = package.importReport(importedAt: Date(timeIntervalSince1970: 0))

        XCTAssertEqual(report.userCardCount, 2)
        XCTAssertEqual(report.skippedCount, 0)
        XCTAssertEqual(report.warnings.count, 2)
    }

    private func makeFeatureCard(
        id: String,
        text: String = "Test metni",
        deckType: CardDeckType = .hardTruth,
        requiredPropIds: [String]? = nil
    ) -> GameCard {
        GameCard(
            id: id,
            title: "Test",
            type: deckType == .propTask ? .task : .question,
            phase: deckType == .propTask ? .timedTask : .boldQuestion,
            intensity: 3,
            minIntensity: .soft,
            maxIntensity: .medium,
            durationSeconds: 45,
            text: text,
            deckType: deckType,
            contentTier: .beginning,
            minPlayers: 2,
            maxPlayers: 2,
            requiredPropIds: requiredPropIds,
            isActive: true
        )
    }
}

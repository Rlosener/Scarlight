import XCTest
@testable import Scarlight

final class LocalDataReliabilityTests: XCTestCase {
    private let store = LocalJSONStore.shared
    private let filenames = [
        "user_cards.json", "card_preferences.json", "players.json", "partner_pairing.json",
        "deck_packs.json", "prop_questions.json", "bar_social_packs.json", "penalties.json",
        "playedHistory.json", "session_presets.json", "user_props.json", "session_config.json", "played_cards.json"
    ]
    private var originals: [String: Data] = [:]

    override func setUpWithError() throws {
        for filename in filenames {
            if store.fileExists(filename) { originals[filename] = try store.loadRawData(from: filename) }
        }
        try store.save([GameCard](), to: CardCatalog.userCardsFilename)
        try store.save([String: CardPreference](), to: "card_preferences.json")
    }

    override func tearDownWithError() throws {
        for filename in filenames {
            if let data = originals[filename] {
                try store.saveRawData(data, to: filename)
            } else if store.fileExists(filename) {
                try store.delete(filename)
            }
        }
    }

    func testInactiveUserCardSurvivesAnotherSaveAndCanBeReactivated() throws {
        var first = makeCard("first")
        first.isActive = false
        try CardCatalog.saveUserCard(first)
        try CardCatalog.saveUserCard(makeCard("second"))
        XCTAssertEqual(CardCatalog.loadUserCards().count, 2)
        XCTAssertTrue(CardCatalog.loadForEditor().contains { $0.id == "first" })
        XCTAssertFalse(CardCatalog.loadForGameplay().contains { $0.id == "first" })
        first.isActive = true
        try CardCatalog.saveUserCard(first)
        XCTAssertTrue(CardCatalog.loadForGameplay().contains { $0.id == "first" })
    }

    func testImportRejectsDuplicateIDsBeforeChangingStoredCards() throws {
        try CardCatalog.saveUserCard(makeCard("original"))
        XCTAssertThrowsError(try CardCatalog.importUserCards([makeCard("duplicate"), makeCard("duplicate")]))
        XCTAssertEqual(CardCatalog.loadUserCards().map(\.id), ["original"])
    }

    func testImportedPackOverrideHasOnlyOneCatalogIdentity() throws {
        let bundled = try XCTUnwrap(DeckPackLoader.bundledPackCards().first)
        var edited = bundled
        edited.text = "Güncellenmiş test metni"
        try CardCatalog.importUserCards([edited])
        let matches = CardCatalog.loadForEditor().filter { $0.id == bundled.id }
        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches.first?.text, edited.text)
    }

    @MainActor
    func testBulkVisibilityWritesOnceAndCanShowInactiveCardsAgain() throws {
        try CardCatalog.saveUserCard(makeCard("bulk"))
        let vm = CardEditorViewModel()
        var notificationCount = 0
        let observer = NotificationCenter.default.addObserver(forName: .cardsDidChange, object: nil, queue: .main) { _ in
            notificationCount += 1
        }
        defer { NotificationCenter.default.removeObserver(observer) }
        let start = Date()
        vm.bulkSetActive(false, for: vm.cards)
        XCTAssertNil(vm.errorMessage)
        XCTAssertEqual(notificationCount, 1)
        XCTAssertTrue(vm.cards.contains { $0.id == "bulk" })
        vm.visibilityFilter = .hidden
        XCTAssertEqual(vm.filteredCards.count, vm.cards.count)
        vm.bulkSetActive(true, for: vm.cards)
        XCTAssertEqual(notificationCount, 2)
        XCTAssertTrue(vm.filteredCards.isEmpty)
        XCTAssertTrue(CardCatalog.loadUserCards().first?.isActive == true)
        print("MVP bulk hide/show \(vm.cards.count) cards: \(Date().timeIntervalSince(start)) seconds")
    }

    func testSaveBatchRollsBackEarlierFilesWhenLaterWriteFails() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let local = LocalJSONStore(directory: directory)
        try local.saveRawData(Data("original".utf8), to: "a.json")
        XCTAssertThrowsError(try local.saveBatch([
            "a.json": Data("changed".utf8),
            "b.json": Data("new".utf8),
            "z-missing/file.json": Data("failure".utf8)
        ]))
        XCTAssertEqual(try local.loadRawData(from: "a.json"), Data("original".utf8))
        XCTAssertFalse(local.fileExists("b.json"))
    }

    func testFutureBackupVersionIsRejectedWithoutChangingData() throws {
        try CardCatalog.saveUserCard(makeCard("original"))
        var package = makeBackup(version: LocalBackupPackage.currentVersion + 1)
        package.userCards = [makeCard("replacement")]
        let url = try store.exportData(package)
        defer { try? FileManager.default.removeItem(at: url) }
        XCTAssertThrowsError(try ExportImportService.shared.importFullBackup(from: url))
        XCTAssertEqual(CardCatalog.loadUserCards().map(\.id), ["original"])
    }

    func testCompleteBackupRoundTripIncludesPlayersAndEditablePacks() throws {
        let players = [makePlayer("Ada"), makePlayer("Deniz")]
        try store.save(players, to: "players.json")
        try store.save([DeckPackEntry](), to: PackFileStore.deckPacksFilename)
        try store.save(Set(["drawn-test-card"]), to: "played_cards.json")
        try CardCatalog.saveUserCard(makeCard("backed-up"))
        let url = try ExportImportService.shared.exportFullBackup()
        defer { try? FileManager.default.removeItem(at: url) }
        try store.save([Player](), to: "players.json")
        try store.save([GameCard](), to: CardCatalog.userCardsFilename)
        let result = try ExportImportService.shared.importFullBackupWithReport(from: url)
        XCTAssertEqual(try store.load(from: "players.json", as: [Player].self), players)
        XCTAssertEqual(CardCatalog.loadUserCards().map(\.id), ["backed-up"])
        XCTAssertEqual(result.report.userCardCount, 1)
        XCTAssertEqual(PlayedCardHistoryStore.load(), ["drawn-test-card"])
        XCTAssertEqual(PackFileStore.loadEditableEntries(named: PackFileStore.deckPacksFilename), [])
    }

    func testLegacyBackupPreservesPlayersAndRejectsInvalidTimer() throws {
        let players = [makePlayer("Ada"), makePlayer("Deniz")]
        try store.save(players, to: "players.json")
        var package = makeBackup(version: 2)
        let url = try store.exportData(package)
        defer { try? FileManager.default.removeItem(at: url) }
        try ExportImportService.shared.importFullBackup(from: url)
        XCTAssertEqual(try store.load(from: "players.json", as: [Player].self), players)
        package.timerDefaults.beginningSeconds = -10
        XCTAssertThrowsError(try package.validateForImport())
    }

    func testPlayerValidationDoesNotSaveWhitespaceAndUsesActiveCount() {
        let vm = PlayerSetupViewModel()
        let before = vm.players
        XCTAssertFalse(vm.addPlayer(name: " \n ", gender: .other, role: .mixed))
        XCTAssertEqual(vm.players, before)
        var inactive = makePlayer("Pasif")
        inactive.isActive = false
        vm.players = [makePlayer("Aktif"), inactive]
        XCTAssertFalse(vm.canStartGame)
    }

    private func makeCard(_ id: String) -> GameCard {
        GameCard(id: id, title: "Test Kartı", type: .question, phase: .boldQuestion,
                 intensity: 3, durationSeconds: 30, text: "Test sorusu", isUserAuthored: true)
    }

    private func makePlayer(_ name: String) -> Player {
        Player(name: name, gender: .other, role: .mixed, colorHex: "#E02B3F")
    }

    private func makeBackup(version: Int) -> LocalBackupPackage {
        LocalBackupPackage(version: version, userCards: [], cardPreferences: [:], penalties: [], history: [],
                           sessionPresets: [], userProps: [], sessionConfig: .default, timerDefaults: TimerDefaults())
    }
}

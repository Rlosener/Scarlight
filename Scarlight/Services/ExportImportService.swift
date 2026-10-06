import Foundation

class ExportImportService {
    static let shared = ExportImportService()
    private let store = LocalJSONStore.shared

    private init() {}

    func exportCards(_ cards: [GameCard]) throws -> URL {
        return try store.exportData(cards)
    }

    func importCards(from url: URL) throws -> [GameCard] {
        return try store.importData(from: url, as: [GameCard].self)
    }

    func exportPenalties(_ penalties: [PenaltyCard]) throws -> URL {
        return try store.exportData(penalties)
    }

    func importPenalties(from url: URL) throws -> [PenaltyCard] {
        return try store.importData(from: url, as: [PenaltyCard].self)
    }

    func exportFullBackup() throws -> URL {
        let url = try store.exportData(LocalBackupPackage.current())
        LocalBackupActivityStore.markExported()
        return url
    }

    @discardableResult
    func importFullBackup(from url: URL) throws -> LocalBackupPackage {
        let result = try importFullBackupWithReport(from: url)
        return result.package
    }

    @discardableResult
    func importFullBackupWithReport(from url: URL) throws -> LocalBackupImportResult {
        try restoreFullBackup(previewFullBackup(from: url))
    }

    func previewFullBackup(from url: URL) throws -> LocalBackupPackage {
        let package = try store.importData(from: url, as: LocalBackupPackage.self)
        try package.validateForImport()
        return package
    }

    @discardableResult
    func restoreFullBackup(_ package: LocalBackupPackage) throws -> LocalBackupImportResult {
        try package.validateForImport()
        let report = package.importReport()
        try apply(package)
        LocalBackupActivityStore.markImported(report)
        return LocalBackupImportResult(package: package, report: report)
    }

    private func apply(_ package: LocalBackupPackage) throws {
        let encoder = JSONEncoder()
        let cards = package.userCards.map { card in
            var copy = card
            copy.isUserAuthored = true
            return copy
        }
        let presets = package.sessionPresets.map {
            SessionPreset(id: $0.id, name: $0.name, config: $0.config, isBuiltIn: false)
        }
        var files: [String: Data] = [
            CardCatalog.userCardsFilename: try encoder.encode(cards),
            "card_preferences.json": try encoder.encode(package.cardPreferences),
            PenaltyCatalog.penaltiesFilename: try encoder.encode(package.penalties),
            "playedHistory.json": try encoder.encode(package.history.sorted { $0.playedAt > $1.playedAt }),
            "session_presets.json": try encoder.encode(presets),
            "user_props.json": try encoder.encode(package.userProps),
            "session_config.json": try encoder.encode(package.sessionConfig)
        ]
        if let players = package.players { files["players.json"] = try encoder.encode(players) }
        if let ids = package.partnerPlayerIds { files["partner_pairing.json"] = try encoder.encode(ids) }
        if let ids = package.playedCardIds { files["played_cards.json"] = try encoder.encode(ids) }
        if let editedPacks = package.editedPacks {
            // A missing override in a complete v3 backup means restore the bundled deck.
            for filename in PackFileStore.packFilenames {
                let entries = editedPacks[filename] ?? PackFileStore.loadBundleEntries(named: filename)
                files[filename] = try encoder.encode(entries)
            }
        }
        try store.saveBatch(files)
        TimerDefaultsStore.save(package.timerDefaults)
        NotificationCenter.default.post(name: .cardsDidChange, object: nil)
    }
}

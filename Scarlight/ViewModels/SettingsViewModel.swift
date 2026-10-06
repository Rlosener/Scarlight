import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    @Published var isHapticEnabled: Bool = true
    @Published var isSoundEnabled: Bool = true

    private let hapticKey = "isHapticEnabled"
    private let soundKey = "isSoundEnabled"

    init() {
        loadSettings()
    }

    func loadSettings() {
        if UserDefaults.standard.object(forKey: hapticKey) == nil {
            isHapticEnabled = true
        } else {
            isHapticEnabled = UserDefaults.standard.bool(forKey: hapticKey)
        }
        if UserDefaults.standard.object(forKey: soundKey) == nil {
            isSoundEnabled = true
        } else {
            isSoundEnabled = UserDefaults.standard.bool(forKey: soundKey)
        }
        HapticManager.shared.setEnabled(isHapticEnabled)
        SoundManager.shared.setEnabled(isSoundEnabled)
    }

    func setHapticEnabled(_ enabled: Bool) {
        isHapticEnabled = enabled
        UserDefaults.standard.set(isHapticEnabled, forKey: hapticKey)
        HapticManager.shared.setEnabled(isHapticEnabled)
    }

    func setSoundEnabled(_ enabled: Bool) {
        isSoundEnabled = enabled
        UserDefaults.standard.set(isSoundEnabled, forKey: soundKey)
        SoundManager.shared.setEnabled(isSoundEnabled)
        if isSoundEnabled {
            SoundManager.shared.play(.clickPop, volume: 0.4)
        }
    }

    func resetGameHistory() {
        PlayedHistoryStore.clear()
    }

    func clearSavedGameSession() {
        GameSessionRestoreStore.clear()
    }

    func resetCardHistory() {
        CardPreferencesStore.clearAll()
    }

    func exportCards() throws -> URL {
        let cards = CardCatalog.loadForGameplay()
        return try ExportImportService.shared.exportCards(cards)
    }

    func importCards(from url: URL) throws {
        let imported = try ExportImportService.shared.importCards(from: url)
        try CardCatalog.importUserCards(imported)
    }

    func exportPenalties() throws -> URL {
        let penalties = PenaltyCatalog.loadForGameplay()
        return try ExportImportService.shared.exportPenalties(penalties)
    }

    func importPenalties(from url: URL) throws {
        let penalties = try ExportImportService.shared.importPenalties(from: url)
        let store = LocalJSONStore.shared
        try store.save(penalties, to: "penalties.json")
    }

    func exportFullBackup() throws -> URL {
        try ExportImportService.shared.exportFullBackup()
    }

    @discardableResult
    func importFullBackup(from url: URL) throws -> LocalBackupPackage {
        try ExportImportService.shared.importFullBackup(from: url)
    }

    @discardableResult
    func importFullBackupWithReport(from url: URL) throws -> LocalBackupImportResult {
        try ExportImportService.shared.importFullBackupWithReport(from: url)
    }
}

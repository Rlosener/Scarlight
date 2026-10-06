import Foundation

struct LocalBackupImportReport: Equatable {
    let packageVersion: Int
    let importedAt: Date
    let userCardCount: Int
    let preferenceCount: Int
    let penaltyCount: Int
    let historyCount: Int
    let presetCount: Int
    let userPropCount: Int
    let skippedCount: Int
    let warnings: [String]

    var summaryText: String {
        let base = "\(userCardCount) kart · \(historyCount) geçmiş · \(presetCount) preset · \(userPropCount) eşya"
        if warnings.isEmpty, skippedCount == 0 {
            return "\(base) içe aktarıldı."
        }
        return "\(base) içe aktarıldı · \(skippedCount) atlandı · \(warnings.count) uyarı."
    }
}

struct LocalBackupImportResult: Equatable {
    let package: LocalBackupPackage
    let report: LocalBackupImportReport
}

struct LocalBackupPackage: Codable, Equatable {
    static let currentVersion = 3

    let version: Int
    let exportedAt: Date
    var userCards: [GameCard]
    var cardPreferences: [String: CardPreference]
    var penalties: [PenaltyCard]
    var history: [PlayedSessionRecord]
    var sessionPresets: [SessionPreset]
    var userProps: [UserProp]
    var sessionConfig: GameSessionConfig
    var timerDefaults: TimerDefaults
    var players: [Player]?
    var partnerPlayerIds: [UUID]?
    var editedPacks: [String: [DeckPackEntry]]?
    var playedCardIds: Set<String>?

    init(
        version: Int = LocalBackupPackage.currentVersion,
        exportedAt: Date = Date(),
        userCards: [GameCard],
        cardPreferences: [String: CardPreference],
        penalties: [PenaltyCard],
        history: [PlayedSessionRecord],
        sessionPresets: [SessionPreset],
        userProps: [UserProp],
        sessionConfig: GameSessionConfig,
        timerDefaults: TimerDefaults,
        players: [Player]? = nil,
        partnerPlayerIds: [UUID]? = nil,
        editedPacks: [String: [DeckPackEntry]]? = nil,
        playedCardIds: Set<String>? = nil
    ) {
        self.version = version
        self.exportedAt = exportedAt
        self.userCards = userCards
        self.cardPreferences = cardPreferences
        self.penalties = penalties
        self.history = history
        self.sessionPresets = sessionPresets
        self.userProps = userProps
        self.sessionConfig = sessionConfig
        self.timerDefaults = timerDefaults
        self.players = players
        self.partnerPlayerIds = partnerPlayerIds
        self.editedPacks = editedPacks
        self.playedCardIds = playedCardIds
    }

    static func current() throws -> LocalBackupPackage {
        let store = LocalJSONStore.shared
        var packs: [String: [DeckPackEntry]] = [:]
        for filename in PackFileStore.packFilenames where store.fileExists(filename) {
            packs[filename] = try store.load(from: filename, as: [DeckPackEntry].self)
        }
        return LocalBackupPackage(
            userCards: CardCatalog.loadUserCards(),
            cardPreferences: CardPreferencesStore.loadAll(),
            penalties: PenaltyCatalog.loadForGameplay(),
            history: PlayedHistoryStore.load(),
            sessionPresets: SessionPresetStore.loadUserPresets(),
            userProps: UserPropStore.load(),
            sessionConfig: SessionConfigStore.load(),
            timerDefaults: TimerDefaultsStore.load(),
            players: store.fileExists("players.json") ? try store.load(from: "players.json", as: [Player].self) : [],
            partnerPlayerIds: PartnerPairingStore.load(),
            editedPacks: packs,
            playedCardIds: PlayedCardHistoryStore.load()
        )
    }

    var restoreSummary: String {
        "\(userCards.count) kart · \(history.count) geçmiş · \(sessionPresets.count) şablon · \(userProps.count) eşya"
    }

    func validateForImport() throws {
        guard (1...Self.currentVersion).contains(version) else {
            throw LocalDataError.invalid("Bu yedek sürümü desteklenmiyor (\(version)). Uygulamayı güncelleyin.")
        }
        try LocalDataValidation.validateCards(userCards)
        try LocalDataValidation.requireUnique(penalties.map(\.id), label: "Cezalar")
        try LocalDataValidation.requireUnique(history.map(\.id), label: "Geçmiş")
        try LocalDataValidation.requireUnique(sessionPresets.map(\.id), label: "Şablonlar")
        try LocalDataValidation.requireUnique(userProps.map(\.id), label: "Eşyalar")
        if let players {
            try LocalDataValidation.requireUnique(players.map(\.id), label: "Oyuncular")
            guard players.allSatisfy({ !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.jokersRemaining >= 0 }) else {
                throw LocalDataError.invalid("Oyuncu bilgileri geçersiz.")
            }
            let ids = Set(players.map(\.id))
            guard (partnerPlayerIds ?? []).allSatisfy({ ids.contains($0) }) else {
                throw LocalDataError.invalid("Partner eşleştirmesi yedekte bulunmayan bir oyuncuya bağlı.")
            }
        }
        for (filename, entries) in editedPacks ?? [:] {
            guard PackFileStore.packFilenames.contains(filename),
                  entries.allSatisfy({ PackFileStore.packFilename(forCardId: $0.id) == filename }) else {
                throw LocalDataError.invalid("Yedekte geçersiz bir deste dosyası var.")
            }
            try LocalDataValidation.validateCards(entries.map { $0.toGameCard() })
        }
        let durations = [timerDefaults.beginningSeconds, timerDefaults.mediumSeconds,
                         timerDefaults.hotSeconds, timerDefaults.penaltyFloorSeconds]
        guard durations.allSatisfy({ (1...3600).contains($0) }),
              penalties.allSatisfy({ (0...3600).contains($0.durationSeconds) }) else {
            throw LocalDataError.invalid("Yedekte geçersiz süre ayarı var.")
        }
        for record in history {
            try LocalDataValidation.requireUnique(record.replayPlayers.map(\.id), label: "Tekrar oynatma oyuncuları")
            try LocalDataValidation.requireUnique(record.playerStats.map(\.id), label: "Oyuncu istatistikleri")
        }
    }

    func importReport(importedAt: Date = Date()) -> LocalBackupImportReport {
        var warnings: [String] = []
        if version < LocalBackupPackage.currentVersion {
            warnings.append("Eski yedekte bulunmayan oyuncu ve deste verileri bu cihazda korunur.")
        }

        let duplicateCardIds = userCards.map(\.id).duplicatesCount
        let duplicatePresetIds = sessionPresets.map(\.id).duplicatesCount
        if duplicateCardIds > 0 {
            warnings.append("\(duplicateCardIds) aynı kart kimliği bulundu; içe aktarmadan önce düzeltin.")
        }
        if duplicatePresetIds > 0 {
            warnings.append("\(duplicatePresetIds) aynı şablon kimliği bulundu; içe aktarmadan önce düzeltin.")
        }

        return LocalBackupImportReport(
            packageVersion: version,
            importedAt: importedAt,
            userCardCount: userCards.count,
            preferenceCount: cardPreferences.count,
            penaltyCount: penalties.count,
            historyCount: history.count,
            presetCount: sessionPresets.count,
            userPropCount: userProps.count,
            skippedCount: 0,
            warnings: warnings
        )
    }
}

enum LocalBackupActivityStore {
    private static let key = "lastLocalBackupActivity"

    static var statusText: String {
        UserDefaults.standard.string(forKey: key) ?? "Henüz yok"
    }

    static func markExported() {
        UserDefaults.standard.set("Dışa aktarıldı · \(Date().formatted(date: .abbreviated, time: .shortened))", forKey: key)
    }

    static func markImported(_ report: LocalBackupImportReport) {
        UserDefaults.standard.set("İçe aktarıldı · \(report.importedAt.formatted(date: .abbreviated, time: .shortened))", forKey: key)
    }
}

private extension Array where Element: Hashable {
    var duplicatesCount: Int {
        var seen: Set<Element> = []
        var duplicates: Set<Element> = []
        for value in self {
            if !seen.insert(value).inserted {
                duplicates.insert(value)
            }
        }
        return duplicates.count
    }
}

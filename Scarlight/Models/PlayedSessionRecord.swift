import Foundation

struct PlayedSessionRecord: Identifiable, Codable, Equatable {
    struct PlayerStat: Identifiable, Codable, Equatable {
        let id: UUID
        let name: String
        let turnCount: Int
        let jokersRemaining: Int
    }

    let id: UUID
    let playedAt: Date
    let playerNames: [String]
    let totalTurns: Int
    let durationSeconds: Int
    let finalIntensity: IntensityLevel
    let completedCycles: Int
    let passCount: Int
    let penaltyCount: Int
    let jokersUsed: Int
    let enabledDeckCount: Int
    let propCount: Int
    let contentProfile: SessionContentProfile
    let phaseNames: [String]
    let enabledDeckNames: [String]
    let selectedPropNames: [String]
    let playerStats: [PlayerStat]
    let replayPlayers: [Player]
    let replayConfig: GameSessionConfig?

    init(summary: GameSessionSummary, playedAt: Date = Date()) {
        self.id = UUID()
        self.playedAt = playedAt
        self.playerNames = summary.playerNames
        self.totalTurns = summary.totalTurns
        self.durationSeconds = summary.durationSeconds
        self.finalIntensity = summary.finalIntensity
        self.completedCycles = summary.completedCycles
        self.passCount = summary.passCount
        self.penaltyCount = summary.penaltyCount
        self.jokersUsed = summary.jokersUsed
        self.enabledDeckCount = summary.enabledDeckCount
        self.propCount = summary.propCount
        self.contentProfile = summary.contentProfile
        self.phaseNames = summary.phasesPlayed
        self.enabledDeckNames = summary.enabledDeckNames
        self.selectedPropNames = summary.selectedPropNames
        self.playerStats = summary.playerStats.map {
            PlayerStat(
                id: $0.id,
                name: $0.name,
                turnCount: $0.turnCount,
                jokersRemaining: $0.jokersRemaining
            )
        }
        self.replayPlayers = summary.replayPlayers
        self.replayConfig = summary.replayConfig
    }

    enum CodingKeys: String, CodingKey {
        case id
        case playedAt
        case playerNames
        case totalTurns
        case durationSeconds
        case finalIntensity
        case completedCycles
        case passCount
        case penaltyCount
        case jokersUsed
        case enabledDeckCount
        case propCount
        case contentProfile
        case phaseNames
        case enabledDeckNames
        case selectedPropNames
        case playerStats
        case replayPlayers
        case replayConfig
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        playedAt = try container.decode(Date.self, forKey: .playedAt)
        playerNames = try container.decode([String].self, forKey: .playerNames)
        totalTurns = try container.decode(Int.self, forKey: .totalTurns)
        durationSeconds = try container.decode(Int.self, forKey: .durationSeconds)
        finalIntensity = try container.decode(IntensityLevel.self, forKey: .finalIntensity)
        completedCycles = try container.decode(Int.self, forKey: .completedCycles)
        passCount = try container.decode(Int.self, forKey: .passCount)
        penaltyCount = try container.decode(Int.self, forKey: .penaltyCount)
        jokersUsed = try container.decode(Int.self, forKey: .jokersUsed)
        enabledDeckCount = try container.decode(Int.self, forKey: .enabledDeckCount)
        propCount = try container.decode(Int.self, forKey: .propCount)
        contentProfile = try container.decodeIfPresent(SessionContentProfile.self, forKey: .contentProfile) ?? .intimate
        phaseNames = try container.decodeIfPresent([String].self, forKey: .phaseNames) ?? []
        enabledDeckNames = try container.decodeIfPresent([String].self, forKey: .enabledDeckNames) ?? []
        selectedPropNames = try container.decodeIfPresent([String].self, forKey: .selectedPropNames) ?? []
        playerStats = try container.decodeIfPresent([PlayerStat].self, forKey: .playerStats) ?? []
        replayPlayers = try container.decodeIfPresent([Player].self, forKey: .replayPlayers) ?? []
        replayConfig = try container.decodeIfPresent(GameSessionConfig.self, forKey: .replayConfig)
    }

    var formattedDate: String {
        playedAt.formatted(date: .abbreviated, time: .shortened)
    }

    var formattedDuration: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        if minutes > 0 { return "\(minutes) dk \(seconds) sn" }
        return "\(seconds) sn"
    }

    var canReplay: Bool {
        replayConfig != nil && replayPlayers.count >= 2
    }
}

enum PlayedHistoryStore {
    private static let filename = "playedHistory.json"
    private static let store = LocalJSONStore.shared
    private static let maxRecords = 50

    static func load() -> [PlayedSessionRecord] {
        guard store.fileExists(filename),
              let records = try? store.load(from: filename, as: [PlayedSessionRecord].self) else {
            return []
        }
        return records.sorted { $0.playedAt > $1.playedAt }
    }

    static func append(_ summary: GameSessionSummary) {
        var records = load()
        records.insert(PlayedSessionRecord(summary: summary), at: 0)
        if records.count > maxRecords {
            records = Array(records.prefix(maxRecords))
        }
        try? store.save(records, to: filename)
    }

    static func replace(_ records: [PlayedSessionRecord]) {
        let sorted = records.sorted { $0.playedAt > $1.playedAt }
        try? store.save(Array(sorted.prefix(maxRecords)), to: filename)
    }

    static func clear() {
        try? store.delete(filename)
    }
}

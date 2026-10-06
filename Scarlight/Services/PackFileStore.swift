import Foundation

/// Bundle deste JSON dosyalarının düzenlenebilir kopyalarını yönetir (Documents).
enum PackFileStore {
    static let deckPacksFilename = "deck_packs.json"
    static let propQuestionsFilename = "prop_questions.json"
    static let barSocialPacksFilename = "bar_social_packs.json"

    static let packFilenames = [deckPacksFilename, propQuestionsFilename, barSocialPacksFilename]

    static func packFilename(forCardId id: String) -> String? {
        if id.hasPrefix("prop_") { return propQuestionsFilename }
        if id.hasPrefix("bar_") { return barSocialPacksFilename }
        if id.hasPrefix("nhi_") || id.hasPrefix("ht_") ||
            id.hasPrefix("ha_") || id.hasPrefix("fr_") {
            return deckPacksFilename
        }
        return nil
    }

    static func isBundledPackCardId(_ id: String) -> Bool {
        packFilename(forCardId: id) != nil
    }

    /// Documents'ta düzenlenebilir kopya varsa onu, yoksa bundle'ı kullanır.
    static func loadEntries(named filename: String) -> [DeckPackEntry] {
        if let editable = loadEditableEntries(named: filename) {
            return editable
        }
        return loadBundleEntries(named: filename)
    }

    static func loadEditableEntries(named filename: String) -> [DeckPackEntry]? {
        let store = LocalJSONStore.shared
        guard store.fileExists(filename),
              let data = try? store.loadRawData(from: filename) else {
            return nil
        }
        return decodeEntries(from: data, filename: filename)
    }

    static func hasEditableCopy(named filename: String) -> Bool {
        LocalJSONStore.shared.fileExists(filename)
    }

    @discardableResult
    static func ensureEditableCopy(named filename: String) -> Bool {
        if hasEditableCopy(named: filename) { return true }
        let bundleEntries = loadBundleEntries(named: filename)
        guard !bundleEntries.isEmpty else { return false }
        return saveEntries(bundleEntries, named: filename)
    }

    @discardableResult
    static func deleteEntry(cardId: String, in filename: String) -> Bool {
        guard ensureEditableCopy(named: filename) else { return false }
        var entries = loadEditableEntries(named: filename) ?? []
        let before = entries.count
        entries.removeAll { $0.id == cardId }
        guard entries.count < before else { return false }
        return saveEntries(entries, named: filename)
    }

    @discardableResult
    static func saveEntries(_ entries: [DeckPackEntry], named filename: String) -> Bool {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(entries)
            try LocalJSONStore.shared.saveRawData(data, to: filename)
            DevResourceSync.writeToProjectResourcesIfPossible(filename: filename, data: data)
            return true
        } catch {
            print("PackFileStore: \(filename) kaydedilemedi — \(error)")
            return false
        }
    }

    static func loadBundleEntries(named filename: String) -> [DeckPackEntry] {
        let resourceName = filename.replacingOccurrences(of: ".json", with: "")
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return []
        }
        return decodeEntries(from: data, filename: filename) ?? []
    }

    private static func decodeEntries(from data: Data, filename: String) -> [DeckPackEntry]? {
        do {
            return try JSONDecoder().decode([DeckPackEntry].self, from: data)
        } catch {
            print("PackFileStore: \(filename) decode hatası — \(error)")
            return nil
        }
    }
}

struct DeckPackEntry: Codable, Equatable {
    let id: String
    let deckType: CardDeckType
    let contentTier: ContentTier
    let minPlayers: Int
    let maxPlayers: Int
    let phase: String
    let type: String
    let text: String
    let onYesTask: String?
    let durationSeconds: Int
    let intensity: Int
    let requiredPropIds: [String]?
    let propCategory: String?
    let title: String?

    func toGameCard() -> GameCard {
        let tier = contentTier
        let maxLevel: IntensityLevel = {
            switch tier {
            case .beginning: return .medium
            case .medium: return .hot
            case .hot: return .hardcore
            }
        }()
        let combined = [text, onYesTask].compactMap { $0 }.joined(separator: " ")
        let targetRule: TargetRule = {
            if maxPlayers <= 2 { return .randomOther }
            if PlaceholderRenderer.textReferencesTarget(combined)
                || PlaceholderRenderer.textReferencesThird(combined) {
                return .randomOther
            }
            return .none
        }()

        return GameCard(
            id: id,
            title: title ?? deckType.displayName,
            type: CardType.from(packKey: type),
            phase: GamePhase.from(packKey: phase),
            intensity: intensity,
            minIntensity: tier.intensityLevel,
            maxIntensity: maxLevel,
            durationSeconds: durationSeconds,
            actorRule: .currentPlayer,
            targetRule: targetRule,
            text: text,
            deckType: deckType,
            contentTier: contentTier,
            minPlayers: minPlayers,
            maxPlayers: maxPlayers,
            onYesTask: onYesTask,
            requiredPropIds: requiredPropIds,
            propCategory: propCategory.flatMap { PropCategory.from(packKey: $0) }
        )
    }
}

#if DEBUG
enum DevResourceSync {
    static func writeToProjectResourcesIfPossible(filename: String, data: Data) {
        _ = filename
        _ = data
    }
}
#else
enum DevResourceSync {
    static func writeToProjectResourcesIfPossible(filename: String, data: Data) {}
}
#endif

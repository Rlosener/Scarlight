import Foundation
import Combine

enum CardVisibilityFilter: String, CaseIterable, Identifiable {
    case all
    case active
    case hidden
    case favorites

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "Tümü"
        case .active: return "Aktif"
        case .hidden: return "Gizli"
        case .favorites: return "Favori"
        }
    }
}

enum CardQualityFilter: String, CaseIterable, Identifiable {
    case all
    case anyIssue
    case duplicateText
    case longText
    case unresolvedPlaceholder
    case playerScope
    case propSetup
    case timing

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "Tümü"
        case .anyIssue: return "Uyarılı"
        case .duplicateText: return ContentAuditKind.duplicateText.displayName
        case .longText: return ContentAuditKind.longText.displayName
        case .unresolvedPlaceholder: return ContentAuditKind.unresolvedPlaceholder.displayName
        case .playerScope: return ContentAuditKind.playerScope.displayName
        case .propSetup: return ContentAuditKind.propSetup.displayName
        case .timing: return ContentAuditKind.timing.displayName
        }
    }

    func matches(_ issues: [ContentAuditIssue]) -> Bool {
        switch self {
        case .all:
            return true
        case .anyIssue:
            return !issues.isEmpty
        case .duplicateText:
            return issues.contains { $0.kind == .duplicateText }
        case .longText:
            return issues.contains { $0.kind == .longText }
        case .unresolvedPlaceholder:
            return issues.contains { $0.kind == .unresolvedPlaceholder }
        case .playerScope:
            return issues.contains { $0.kind == .playerScope }
        case .propSetup:
            return issues.contains { $0.kind == .propSetup }
        case .timing:
            return issues.contains { $0.kind == .timing }
        }
    }
}

@MainActor
class CardEditorViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published private(set) var preferences: [String: CardPreference] = [:]
    @Published private(set) var cards: [GameCard] = []
    @Published private(set) var filteredCards: [GameCard] = []
    @Published private(set) var deckStats: [(CardDeckType, Int)] = []
    @Published private(set) var deletableCardIds: Set<String> = []
    @Published private(set) var auditSummary: CardContentAuditSummary = .empty
    @Published private(set) var qualityIssuesByCardId: [String: [ContentAuditIssue]] = [:]
    @Published var playerFilter: PlayerCountFilter = .all {
        didSet { refreshFilteredCards() }
    }
    @Published var deckFilter: CardDeckType? {
        didSet { refreshFilteredCards() }
    }
    @Published var tierFilter: ContentTier? {
        didSet { refreshFilteredCards() }
    }
    @Published var visibilityFilter: CardVisibilityFilter = .all {
        didSet { refreshFilteredCards() }
    }
    @Published var qualityFilter: CardQualityFilter = .all {
        didSet { refreshFilteredCards() }
    }
    @Published var searchText: String = "" {
        didSet { scheduleSearchRefresh() }
    }

    private var searchIndexByCardId: [String: String] = [:]
    private var searchDebounceTask: Task<Void, Never>?
    private let searchDebounceNanoseconds: UInt64 = 200_000_000

    init() {
        loadCards()
    }

    deinit {
        searchDebounceTask?.cancel()
    }

    func loadCards() {
        preferences = CardPreferencesStore.loadAll()
        cards = CardCatalog.loadForEditor()
        rebuildDerivedData()
    }

    private func rebuildDerivedData() {
        searchIndexByCardId = cards.reduce(into: [:]) { index, card in
            index[card.id] = [card.title, card.text, card.onYesTask ?? ""]
                .joined(separator: " ")
                .lowercased()
        }
        deletableCardIds = Set(cards.filter { CardCatalog.canDelete($0) }.map(\.id))
        deckStats = CardCatalog.deckStats(from: cards)
        let issues = CardContentAuditor.analyze(cards)
        qualityIssuesByCardId = Dictionary(grouping: issues, by: \.cardId)
        auditSummary = CardContentAuditor.summary(cards: cards, issues: issues)
        refreshFilteredCards()
    }

    private func scheduleSearchRefresh() {
        searchDebounceTask?.cancel()
        let delay = searchDebounceNanoseconds
        searchDebounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.refreshFilteredCards()
            }
        }
    }

    private func refreshFilteredCards() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        filteredCards = cards.filter { card in
            if let deckFilter, card.effectiveDeckType != deckFilter {
                return false
            }
            if let tierFilter, card.contentTier != tierFilter {
                return false
            }
            guard playerFilter.matches(minPlayers: card.minPlayers, maxPlayers: card.maxPlayers) else {
                return false
            }
            let hidden = !card.isActive || preferences[card.id]?.isHiddenFromPool == true
            let favorite = preferences[card.id]?.isFavorite == true
            switch visibilityFilter {
            case .all:
                break
            case .active:
                if !card.isActive || hidden { return false }
            case .hidden:
                if !hidden { return false }
            case .favorites:
                if !favorite { return false }
            }
            let issues = qualityIssuesByCardId[card.id] ?? []
            guard qualityFilter.matches(issues) else { return false }
            guard !query.isEmpty else { return true }
            return searchIndexByCardId[card.id]?.contains(query) == true
        }
    }

    func isFavorite(_ card: GameCard) -> Bool {
        preferences[card.id]?.isFavorite == true
    }

    func isHidden(_ card: GameCard) -> Bool {
        !card.isActive || preferences[card.id]?.isHiddenFromPool == true
    }

    func canDelete(_ card: GameCard) -> Bool {
        deletableCardIds.contains(card.id)
    }

    func qualityIssues(for card: GameCard) -> [ContentAuditIssue] {
        qualityIssuesByCardId[card.id] ?? []
    }

    @discardableResult
    private func performChange(_ action: () throws -> Void, reload: Bool = true) -> Bool {
        do {
            try action()
            preferences = CardPreferencesStore.loadAll()
            if reload { loadCards() } else { refreshFilteredCards() }
            return true
        } catch {
            errorMessage = "Değişiklik kaydedilemedi: \(error.localizedDescription)"
            return false
        }
    }

    func saveCards() {
        performChange { try CardCatalog.updateUserCards(cards.filter(\.isUserCard)) }
    }

    @discardableResult
    func addCard(_ card: GameCard) -> Bool {
        performChange { try CardCatalog.saveUserCard(card) }
    }

    func updateCard(_ card: GameCard) {
        guard card.isUserCard else { return }
        performChange { try CardCatalog.saveUserCard(card) }
    }

    @discardableResult
    func deleteCard(_ card: GameCard) -> Bool {
        let deleted = CardCatalog.deleteCard(card)
        if deleted { loadCards() }
        return deleted
    }

    func toggleCardActive(_ card: GameCard) {
        bulkSetActive(isHidden(card), for: [card])
    }

    func toggleFavorite(_ card: GameCard) {
        performChange({ try CardPreferencesStore.setFavorite(card.id, !isFavorite(card)) }, reload: false)
    }

    func bulkSetActive(_ active: Bool, for targets: [GameCard]) {
        guard !targets.isEmpty else { return }
        performChange({
            let ids = Set(targets.map(\.id))
            let userCards = CardCatalog.loadUserCards().map { card in
                var updated = card
                if ids.contains(card.id) { updated.isActive = active }
                return updated
            }
            var updatedPreferences = CardPreferencesStore.loadAll()
            for id in ids {
                var entry = updatedPreferences[id] ?? CardPreference()
                entry.isHiddenFromPool = !active
                updatedPreferences[id] = entry
            }
            let encoder = JSONEncoder()
            try LocalJSONStore.shared.saveBatch([
                CardCatalog.userCardsFilename: try encoder.encode(userCards),
                "card_preferences.json": try encoder.encode(updatedPreferences)
            ])
            cards = cards.map { card in
                var updated = card
                if ids.contains(card.id), card.isUserCard { updated.isActive = active }
                return updated
            }
            deckStats = CardCatalog.deckStats(from: cards)
            NotificationCenter.default.post(name: .cardsDidChange, object: nil)
        }, reload: false)
    }

    func bulkSetTierHidden(_ tier: ContentTier) {
        let targets = cards.filter { $0.contentTier == tier }
        bulkSetActive(false, for: targets)
    }
}

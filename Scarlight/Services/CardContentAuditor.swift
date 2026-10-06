import Foundation

enum ContentAuditSeverity: String, Codable {
    case info
    case warning
}

enum ContentAuditKind: String, Codable {
    case duplicateText
    case longText
    case unresolvedPlaceholder
    case playerScope
    case propSetup
    case timing

    var displayName: String {
        switch self {
        case .duplicateText: return "Duplicate"
        case .longText: return "Uzun metin"
        case .unresolvedPlaceholder: return "Placeholder"
        case .playerScope: return "Oyuncu uyumu"
        case .propSetup: return "Eşya"
        case .timing: return "Süre"
        }
    }
}

struct ContentAuditIssue: Identifiable, Codable, Equatable {
    let cardId: String
    let severity: ContentAuditSeverity
    let kind: ContentAuditKind
    let message: String

    var id: String {
        "\(cardId)-\(kind.rawValue)-\(message)"
    }
}

struct CardContentAuditSummary: Equatable {
    let totalCards: Int
    let issueCount: Int
    let warningCount: Int
    let duplicateCount: Int
    let longTextCount: Int
    let placeholderCount: Int

    static let empty = CardContentAuditSummary(
        totalCards: 0,
        issueCount: 0,
        warningCount: 0,
        duplicateCount: 0,
        longTextCount: 0,
        placeholderCount: 0
    )

    var statusText: String {
        if issueCount == 0 {
            return "\(totalCards) kart temiz"
        }
        return "\(issueCount) uyarı · \(totalCards) kart"
    }
}

enum CardContentAuditor {
    static func analyze(_ cards: [GameCard]) -> [ContentAuditIssue] {
        var issues: [ContentAuditIssue] = []
        let duplicateIds = duplicateCardIds(in: cards)

        for card in cards {
            if duplicateIds.contains(card.id) {
                issues.append(issue(card, .warning, .duplicateText, "Benzer metinli başka kart var."))
            }

            if card.text.count > 240 {
                issues.append(issue(card, .warning, .longText, "Ana metin çok uzun; kart ekranında sıkışabilir."))
            }

            if let task = card.onYesTask, task.count > 180 {
                issues.append(issue(card, .warning, .longText, "Cevap sonrası görev metni uzun."))
            }

            let scope = CardPlayerScope.from(minPlayers: card.minPlayers, maxPlayers: card.maxPlayers)
            let previewTexts = [card.text, card.onYesTask].compactMap { $0 }
            for text in previewTexts {
                for warning in PlaceholderRenderer.previewWarnings(rawText: text, playerScope: scope) {
                    issues.append(issue(card, .warning, .unresolvedPlaceholder, warning))
                }
            }

            if card.effectiveDeckType == .propTask, card.requiredPropIds?.isEmpty != false {
                issues.append(issue(card, .warning, .propSetup, "Eşya görevi ama requiredPropIds boş."))
            }

            if card.isTimedTaskCard, card.durationSeconds <= 0 {
                issues.append(issue(card, .warning, .timing, "Süreli görev için süre 0 görünüyor."))
            }
        }

        return issues
    }

    static func issuesByCardId(_ cards: [GameCard]) -> [String: [ContentAuditIssue]] {
        Dictionary(grouping: analyze(cards), by: \.cardId)
    }

    static func summary(cards: [GameCard], issues: [ContentAuditIssue]) -> CardContentAuditSummary {
        CardContentAuditSummary(
            totalCards: cards.count,
            issueCount: issues.count,
            warningCount: issues.filter { $0.severity == .warning }.count,
            duplicateCount: issues.filter { $0.kind == .duplicateText }.count,
            longTextCount: issues.filter { $0.kind == .longText }.count,
            placeholderCount: issues.filter { $0.kind == .unresolvedPlaceholder }.count
        )
    }

    private static func issue(
        _ card: GameCard,
        _ severity: ContentAuditSeverity,
        _ kind: ContentAuditKind,
        _ message: String
    ) -> ContentAuditIssue {
        ContentAuditIssue(cardId: card.id, severity: severity, kind: kind, message: message)
    }

    private static func duplicateCardIds(in cards: [GameCard]) -> Set<String> {
        let grouped = Dictionary(grouping: cards) { card in
            normalizedFingerprint(for: card)
        }

        return Set(
            grouped.values.flatMap { group -> [String] in
                guard group.count > 1 else { return [] }
                return group
                    .sorted { $0.id < $1.id }
                    .dropFirst()
                    .map(\.id)
            }
        )
    }

    private static func normalizedFingerprint(for card: GameCard) -> String {
        [card.text, card.onYesTask ?? ""]
            .joined(separator: " ")
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

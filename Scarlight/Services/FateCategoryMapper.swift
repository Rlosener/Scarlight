import Foundation

/// Zar ve çark için deste kartlarını kategoriye göre eşler.
enum FateCategoryMapper {
    static func deckTypes(for category: FateCategory, profile: SessionContentProfile = .intimate) -> Set<CardDeckType> {
        if profile == .social {
            switch category {
            case .question:
                return [.barTruth]
            case .touch, .dare:
                return [.barDare]
            case .role, .partner:
                return [.barDare, .barNeverHaveI]
            case .wild:
                return Set(CardDeckType.socialPlayableDefaults)
            }
        }
        switch category {
        case .question:
            return [.hardTruth]
        case .touch:
            return [.hardAction, .propTask]
        case .role:
            return [.fantasyRole]
        case .dare:
            return [.hardAction, .neverHaveI]
        case .partner:
            return [.hardAction, .fantasyRole, .propTask]
        case .wild:
            return Set(CardDeckType.playableDefaults)
        }
    }

    static func wheelDeckTypes(profile: SessionContentProfile = .intimate) -> Set<CardDeckType> {
        switch profile {
        case .social:
            return [.barDare, .barNeverHaveI]
        case .intimate:
            return [.hardAction, .fantasyRole, .propTask, .neverHaveI]
        }
    }

    static func wheelDeckTypes() -> Set<CardDeckType> {
        wheelDeckTypes(profile: .intimate)
    }

    static func preferredTiers(for category: FateCategory) -> Set<ContentTier>? {
        switch category {
        case .question, .touch:
            return [.beginning, .medium]
        case .role:
            return [.beginning, .medium, .hot]
        case .dare, .partner:
            return [.medium, .hot]
        case .wild:
            return nil
        }
    }

    static func isUsableContent(_ card: GameCard) -> Bool {
        guard !CardCatalog.isLegacyDemoCard(card) else { return false }
        guard !card.id.hasPrefix("sys_") else { return false }
        guard card.deckType != nil else { return false }
        let trimmed = card.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 8 else { return false }
        guard !trimmed.contains("{actor}, kader") else { return false }
        guard !trimmed.contains("çark tarafından seçildi") else { return false }
        return true
    }
}

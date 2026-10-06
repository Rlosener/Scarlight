import Foundation

/// Kart ve deste kartlarında gösterilen içerik uyarı etiketleri.
enum ContentLabel: String, Codable, CaseIterable, Identifiable {
    case verbal = "Sözlü"
    case physical = "Fiziksel"
    case rolePlay = "Rol"
    case food = "Yiyecek"
    case prop = "Eşya"
    case timed = "Süreli"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .verbal: return "text.bubble"
        case .physical: return "figure.2"
        case .rolePlay: return "theatermasks"
        case .food: return "leaf"
        case .prop: return "bag"
        case .timed: return "timer"
        }
    }
}

extension GameCard {
    var contentLabels: [ContentLabel] {
        var labels: [ContentLabel] = []
        switch effectiveDeckType {
        case .neverHaveI, .hardTruth, .barNeverHaveI, .barTruth:
            labels.append(.verbal)
        case .barDare:
            labels.append(.timed)
        case .hardAction:
            labels.append(.physical)
            labels.append(.timed)
        case .fantasyRole:
            labels.append(.rolePlay)
        case .propTask:
            labels.append(.prop)
            labels.append(.timed)
        case .standard:
            break
        }
        if isTimedTaskCard, !labels.contains(.timed) { labels.append(.timed) }
        if propCategory == .edibleReachable || requiredPropIds?.contains(where: { $0.hasPrefix("ed_") }) == true {
            if !labels.contains(.food) { labels.append(.food) }
        }
        return labels
    }
}

extension CardDeckType {
    var contentLabels: [ContentLabel] {
        switch self {
        case .neverHaveI, .hardTruth: return [.verbal]
        case .barNeverHaveI, .barTruth: return [.verbal]
        case .barDare: return [.timed]
        case .hardAction: return [.physical, .timed]
        case .fantasyRole: return [.rolePlay]
        case .propTask: return [.prop, .timed]
        case .standard: return []
        }
    }
}

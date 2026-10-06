import SwiftUI

struct AppTypography {
    static let logo = Font.system(size: 36, weight: .black, design: .default)
    static let display = Font.system(.largeTitle, design: .default, weight: .bold)
    static let phaseLabel = Font.system(size: 12, weight: .bold, design: .default).uppercaseSmallCaps()
    static let cardText = Font.system(.title2, design: .default, weight: .semibold)
    static let cardTextCompact = Font.system(.title3, design: .default, weight: .semibold)
    static let cardTextLong = Font.system(.body, design: .default, weight: .medium)

    static func cardTextFont(for characterCount: Int) -> Font {
        switch characterCount {
        case ..<70:
            return cardText
        case ..<130:
            return cardTextCompact
        default:
            return cardTextLong
        }
    }

    static let timer = Font.system(size: 64, weight: .black, design: .default).monospacedDigit()
    static let timerSmall = Font.system(size: 48, weight: .black, design: .default).monospacedDigit()
    static let button = Font.system(.headline, design: .default, weight: .bold)
    static let playerName = Font.system(.title3, design: .default, weight: .semibold)
    static let sectionTitle = Font.system(.title2, design: .default, weight: .bold)
    static let body = Font.system(.body)
    static let caption = Font.system(.subheadline, design: .default, weight: .medium)
    static let labelSmall = Font.system(.caption, design: .default, weight: .semibold)
}

import SwiftUI

enum ConversationPalette {
    static let background = Color(hex: "#0D0F14")
    static let question = Color(hex: "#BEADFF")
    static let answer = Color(hex: "#8BDAC7")
}

struct ConversationBackground: View {
    var body: some View {
        ConversationPalette.background
            .overlay {
                RadialGradient(colors: [ConversationPalette.question.opacity(0.07), .clear],
                               center: .topLeading, startRadius: 0, endRadius: 440)
            }
            .ignoresSafeArea()
    }
}

struct ConversationBubble<Content: View>: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.ffPerformanceMode) private var performanceMode
    let role: String
    let name: String
    var isAnswer = false
    @ViewBuilder let content: Content

    private var tint: Color { isAnswer ? ConversationPalette.answer : ConversationPalette.question }
    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: 22, bottomLeadingRadius: isAnswer ? 22 : 6,
                               bottomTrailingRadius: isAnswer ? 6 : 22, topTrailingRadius: 22)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 10) {
                Text(String(name.prefix(1)).uppercased(with: Locale(identifier: "tr_TR")))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.12), in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(role)
                        .font(.caption)
                        .foregroundColor(tint)
                    Text(name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if reduceTransparency || performanceMode {
                shape.fill(Color(hex: "#1B1D26"))
            } else {
                shape.fill(.ultraThinMaterial)
            }
            shape.fill(LinearGradient(colors: [tint.opacity(0.14), tint.opacity(0.035)],
                                      startPoint: .topLeading, endPoint: .bottomTrailing))
            shape.strokeBorder(LinearGradient(colors: [.white.opacity(0.18), tint.opacity(0.08)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        }
        .padding(isAnswer ? .leading : .trailing, 24)
    }
}

struct ConversationReplyPrompt: View {
    let name: String
    var message = "Söz sende."

    var body: some View {
        ConversationBubble(role: "Cevaplayan", name: name, isAnswer: true) {
            Text(message)
                .font(.body)
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

extension SessionTheme {
    static func conversation(for atmosphere: PlayAtmosphere) -> SessionTheme {
        var theme = forAtmosphere(atmosphere)
        theme.backgroundDeep = ConversationPalette.background
        theme.backgroundWine = ConversationPalette.background
        theme.cardDark = Color(hex: "#1B1D26")
        theme.cardElevated = Color(hex: "#232632")
        theme.accent = Color(hex: "#6860AD")
        theme.accentBright = ConversationPalette.question
        theme.accentSoft = ConversationPalette.answer
        theme.borderAccent = ConversationPalette.question.opacity(0.2)
        return theme
    }
}

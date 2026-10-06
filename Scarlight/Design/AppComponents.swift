import SwiftUI

private enum FFButtonTiming {
    static let tapCooldown: TimeInterval = 0.18
}

struct AppLogoMark: View {
    enum Style {
        case iconOnly
        case withTitle
        case compact
    }

    var style: Style = .withTitle
    var iconSize: CGFloat = 72
    var showsTagline: Bool = false

    @Environment(\.sessionTheme) private var theme
    @Environment(\.ffPerformanceMode) private var performanceMode
    @Environment(\.visualEffectBudget) private var effectBudget

    var body: some View {
        switch style {
        case .iconOnly:
            iconImage
        case .withTitle:
            VStack(spacing: 12) {
                iconImage
                titleBlock
                if showsTagline {
                    Text("Timed. Bold. Unpredictable.")
                        .font(AppTypography.caption)
                        .foregroundColor(theme.textSecondary)
                        .tracking(1.1)
                }
            }
        case .compact:
            HStack(spacing: 10) {
                iconImage
                    .frame(width: iconSize, height: iconSize)
                Text(AppConstants.gameNameDisplay)
                    .font(AppTypography.sectionTitle)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
    }

    private var iconImage: some View {
        ZStack {
            if !performanceMode && effectBudget.allowsPremiumGlow {
                RoundedRectangle(cornerRadius: iconSize * 0.30, style: .continuous)
                    .stroke(theme.borderAccent.opacity(0.75), lineWidth: 1.5)
                    .frame(width: iconSize + 18, height: iconSize + 18)
                    .shadow(color: theme.shadowGlow, radius: 22, x: 0, y: 0)
            }

            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
                .clipShape(RoundedRectangle(cornerRadius: iconSize * 0.22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: iconSize * 0.22, style: .continuous)
                        .stroke(AppColors.edgeLight.opacity(0.75), lineWidth: 1)
                )
                .shadow(
                    color: !performanceMode && effectBudget.allowsPremiumGlow ? theme.shadowGlow : .clear,
                    radius: min(14, effectBudget.shadowRadius),
                    x: 0,
                    y: 6
                )
        }
    }

    private var titleBlock: some View {
        Text(AppConstants.gameNameDisplay)
            .font(AppTypography.logo)
            .foregroundColor(AppColors.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

}

struct FFScreenHeader: View {
    let title: String
    var onBack: (() -> Void)? = nil
    var trailing: AnyView? = nil

    var body: some View {
        HStack(spacing: 12) {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 40, height: 40)
                        .ffGlassChipStyle(cornerRadius: 20)
                }
            } else {
                Color.clear.frame(width: 40, height: 40)
            }

            Spacer()

            Text(title)
                .font(AppTypography.sectionTitle)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer()

            if let trailing {
                trailing
            } else {
                Color.clear.frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}

struct FFBackground: View {
    @Environment(\.sessionTheme) private var theme
    @Environment(\.ffPerformanceMode) private var performanceMode
    @Environment(\.visualEffectBudget) private var effectBudget

    var body: some View {
        Group {
            if performanceMode || effectBudget == .reduced {
                performanceBackdrop
            } else {
                ZStack {
                    performanceBackdrop
                    premiumLightSweep
                        .opacity(effectBudget.ambientOpacity)
                    FFStageTexture()
                        .opacity(effectBudget.ambientOpacity)
                }
            }
        }
        .ignoresSafeArea()
    }

    private var performanceBackdrop: some View {
        ZStack {
            LinearGradient(
                colors: [
                    theme.backgroundHighlight.opacity(0.52),
                    theme.backgroundWine,
                    theme.backgroundDeep,
                    Color(hex: "#050104")
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            LinearGradient(
                colors: [
                    theme.radialAccent.opacity(0.16),
                    Color.clear,
                    theme.radialSecondary.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            AppColors.stageDepth
        }
    }

    private var premiumLightSweep: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.white.opacity(0.07),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    theme.accentBright.opacity(0.14),
                    Color.clear,
                    theme.accentSoft.opacity(0.08)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .blendMode(.screen)
        }
    }
}

private struct FFStageTexture: View {
    @Environment(\.sessionTheme) private var theme

    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 34
            let stroke = StrokeStyle(lineWidth: 0.55, lineCap: .round)
            for index in stride(from: -size.height, through: size.width + size.height, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: index, y: 0))
                path.addLine(to: CGPoint(x: index + size.height, y: size.height))
                context.stroke(
                    path,
                    with: .color(theme.accentSoft.opacity(0.055)),
                    style: stroke
                )
            }
        }
        .allowsHitTesting(false)
    }
}

struct FFPrimaryButton: View {
    @Environment(\.sessionTheme) private var theme
    @Environment(\.ffPerformanceMode) private var performanceMode
    @Environment(\.visualEffectBudget) private var effectBudget

    let title: String
    let action: () -> Void
    var isEnabled: Bool = true

    @State private var isCoolingDown = false

    var body: some View {
        Button {
            guard isEnabled, !isCoolingDown else { return }
            guard TapThrottle.tryFire(key: "primary.\(title)", cooldown: FFButtonTiming.tapCooldown) else { return }
            isCoolingDown = true
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + FFButtonTiming.tapCooldown) {
                isCoolingDown = false
            }
        } label: {
            Text(title)
                .font(AppTypography.button)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(isEnabled ? theme.accent : theme.accentMuted)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .opacity(isCoolingDown ? 0.8 : 1)

        }
        .disabled(!isEnabled || isCoolingDown)
    }
}

struct FFSecondaryButton: View {
    let title: String
    let action: () -> Void

    @State private var isCoolingDown = false

    var body: some View {
        Button {
            guard !isCoolingDown else { return }
            guard TapThrottle.tryFire(key: "secondary.\(title)", cooldown: FFButtonTiming.tapCooldown) else { return }
            isCoolingDown = true
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + FFButtonTiming.tapCooldown) {
                isCoolingDown = false
            }
        } label: {
            Text(title)
                .font(AppTypography.button)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, minHeight: 54)
                .ffGlassPanelStyle(cornerRadius: 14)
        }
        .disabled(isCoolingDown)
    }
}

struct FFDangerButton: View {
    @Environment(\.sessionTheme) private var theme

    let title: String
    let action: () -> Void

    @State private var isCoolingDown = false

    var body: some View {
        Button {
            guard !isCoolingDown else { return }
            guard TapThrottle.tryFire(key: "danger.\(title)", cooldown: FFButtonTiming.tapCooldown) else { return }
            isCoolingDown = true
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + FFButtonTiming.tapCooldown) {
                isCoolingDown = false
            }
        } label: {
            Text(title)
                .font(AppTypography.button)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(AppColors.glassDeep)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(theme.accentMuted.opacity(0.55), lineWidth: 1)
                )
        }
        .disabled(isCoolingDown)
    }
}

struct FFCard: View {
    let content: AnyView

    var body: some View {
        content
            .padding(26)
            .ffGlassPanelStyle(cornerRadius: 28)
    }
}

struct FFGlassPanel: View {
    let content: AnyView

    var body: some View {
        content
            .padding(28)
            .ffGlassPanelStyle(cornerRadius: 24)
    }
}

struct AdaptiveCardText: View, Equatable {
    @Environment(\.visualEffectBudget) private var effectBudget

    let text: String

    static func == (lhs: AdaptiveCardText, rhs: AdaptiveCardText) -> Bool {
        lhs.text == rhs.text
    }

    var body: some View { cardText }

    private var cardText: some View {
        Text(text)
            .font(AppTypography.cardTextFont(for: text.count))
            .foregroundColor(AppColors.textPrimary)
            .multilineTextAlignment(.leading)
            .lineSpacing(6)
            .shadow(
                color: effectBudget.allowsPremiumGlow ? AppColors.shadowColor.opacity(0.35) : .clear,
                radius: effectBudget.allowsPremiumGlow ? 2 : 0,
                x: 0,
                y: 1
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct FFTimerDisplay: View {
    @Environment(\.sessionTheme) private var theme
    @Environment(\.visualEffectBudget) private var effectBudget

    let seconds: Int
    var isRunning: Bool = false
    var isWarning: Bool = false
    var compact: Bool = false

    var body: some View {
        Text(formatTime(seconds))
            .font(compact ? AppTypography.timerSmall : AppTypography.timer)
            .foregroundColor(isWarning ? theme.accentBright : AppColors.textPrimary)
            .monospacedDigit()
            .shadow(
                color: isWarning && effectBudget.allowsPremiumGlow ? theme.glow : .clear,
                radius: isWarning ? min(12, effectBudget.shadowRadius) : 0,
                x: 0,
                y: 0
            )
    }

    private func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct CardTextPreviewView: View {
    let rawText: String
    let duration: Int
    var phase: GamePhase = .boldQuestion
    var playerScope: CardPlayerScope = .mixed
    var secondaryRawText: String?
    var itemName: String? = "kırbaç"

    private var trimmedPrimary: String {
        rawText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var previewPrimary: String {
        guard !trimmedPrimary.isEmpty else { return "…" }
        return PlaceholderRenderer.previewRender(
            trimmedPrimary,
            duration: duration,
            phase: phase,
            playerScope: playerScope,
            itemName: itemName
        )
    }

    private var previewSecondary: String? {
        guard let secondaryRawText else { return nil }
        let trimmed = secondaryRawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return PlaceholderRenderer.previewRender(
            trimmed,
            duration: duration,
            phase: phase,
            playerScope: playerScope,
            itemName: itemName
        )
    }

    private var warnings: [String] {
        var list = PlaceholderRenderer.previewWarnings(rawText: trimmedPrimary, playerScope: playerScope)
        if let secondaryRawText {
            list.append(contentsOf: PlaceholderRenderer.previewWarnings(rawText: secondaryRawText, playerScope: playerScope))
        }
        return list
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Önizleme")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                Text(CardPreviewSamples.roleLegend(for: playerScope))
                    .font(AppTypography.labelSmall)
                    .foregroundColor(AppColors.softRose)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(previewPrimary)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let secondary = previewSecondary {
                    Text("Yaptıysan: \(secondary)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(14)
            .ffGlassCardStyle(cornerRadius: 16, glow: false)
        }
    }
}

struct CardPlayerScopePicker: View {
    @Binding var scope: CardPlayerScope

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Oyuncu Sayısı")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)

            Picker("Oyuncu Sayısı", selection: $scope) {
                ForEach(CardPlayerScope.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.segmented)

            Text(scope.hint)
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.softRose)
        }
    }
}

struct PlayerCountFilterBar: View {
    @Environment(\.sessionTheme) private var theme
    @Binding var filter: PlayerCountFilter

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Oyuncu filtresi")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PlayerCountFilter.allCases) { option in
                        Button {
                            filter = option
                        } label: {
                            Text(option.displayName)
                                .font(AppTypography.labelSmall)
                                .foregroundColor(filter == option ? .white : AppColors.textSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background {
                                    if filter == option {
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .fill(theme.heroGradient)
                                    } else {
                                        FFGlassBackground(cornerRadius: 20, style: .chip)
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(filter == option ? AppColors.borderStrong : AppColors.borderSoft, lineWidth: 1)
                                )
                        }
                    }
                }
            }
        }
    }
}

struct FFTopBar: View {
    @Environment(\.sessionTheme) private var theme
    let title: String
    let phaseLabel: String?
    let onSafeStop: () -> Void
    let onSettings: (() -> Void)?
    var onAddCard: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .tracking(0.6)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                if let phaseLabel {
                    Text(phaseLabel.uppercased())
                        .font(AppTypography.phaseLabel)
                        .foregroundColor(theme.accentBright)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let onAddCard {
                Button(action: onAddCard) {
                    Image(systemName: "plus").frame(width: 44, height: 44)
                }
                .accessibilityLabel("Hızlı kart ekle")
            }
            if let onSettings {
                Button(action: onSettings) {
                    Image(systemName: "gearshape").frame(width: 44, height: 44)
                }
                .accessibilityLabel("Ayarlar")
            }
            Button(action: onSafeStop) {
                Image(systemName: "pause.fill")
                    .foregroundColor(theme.accentBright)
                    .frame(width: 44, height: 44)
                    .background(theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }
            .accessibilityLabel("Oyunu duraklat")
        }
        .font(.system(size: 17, weight: .semibold))
        .foregroundColor(AppColors.textSecondary)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

struct FFPlayerChip: View {
    let name: String
    let color: Color
    var isActive: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 1))

            Text(name)
                .font(AppTypography.caption)
                .foregroundColor(isActive ? AppColors.textPrimary : AppColors.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background {
            if isActive {
                FFGlassBackground(cornerRadius: 16, style: .chip, glow: true)
            } else {
                FFGlassBackground(cornerRadius: 16, style: .chip)
            }
        }
    }
}

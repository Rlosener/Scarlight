import SwiftUI

struct ModeSceneStrip: View {
    @Environment(\.visualEffectBudget) private var effectBudget

    let experience: ModeExperienceSpec
    var compact: Bool = false

    private var theme: SessionTheme { experience.theme }
    private var height: CGFloat { compact ? 78 : 118 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: compact ? 12 : 16, style: .continuous)
                .fill(theme.cardElevated)

            LinearGradient(
                colors: [
                    theme.accent.opacity(0.08),
                    Color.clear,
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if effectBudget.allowsAmbientTexture {
                sceneLayer
                    .opacity(effectBudget.ambientOpacity)
            }

            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(experience.selectionBadge.uppercased())
                        .font(AppTypography.labelSmall)
                        .foregroundColor(.white.opacity(0.72))
                        .tracking(1.4)
                    Text(experience.conceptName)
                        .font(compact ? AppTypography.caption : AppTypography.button)
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: experience.primarySymbol)
                    .font(.system(size: compact ? 28 : 38, weight: .bold))
                    .foregroundColor(.white.opacity(0.92))
            }
            .padding(compact ? 16 : 20)
        }
        .frame(minHeight: height)
        .clipShape(RoundedRectangle(cornerRadius: compact ? 12 : 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: compact ? 12 : 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: effectBudget.allowsPremiumGlow ? theme.shadowGlow : .clear, radius: effectBudget.shadowRadius, x: 0, y: 8)
    }

    @ViewBuilder
    private var sceneLayer: some View {
        switch experience.sceneTreatment {
        case .bar:
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { index in
                    Capsule()
                        .fill(Color.white.opacity(index.isMultiple(of: 2) ? 0.18 : 0.10))
                        .frame(width: 12, height: CGFloat(26 + (index % 3) * 14))
                }
                Spacer()
                Image(systemName: experience.secondarySymbol)
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.12))
            }
            .padding(18)

        case .flame:
            HStack {
                ForEach(0..<4, id: \.self) { index in
                    Image(systemName: "flame.fill")
                        .font(.system(size: CGFloat(28 + index * 8), weight: .bold))
                        .foregroundColor(Color.white.opacity(0.10 + Double(index) * 0.02))
                        .offset(y: CGFloat(index % 2 == 0 ? 8 : -6))
                }
                Spacer()
                Image(systemName: experience.secondarySymbol)
                    .font(.system(size: 62, weight: .black))
                    .foregroundColor(Color.white.opacity(0.14))
            }
            .padding(18)

        case .privateRoom:
            ZStack {
                HStack(spacing: 10) {
                    ForEach(0..<5, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(index == 2 ? 0.16 : 0.08))
                            .frame(width: 38, height: CGFloat(78 + index * 8))
                            .rotationEffect(.degrees(-12))
                    }
                    Spacer()
                }
                Image(systemName: experience.secondarySymbol)
                    .font(.system(size: 58, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.13))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 20)
            }
            .padding(.vertical, 12)
        }
    }
}

struct ModeConceptPill: View {
    let title: String
    let icon: String
    var isEmphasized: Bool = false

    @Environment(\.sessionTheme) private var theme

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(title)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(AppTypography.labelSmall)
        .foregroundColor(isEmphasized ? .white : theme.accentSoft)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(minHeight: 30)
        .background(isEmphasized ? theme.accent.opacity(0.34) : theme.cardElevated.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isEmphasized ? theme.borderAccent : AppColors.borderSoft, lineWidth: 1)
        )
    }
}

struct ModeSetupHeroCard: View {
    let experience: ModeExperienceSpec
    let playerCount: Int
    let playableCardCount: Int
    let summary: String

    @Environment(\.sessionTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ModeSceneStrip(experience: experience, compact: true)

            VStack(alignment: .leading, spacing: 8) {
                Text(experience.setupTitle)
                    .font(AppTypography.button)
                    .foregroundColor(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(experience.setupSubtitle)
                    .font(AppTypography.labelSmall)
                    .foregroundColor(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            FlowLayout(spacing: 8) {
                ModeConceptPill(title: "\(max(playerCount, 2)) oyuncu", icon: "person.2.fill", isEmphasized: true)
                ModeConceptPill(title: "\(playableCardCount) kart", icon: "rectangle.stack.fill")
                ModeConceptPill(title: summary, icon: "checkmark.seal.fill")
            }
        }
        .padding(16)
        .ffGlassPanelStyle(cornerRadius: 22, glow: true)
    }
}

struct GameModeRibbon: View, Equatable {
    let experience: ModeExperienceSpec
    let primaryText: String
    let secondaryText: String

    @Environment(\.sessionTheme) private var theme

    static func == (lhs: GameModeRibbon, rhs: GameModeRibbon) -> Bool {
        lhs.experience == rhs.experience &&
            lhs.primaryText == rhs.primaryText &&
            lhs.secondaryText == rhs.secondaryText
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: experience.primarySymbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(theme.accentBright)
                .frame(width: 32, height: 32)
                .background(theme.accent.opacity(0.18))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(primaryText.uppercased())
                    .font(AppTypography.labelSmall)
                    .foregroundColor(theme.accentSoft)
                    .tracking(1.2)
                Text(secondaryText)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 8)

            Text(experience.cardChromeLabel)
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minHeight: 58)
        .ffGlassChipStyle(cornerRadius: 22)
    }
}

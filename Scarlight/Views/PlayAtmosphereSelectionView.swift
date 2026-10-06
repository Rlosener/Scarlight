import SwiftUI

struct PlayAtmosphereSelectionView: View {
    let players: [Player]
    var onBack: (() -> Void)? = nil
    var onOpenMenu: (() -> Void)? = nil
    var onSelect: (PlayAtmosphere) -> Void

    @State private var isSelecting = false

    var body: some View {
        ZStack {
            FFBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    VStack(alignment: .leading, spacing: 10) {
                        Text("GECE SİZİN.")
                            .font(AppTypography.labelSmall)
                            .tracking(2.4)
                            .foregroundColor(AppColors.rubyBright)
                        Text("Ritmini seç.")
                            .font(AppTypography.display)
                            .foregroundColor(AppColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(players.count >= 2 ? "\(players.count) oyuncu hazır. Bir mod seçerek devam et." : "Bir mod seç, oyuncularını ekle ve başla.")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    VStack(spacing: 12) {
                        ForEach(Array(PlayAtmosphere.selectionOptions.enumerated()), id: \.element.id) { index, atmosphere in
                            atmosphereCard(atmosphere, number: index + 1)
                        }
                    }
                    .allowsHitTesting(!isSelecting)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear { isSelecting = false }
    }

    private var header: some View {
        HStack(spacing: 12) {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Geri")
            }
            AppLogoMark(style: .compact, iconSize: 38)
            Spacer(minLength: 8)
            if let onOpenMenu {
                Button(action: onOpenMenu) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .ffGlassChipStyle(cornerRadius: 12)
                }
                .accessibilityLabel("Menü")
            }
        }
        .foregroundColor(AppColors.textPrimary)
    }

    private func atmosphereCard(_ atmosphere: PlayAtmosphere, number: Int) -> some View {
        let experience = atmosphere.experience
        let accent = experience.theme.accentBright
        return Button {
            guard !isSelecting else { return }
            guard TapThrottle.tryFire(key: "atmosphere.\(atmosphere.id)", cooldown: 0.22) else { return }
            isSelecting = true
            HapticManager.shared.success()
            onSelect(atmosphere)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { isSelecting = false }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(String(format: "%02d", number))
                        .font(.system(.caption, design: .monospaced, weight: .medium))
                        .foregroundColor(AppColors.textMuted)
                    Text(experience.selectionBadge.uppercased())
                        .font(AppTypography.labelSmall)
                        .tracking(1.4)
                        .foregroundColor(accent)
                    Spacer(minLength: 8)
                    Image(systemName: experience.primarySymbol)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(accent)
                }
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(experience.heroTitle)
                            .font(AppTypography.sectionTitle)
                            .foregroundColor(AppColors.textPrimary)
                        Text(experience.moodLine)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textMuted)
                        .padding(.top, 4)
                }
            }
            .multilineTextAlignment(.leading)
            .padding(20)
            .background(AppColors.cardDark)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.09), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("mode-\(atmosphere.id)")
    }
}

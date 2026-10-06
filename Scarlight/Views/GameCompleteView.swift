import SwiftUI

struct GameCompleteView: View {
    @Environment(\.sessionTheme) private var theme

    let summary: GameSessionSummary
    var onPlayAgain: () -> Void
    var onHome: () -> Void

    var body: some View {
        ZStack {
            FFBackground()

            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 10) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 44))
                            .foregroundColor(theme.accent)
                            .shadow(color: theme.glow.opacity(0.5), radius: 16)

                        Text("Oturum Tamamlandı")
                            .font(AppTypography.sectionTitle)
                            .foregroundColor(AppColors.textPrimary)

                        Text("Tüm fazlar oynandı — harika bir gece.")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 48)

                    statsGrid
                    extraStats

                    if !summary.playerStats.isEmpty {
                        playerStatsSection
                    }

                    ShareLink(item: summary.shareText) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Özeti Paylaş")
                        }
                        .font(AppTypography.labelSmall)
                        .foregroundColor(theme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .ffGlassPanelStyle(cornerRadius: 16)
                    }
                    .padding(.horizontal, 20)

                    VStack(spacing: 12) {
                        FFPrimaryButton(title: "Tekrar Oyna", action: onPlayAgain)
                        FFSecondaryButton(title: "Ana Menü", action: onHome)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 48)
                }
            }
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
    }

    private var statsGrid: some View {
        HStack(spacing: 12) {
            statTile(title: "Tur", value: "\(summary.totalTurns)")
            statTile(title: "Süre", value: summary.formattedDuration)
            statTile(title: "Yoğunluk", value: summary.finalIntensity.displayName)
        }
        .padding(.horizontal, 20)
    }

    private var extraStats: some View {
        HStack(spacing: 12) {
            statTile(title: "Pas", value: "\(summary.passCount)")
            statTile(title: "Ceza", value: "\(summary.penaltyCount)")
            statTile(title: "Joker", value: "\(summary.jokersUsed)")
        }
        .padding(.horizontal, 20)
    }

    private func statTile(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(title.uppercased())
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.textSecondary)
                .tracking(1)
            Text(value)
                .font(AppTypography.button)
                .foregroundColor(AppColors.champagne)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .ffGlassPanelStyle(cornerRadius: 16)
    }

    private var playerStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OYUNCULAR")
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.textSecondary)
                .tracking(1.2)
                .padding(.horizontal, 24)

            VStack(spacing: 8) {
                ForEach(summary.playerStats) { stat in
                    HStack {
                        Text(stat.name)
                            .font(AppTypography.button)
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Text("\(stat.turnCount) tur")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                        Text("·")
                            .foregroundColor(AppColors.textSecondary.opacity(0.5))
                        Text("\(stat.jokersRemaining) joker")
                            .font(AppTypography.caption)
                            .foregroundColor(theme.accentSoft)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .ffGlassPanelStyle(cornerRadius: 14)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

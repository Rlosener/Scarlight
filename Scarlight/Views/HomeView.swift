import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppStateViewModel
    @EnvironmentObject private var playerVM: PlayerSetupViewModel
    @Environment(\.sessionTheme) private var theme
    @Environment(\.visualEffectBudget) private var effectBudget
    var onBack: (() -> Void)? = nil

    var body: some View {
        ZStack {
            FFBackground()

            ScrollView {
                VStack(spacing: 0) {
                    if let onBack {
                        FFScreenHeader(title: "Menü", onBack: onBack)
                            .padding(.bottom, 8)
                    }

                    header
                        .padding(.top, onBack == nil ? 52 : 8)
                        .padding(.bottom, 20)

                    if appState.restorableSnapshot != nil {
                        resumeBanner
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                    }

                    playButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                    if playerVM.canStartGame {
                        quickStartButton
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                    } else {
                        Spacer().frame(height: 8)
                    }

                    menuSection(title: "Hazırlık") {
                        HomeMenuRow(
                            title: "Kişiler",
                            subtitle: playerSubtitle,
                            icon: "person.2.fill"
                        ) {
                            appState.navigate(.players)
                        }

                        HomeMenuRow(
                            title: "Eşya & Desteler",
                            subtitle: deckSubtitle,
                            icon: "square.grid.2x2.fill"
                        ) {
                            appState.navigate(.decksAndProps)
                        }

                        HomeMenuRow(
                            title: "Özel Eşyalar",
                            subtitle: "\(UserPropStore.load().count) özel eşya",
                            icon: "plus.circle.fill"
                        ) {
                            appState.navigate(.customProps)
                        }
                    }

                    menuSection(title: "İçerik") {
                        HomeMenuRow(
                            title: "Kartlar",
                            subtitle: "Düzenle, ekle veya kapat",
                            icon: "rectangle.stack.fill"
                        ) {
                            appState.navigate(.cards)
                        }

                        HomeMenuRow(
                            title: "Oyun Geçmişi",
                            subtitle: historySubtitle,
                            icon: "clock.arrow.circlepath"
                        ) {
                            appState.navigate(.history)
                        }
                    }

                    menuSection(title: "Uygulama") {
                        HomeMenuRow(
                            title: "Ayarlar",
                            subtitle: "Ses, süre, veri ve cezalar",
                            icon: "gearshape.fill"
                        ) {
                            appState.navigate(.settings)
                        }
                    }

                    Text("Scarlight")
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.textMuted)
                        .padding(.top, 28)
                        .padding(.bottom, 48)
                }
            }
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .navigationBarHidden(true)
        .onAppear {
            playerVM.loadPlayers()
            appState.refreshRestorableSession()
        }
    }

    private var resumeBanner: some View {
        HStack(spacing: 12) {
            Button {
                appState.resumeSavedGame()
            } label: {
                HStack(spacing: 12) {
                    resumeIcon
                    resumeText
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppColors.textMuted)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                HapticManager.shared.warning()
                appState.discardRestorableSession()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(AppColors.textMuted)
                    .frame(width: 42, height: 42)
                    .background(AppColors.cardElevated.opacity(0.7))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Kayıtlı oturumu sil")
        }
        .padding(16)
        .ffGlassPanelStyle(cornerRadius: 18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppColors.ruby.opacity(0.4), lineWidth: 1)
        )
    }

    private var resumeIcon: some View {
        ZStack {
            Circle()
                .fill(AppColors.ruby.opacity(0.18))
                .frame(width: 44, height: 44)
            Image(systemName: "play.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(AppColors.champagne)
        }
    }

    private var resumeText: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Kaldığın Oyuna Devam Et")
                .font(AppTypography.button)
                .foregroundColor(AppColors.textPrimary)
            if let snapshot = appState.restorableSnapshot {
                Text(resumeSummary(for: snapshot))
                    .font(AppTypography.labelSmall)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    private func resumeSummary(for snapshot: GameSessionSnapshot) -> String {
        let names = snapshot.players.map(\.name).joined(separator: ", ")
        let mode = snapshot.session.contentProfile.displayName
        let turns = snapshot.totalCompletedTurns
        return "\(mode) · \(snapshot.currentPhase.rawValue) · \(turns) tur · \(names)"
    }

    private var header: some View {
        HomeHeroPanel(
            statusText: statusText,
            canStartGame: playerVM.canStartGame,
            playerCount: playerVM.activePlayers.count,
            deckCount: appState.sessionConfig.enabledDeckTypes.count
        )
        .padding(.horizontal, 20)
    }

    private var statusText: String {
        let count = playerVM.activePlayers.count
        let decks = appState.sessionConfig.enabledDeckTypes.count
        if count >= 2 {
            return "\(count) oyuncu · \(decks) deste hazır"
        }
        return "Oynamak için en az 2 kişi ekle"
    }

    private var playerSubtitle: String {
        let count = playerVM.activePlayers.count
        if count == 0 { return "Henüz oyuncu yok" }
        return "\(count) kayıtlı oyuncu"
    }

    private var deckSubtitle: String {
        let decks = appState.sessionConfig.enabledDeckTypes.count
        let props = appState.sessionConfig.selectedPropIds.count
        return "\(decks) deste · \(props) eşya seçili"
    }

    private var historySubtitle: String {
        let count = PlayedHistoryStore.load().count
        return count == 0 ? "Henüz oturum yok" : "\(count) oturum kaydı"
    }

    private var playButton: some View {
        Button(action: startPlay) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .bold))
                }
                Text("Oyna")
                    .font(AppTypography.button)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .opacity(0.8)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity)
            .frame(height: 68)
            .background(theme.heroGradient)
            .cornerRadius(34)
            .overlay(alignment: .top) {
                Capsule()
                    .fill(Color.white.opacity(0.22))
                    .frame(height: 1.2)
                    .padding(.horizontal, 28)
                    .padding(.top, 9)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 34)
                    .stroke(AppColors.edgeLight.opacity(0.72), lineWidth: 1)
            )
            .shadow(
                color: effectBudget.allowsPremiumGlow ? theme.shadowGlow : .clear,
                radius: min(24, effectBudget.shadowRadius),
                x: 0,
                y: 12
            )
            .shadow(
                color: effectBudget.allowsPremiumGlow ? AppColors.shadowColor.opacity(0.35) : .clear,
                radius: min(8, effectBudget.shadowRadius),
                x: 0,
                y: 4
            )
        }
    }

    private var quickStartButton: some View {
        Button {
            HapticManager.shared.selection()
            appState.startNewGameWithSavedSetup(players: playerVM.activePlayers)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "bolt.fill")
                Text("Aynı Kurulumla Yeniden Başlat")
                    .font(AppTypography.labelSmall)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(AppColors.champagne)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .ffGlassPanelStyle(cornerRadius: 26)
        }
    }

    private func startPlay() {
        HapticManager.shared.success()
        appState.pendingSelectedAtmosphere = nil
        if playerVM.canStartGame {
            appState.beginPlay(with: playerVM.activePlayers)
        } else {
            appState.navigate(.playPlayers)
        }
    }

    @ViewBuilder
    private func menuSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.champagne)
                .tracking(1.5)
                .padding(.horizontal, 24)

            VStack(spacing: 10) {
                content()
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 22)
    }
}

private struct HomeHeroPanel: View {
    @Environment(\.sessionTheme) private var theme

    let statusText: String
    let canStartGame: Bool
    let playerCount: Int
    let deckCount: Int

    var body: some View {
        VStack(spacing: 18) {
            AppLogoMark(style: .withTitle, iconSize: 92, showsTagline: true)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    statusBadge
                    statChip(value: "\(playerCount)", label: "kişi")
                    statChip(value: "\(deckCount)", label: "deste")
                }

                VStack(spacing: 10) {
                    statusBadge
                    HStack(spacing: 10) {
                        statChip(value: "\(playerCount)", label: "kişi")
                        statChip(value: "\(deckCount)", label: "deste")
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 26)
        .frame(maxWidth: .infinity)
        .ffGlassCardStyle(cornerRadius: 30, glow: true)
        .overlay(alignment: .top) {
            Capsule()
                .fill(theme.heroGradient)
                .frame(height: 3)
                .padding(.horizontal, 40)
                .padding(.top, 1)
                .opacity(0.85)
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: canStartGame ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(canStartGame ? AppColors.gold : AppColors.textSecondary)

            Text(statusText)
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .padding(.horizontal, 14)
        .frame(height: 36)
        .ffGlassChipStyle(cornerRadius: 18)
    }

    private func statChip(value: String, label: String) -> some View {
        HStack(spacing: 4) {
            Text(value)
                .font(AppTypography.button)
                .foregroundColor(theme.accentSoft)
            Text(label)
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .ffGlassChipStyle(cornerRadius: 18)
    }
}

private struct HomeMenuRow: View {
    @Environment(\.sessionTheme) private var theme
    @Environment(\.visualEffectBudget) private var effectBudget

    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 46, height: 46)
                    .background(theme.heroGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.30), lineWidth: 1)
                    )
                    .shadow(
                        color: effectBudget.allowsPremiumGlow ? theme.shadowGlow : .clear,
                        radius: min(10, effectBudget.shadowRadius),
                        x: 0,
                        y: 5
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTypography.button)
                        .foregroundColor(AppColors.textPrimary)
                    Text(subtitle)
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.textMuted)
            }
            .padding(16)
            .ffGlassPanelStyle(cornerRadius: 20)
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(theme.borderAccent.opacity(0.35), lineWidth: 1)
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environmentObject(AppStateViewModel())
    .environmentObject(PlayerSetupViewModel())
}

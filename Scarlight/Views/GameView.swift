import SwiftUI
import UIKit

private enum GameLayoutSpacing {
    static let horizontalInset: CGFloat = 20
}

struct GameView: View {
    @ObservedObject var viewModel: GameEngineViewModel
    @Environment(\.scenePhase) private var scenePhase
    private var theme: SessionTheme { SessionTheme.conversation(for: activeAtmosphere) }
    @Environment(\.visualEffectBudget) private var effectBudget
    @AppStorage(PerformanceDefaults.performanceModeKey) private var isPerformanceModeEnabled = true
    @State private var showSettings = false
    @State private var showQuickAdd = false

    var onExit: () -> Void
    var onPlayAgain: () -> Void

    private var activeAtmosphere: PlayAtmosphere {
        viewModel.currentSessionConfig.contentProfile == .social ? .friends : .hot
    }

    var body: some View {
        ZStack {
            if viewModel.gameState == .gameComplete, let summary = viewModel.sessionSummary {
                GameCompleteView(
                    summary: summary,
                    onPlayAgain: onPlayAgain,
                    onHome: onExit
                )
            } else {
                activeGameContent
            }
        }
        .environment(\.sessionTheme, theme)
        .environment(\.ffPerformanceMode, isPerformanceModeEnabled)
        .visualEffectBudget(.resolved(performanceModeEnabled: isPerformanceModeEnabled))
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            viewModel.startGameIfNeeded()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            viewModel.pauseForInactivity()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { viewModel.pauseForInactivity() }
        }
        .alert("Oyun kaydedilemedi", isPresented: Binding(
            get: { viewModel.saveErrorMessage != nil },
            set: { if !$0 { viewModel.saveErrorMessage = nil } }
        )) {
            Button("Tamam", role: .cancel) { viewModel.saveErrorMessage = nil }
        } message: {
            Text(viewModel.saveErrorMessage ?? "")
        }
        .onChange(of: showSettings) { _, presented in
            if presented { viewModel.safeStop() }
        }
        .onChange(of: showQuickAdd) { _, presented in
            if presented { viewModel.safeStop() }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showQuickAdd) {
            QuickAddCardView(playerCount: viewModel.allPlayers.count, onSaved: {})
        }
    }

    private var activeGameContent: some View {
        ZStack {
            ConversationBackground()

            VStack(spacing: 0) {
                FFTopBar(
                    title: AppConstants.gameNameDisplay,
                    phaseLabel: nil,
                    onSafeStop: { viewModel.safeStop() },
                    onSettings: { showSettings = true },
                    onAddCard: viewModel.showsQuickAddButton ? { showQuickAdd = true } : nil
                )
                ScrollViewReader { proxy in
                  ScrollView {
                    VStack(spacing: 16) {
                        Color.clear.frame(height: 0).id("conversationTop")
                        Group {
                            if viewModel.gameState == .wheelSpin {
                                WheelView(viewModel: viewModel)
                            } else if viewModel.gameState == .diceRoll || viewModel.gameState == .diceWildChoice {
                                DiceView(viewModel: viewModel)
                            } else if viewModel.gameState == .penaltyChoice {
                                PenaltyChoiceView(viewModel: viewModel)
                            } else if viewModel.currentPenalty != nil {
                                PenaltyCardView(viewModel: viewModel)
                            } else {
                                GameCardView(viewModel: viewModel)
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                    .frame(maxWidth: 680)
                    .frame(maxWidth: .infinity)
                  }
                  .onChange(of: viewModel.currentCard?.id) { _, _ in
                      proxy.scrollTo("conversationTop", anchor: .top)
                  }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ActionButtons(viewModel: viewModel)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                    .frame(maxWidth: 680)
                    .frame(maxWidth: .infinity)
                    .background(theme.backgroundDeep)
            }

            if viewModel.showSafeStop {
                SafeStopOverlay(
                    onResume: {
                        viewModel.resumeGame()
                    },
                    onExit: onExit
                )
            }

            if viewModel.showPartnerConsent {
                PartnerConsentOverlay(
                    targetName: viewModel.displayTargetName ?? "",
                    onAccept: {
                        viewModel.partnerAccepted()
                    },
                    onReject: {
                        viewModel.partnerRejected()
                    }
                )
            }

            if viewModel.gameState == .roundSetup {
                SessionSetupView(
                    mode: .postHardcoreRound,
                    players: viewModel.allPlayers,
                    initialConfig: viewModel.currentSessionConfig,
                    onContinue: { config in
                        viewModel.applyRoundSetup(config)
                    }
                )
                .transition(.opacity)
                .zIndex(50)
            }
        }
    }
}

struct GameCardView: View {
    @ObservedObject var viewModel: GameEngineViewModel

    var body: some View {
        VStack(spacing: 20) {
            ConversationBubble(role: "Soran", name: viewModel.actorPlayer?.name ?? "Scarlight") {
                if viewModel.showSurpriseTask, let surprise = viewModel.currentSurprisePosition {
                    DiceSurpriseTaskBanner(
                        surprise: surprise,
                        taskText: viewModel.renderedSurpriseTaskText,
                        timerSeconds: viewModel.isSurpriseTimed ? viewModel.timerSeconds : nil,
                        isTimerRunning: viewModel.isSurpriseTimed &&
                            (viewModel.gameState == .timerRunning || viewModel.gameState == .waitingForCompletion)
                    )
                }

                if viewModel.showPartnerConsent {
                    Text("Partner onayı bekleniyor…")
                        .font(.body)
                        .foregroundColor(AppColors.textSecondary)
                } else {
                    Text(viewModel.renderedCardText)
                        .font(.system(.title3, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let item = viewModel.activeItemName {
                    Label(item, systemImage: "bag")
                        .font(.caption)
                        .foregroundColor(ConversationPalette.question)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if viewModel.gameState != .neverHaveIChoice,
                   viewModel.requiresTaskTimer, !viewModel.isSurpriseTimed {
                    if viewModel.gameState == .timerRunning || viewModel.gameState == .waitingForCompletion {
                        FFTimerDisplay(seconds: viewModel.timerSeconds,
                                       isRunning: viewModel.gameState == .timerRunning,
                                       isWarning: viewModel.timerSeconds <= 5 && viewModel.timerSeconds > 0,
                                       compact: true)
                    } else {
                        Label("\(viewModel.timerSeconds) sn", systemImage: "timer")
                            .font(.caption)
                            .foregroundColor(ConversationPalette.question)
                            .monospacedDigit()
                    }
                }
            }

            ConversationReplyPrompt(name: viewModel.displayTargetName ?? "Masa",
                                    message: viewModel.requiresTaskTimer ? "Hazır olduğunda başlat." : "Söz sende.")
        }
        .padding(.horizontal, GameLayoutSpacing.horizontalInset)
    }
}

struct DiceSurpriseTaskBanner: View {
    @Environment(\.sessionTheme) private var theme

    let surprise: SurprisePosition
    let taskText: String
    var timerSeconds: Int?
    var isTimerRunning: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            DiceSurpriseIcon(assetName: surprise.assetName, size: 36)

            VStack(alignment: .leading, spacing: 6) {
                Text("Pozisyon · \(surprise.name)")
                    .font(AppTypography.labelSmall)
                    .foregroundColor(theme.accentSoft)

                Text(taskText)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if let timerSeconds {
                    if isTimerRunning {
                        FFTimerDisplay(
                            seconds: timerSeconds,
                            isRunning: true,
                            isWarning: timerSeconds <= 5 && timerSeconds > 0,
                            compact: true
                        )
                    } else {
                        Text("Süre: \(timerSeconds) sn")
                            .font(AppTypography.caption)
                            .foregroundColor(theme.accentSoft)
                            .monospacedDigit()
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ffGlassChipStyle(cornerRadius: 16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.borderAccent, lineWidth: 1)
        )
    }
}

struct PenaltyChoiceView: View {
    @ObservedObject var viewModel: GameEngineViewModel
    @Environment(\.sessionTheme) private var theme

    var body: some View {
        VStack(spacing: 24) {
            Text("Kartı Kabul Etmiyorsun")
                .font(AppTypography.sectionTitle)
                .foregroundColor(AppColors.textPrimary)

            Text("Nasıl devam etmek istiyorsun?")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 16) {
                Button {
                    viewModel.selectPenaltyReason(isRelated: true)
                } label: {
                    VStack(spacing: 6) {
                        Text("Hafif Alternatif")
                            .font(AppTypography.button)
                        Text("Daha yumuşak bir görev veya soru")
                            .font(AppTypography.caption)
                    }
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .ffGlassPanelStyle(cornerRadius: 16)
                }

                Button {
                    viewModel.selectPenaltyReason(isRelated: false)
                } label: {
                    VStack(spacing: 6) {
                        Text("Ceza Çek")
                            .font(AppTypography.button)
                        Text("Rastgele red cezası — her seferinde farklı")
                            .font(AppTypography.caption)
                    }
                    .foregroundColor(theme.accentBright)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .ffGlassCardStyle(cornerRadius: 16, glow: true)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

struct PenaltyCardView: View {
    @ObservedObject var viewModel: GameEngineViewModel

    var body: some View {
        VStack(spacing: 20) {
            ConversationBubble(role: "Soran", name: viewModel.actorPlayer?.name ?? "Scarlight") {
                Text("Alternatif tur")
                    .font(.caption)
                    .foregroundColor(ConversationPalette.question)
                Text(viewModel.renderedPenaltyText)
                    .font(.system(.title3, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                if viewModel.gameState == .timerRunning || viewModel.gameState == .waitingForCompletion {
                    FFTimerDisplay(seconds: viewModel.timerSeconds,
                                   isRunning: viewModel.gameState == .timerRunning,
                                   isWarning: viewModel.timerSeconds <= 5 && viewModel.timerSeconds > 0,
                                   compact: true)
                } else {
                    Label("\(viewModel.timerSeconds) sn", systemImage: "timer")
                        .font(.caption)
                        .foregroundColor(ConversationPalette.question)
                }
            }
            ConversationReplyPrompt(name: viewModel.displayTargetName ?? "Masa", message: "Hazır olduğunda başlat.")
        }
        .padding(.horizontal, GameLayoutSpacing.horizontalInset)
    }
}

struct ActionButtons: View {
    @ObservedObject var viewModel: GameEngineViewModel
    @Environment(\.sessionTheme) private var theme

    private var canUseJoker: Bool {
        guard let actor = viewModel.actorPlayer else { return false }
        return actor.jokersRemaining > 0 && viewModel.currentPenalty == nil
    }

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.gameState == .neverHaveIChoice {
                VStack(spacing: 16) {
                    FFSecondaryButton(title: "Yapmadım") {
                        viewModel.answerNeverHaveINo()
                    }
                    FFPrimaryButton(title: "Yaptım — Görevi Yap") {
                        viewModel.answerNeverHaveIYes()
                    }
                }
            } else if viewModel.gameState == .partnerConsent {
                EmptyView()
            } else if viewModel.gameState == .cardDisplay {
                if viewModel.requiresTaskTimer {
                    FFPrimaryButton(title: "Başlat") {
                        viewModel.startTimer()
                    }
                } else {
                    FFPrimaryButton(title: "Tamamladım") {
                        viewModel.completeCard()
                    }
                }
            } else if viewModel.gameState == .penaltyDisplay {
                FFPrimaryButton(title: "Ceza Süresini Başlat") {
                    viewModel.startTimer()
                }
            } else if viewModel.gameState == .timerRunning || viewModel.gameState == .waitingForCompletion {
                if viewModel.gameState == .timerRunning && viewModel.canUseTimeBonus {
                    Button(action: { viewModel.addTimeBonus() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.badge.plus")
                            Text("+30 saniye")
                        }
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.vertical, 8)
                    }
                }

                HStack(spacing: 16) {
                    if canUseJoker {
                        Button(action: { viewModel.useJoker() }) {
                            VStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 20))
                                Text("Joker")
                                    .font(AppTypography.labelSmall)
                            }
                            .foregroundColor(theme.accentSoft)
                            .frame(width: 70, height: 60)
                            .background(theme.cardDark)
                            .cornerRadius(16)
                        }
                    }

                    VStack(spacing: 12) {
                        HStack(spacing: 16) {
                            FFDangerButton(title: "Pas") {
                                if viewModel.currentPenalty != nil {
                                    viewModel.rejectPenalty()
                                } else {
                                    if viewModel.currentPhase == .wheel && viewModel.wheelState != nil {
                                        viewModel.passWheelCard()
                                    } else if viewModel.currentPhase == .dice && viewModel.diceState != nil {
                                        viewModel.passDiceCard()
                                    } else {
                                        viewModel.passCard()
                                    }
                                }
                            }

                            FFPrimaryButton(title: "Tamamladım") {
                                if viewModel.currentPenalty != nil {
                                    viewModel.completePenalty()
                                } else {
                                    if viewModel.currentPhase == .wheel && viewModel.wheelState != nil {
                                        viewModel.completeWheelCard()
                                    } else if viewModel.currentPhase == .dice && viewModel.diceState != nil {
                                        viewModel.completeDiceCard()
                                    } else {
                                        viewModel.completeCard()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct SafeStopOverlay: View {
    var onResume: () -> Void
    var onExit: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Oyun Durdu")
                    .font(AppTypography.sectionTitle)
                    .foregroundColor(AppColors.textPrimary)

                VStack(spacing: 12) {
                    FFPrimaryButton(title: "Devam Et", action: onResume)
                    FFDangerButton(title: "Ana Menü", action: onExit)
                }
            }
            .padding(32)
            .ffGlassPanelStyle(cornerRadius: 28, glow: true)
            .padding(.horizontal, 40)
        }
    }
}

struct PartnerConsentOverlay: View {
    let targetName: String
    var onAccept: () -> Void
    var onReject: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Partner Onayı")
                    .font(AppTypography.sectionTitle)
                    .foregroundColor(AppColors.textPrimary)

                Text("\(targetName), bu görevi kabul ediyor musun?")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    FFDangerButton(title: "Hayır", action: onReject)
                    FFPrimaryButton(title: "Evet", action: onAccept)
                }
            }
            .padding(32)
            .ffGlassPanelStyle(cornerRadius: 28, glow: true)
            .padding(.horizontal, 40)
        }
    }
}

#Preview {
    let players = [
        Player(name: "Efe", gender: .male, role: .dominant, colorHex: "#E02B3F"),
        Player(name: "Su", gender: .female, role: .receptive, colorHex: "#F2A6B3")
    ]
    GameView(viewModel: GameEngineViewModel(players: players), onExit: {}, onPlayAgain: {})
}

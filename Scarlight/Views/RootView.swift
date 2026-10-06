import SwiftUI

/// Uygulama kökü: ortam seçimi + NavigationStack + oyun katmanları.
struct RootView: View {
    @EnvironmentObject private var appState: AppStateViewModel
    @EnvironmentObject private var playerVM: PlayerSetupViewModel
    @AppStorage(PerformanceDefaults.performanceModeKey) private var isPerformanceModeEnabled = true

    var body: some View {
        NavigationStack(path: $appState.path) {
            PlayAtmosphereSelectionView(
                players: playerVM.activePlayers,
                onOpenMenu: { appState.navigate(.menu) },
                onSelect: { atmosphere in
                    appState.pendingPlayers = playerVM.activePlayers
                    appState.selectAtmosphere(atmosphere)
                }
            )
            .neutralAppTheme()
            .navigationDestination(for: AppRoute.self) { route in
                destination(for: route)
                    .navigationBarBackButtonHidden(true)
            }
        }
        .fullScreenCover(isPresented: $appState.showConsent) {
            ConsentView {
                appState.acceptConsent()
            }
        }
        .fullScreenCover(isPresented: $appState.showOnboarding) {
            OnboardingView {
                appState.completeOnboarding()
            }
        }
        .fullScreenCover(isPresented: $appState.showGame) {
            if let viewModel = appState.gameViewModel {
                GameView(
                    viewModel: viewModel,
                    onExit: {
                        appState.endGame()
                    },
                    onPlayAgain: {
                        appState.replayGame()
                    }
                )
                .id(viewModel.sessionId)
            }
        }
        .fullScreenCover(isPresented: $appState.showLighterGame) {
            if let viewModel = appState.lighterGameViewModel {
                LighterGameView(viewModel: viewModel) {
                    appState.endLighterGame()
                }
                .id(viewModel.sessionId)
            }
        }
        .onAppear {
            playerVM.loadPlayers()
        }
        .environment(\.ffPerformanceMode, isPerformanceModeEnabled)
        .visualEffectBudget(.resolved(performanceModeEnabled: isPerformanceModeEnabled))
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .menu:
            HomeView(onBack: { appState.pop() })
                .neutralAppTheme()

        case .players:
            PlayerSetupView(
                mode: .manage,
                onBack: { appState.pop() }
            )
            .neutralAppTheme()

        case .decksAndProps:
            SessionSetupView(
                mode: .manage,
                players: placeholderPlayers,
                initialConfig: appState.sessionConfig,
                onBack: { appState.pop() },
                onContinue: { config in
                    appState.saveSessionConfig(config)
                    appState.pop()
                }
            )
            .neutralAppTheme()

        case .cards:
            CardEditorView(onBack: { appState.pop() })
                .neutralAppTheme()

        case .settings:
            SettingsView(onBack: { appState.pop() })
                .neutralAppTheme()

        case .history:
            GameHistoryView(onBack: { appState.pop() })
                .neutralAppTheme()

        case .customProps:
            CustomPropsView(onBack: { appState.pop() })
                .neutralAppTheme()

        case .playPlayers:
            PlayerSetupView(
                mode: .playFlow,
                onBack: { appState.pop() },
                onContinue: { players in
                    appState.completePlayPlayerSetup(with: players)
                }
            )
            .neutralAppTheme()

        case .playAtmosphere:
            PlayAtmosphereSelectionView(
                players: appState.pendingPlayers,
                onBack: { appState.pop() },
                onSelect: { atmosphere in
                    appState.selectAtmosphere(atmosphere)
                }
            )
            .neutralAppTheme()

        case .playSetup(let atmosphere):
            SessionSetupView(
                mode: .preGame,
                players: appState.pendingPlayers,
                atmosphere: atmosphere,
                initialConfig: atmosphere.preparedConfig(),
                onBack: { appState.pop() },
                onContinue: { config in
                    appState.launchGame(config: config)
                }
            )
            .sessionTheme(for: atmosphere)
        }
    }

    private var placeholderPlayers: [Player] {
        let active = playerVM.activePlayers
        if active.isEmpty {
            return [Player(name: "Oyuncu 1", gender: .female, role: .mixed, colorHex: "#E02B3F")]
        }
        return active
    }
}

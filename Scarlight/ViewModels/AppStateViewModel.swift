import Foundation
import SwiftUI
import Combine

private enum AppFlowTiming {
    static let navigation: TimeInterval = 0.18
    static let shortTransition: TimeInterval = 0.22
    static let setupStep: TimeInterval = 0.25
    static let launch: TimeInterval = 0.35
}

class AppStateViewModel: ObservableObject {
    @Published var path = NavigationPath()
    @Published var showConsent = false
    @Published var showGame = false
    @Published var showOnboarding = false
    @Published var gameViewModel: GameEngineViewModel?
    @Published var pendingPlayers: [Player] = []
    @Published var pendingSelectedAtmosphere: PlayAtmosphere?
    @Published var sessionConfig: GameSessionConfig = SessionConfigStore.load()
    @Published private(set) var restorableSnapshot: GameSessionSnapshot?
    @Published var showLighterGame = false
    @Published var lighterGameViewModel: LighterGameViewModel?

    private(set) var hasConsented: Bool = false
    private let consentKey = "hasConsented"
    private var isFlowLocked = false

    init() {
        hasConsented = UserDefaults.standard.bool(forKey: consentKey)
        showConsent = !hasConsented
        refreshRestorableSession()
    }

    func refreshRestorableSession() {
        restorableSnapshot = GameSessionRestoreStore.loadValidated()
    }

    func acceptConsent() {
        hasConsented = true
        UserDefaults.standard.set(true, forKey: consentKey)
        showConsent = false
        if !OnboardingStore.hasCompleted {
            showOnboarding = true
        }
    }

    func completeOnboarding() {
        OnboardingStore.markCompleted()
        showOnboarding = false
    }

    func resetConsent() {
        hasConsented = false
        UserDefaults.standard.set(false, forKey: consentKey)
        showConsent = true
        popToRoot()
        endGame()
    }

    func navigate(_ route: AppRoute) {
        guard TapThrottle.tryFire(key: "appState.navigate", cooldown: AppFlowTiming.navigation) else { return }
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        guard TapThrottle.tryFire(key: "appState.pop", cooldown: AppFlowTiming.navigation) else { return }
        path.removeLast()
    }

    func popToRoot() {
        guard TapThrottle.tryFire(key: "appState.popToRoot", cooldown: AppFlowTiming.navigation) else { return }
        path = NavigationPath()
    }

    func saveSessionConfig(_ config: GameSessionConfig) {
        sessionConfig = config
        SessionConfigStore.save(config)
    }

    func reloadSessionConfigFromStore() {
        sessionConfig = SessionConfigStore.load()
        refreshRestorableSession()
    }

    func beginPlay(with players: [Player]) {
        pendingPlayers = players
        pendingSelectedAtmosphere = nil
        popToRoot()
    }

    func quickStart(with players: [Player]) {
        pendingPlayers = players
        pendingSelectedAtmosphere = nil
        popToRoot()
    }

    func startNewGameWithSavedSetup(players: [Player]) {
        guard acquireFlowLock(key: "savedSetup", cooldown: AppFlowTiming.launch) else { return }
        guard players.count >= 2, !showGame else {
            releaseFlowLock()
            return
        }

        let normalizedPlayers = players.map { player in
            Player(
                id: player.id,
                name: player.name,
                gender: player.gender,
                role: player.role,
                colorHex: player.colorHex,
                isActive: true,
                jokersRemaining: 3
            )
        }
        pendingPlayers = normalizedPlayers
        pendingSelectedAtmosphere = nil
        GameSessionRestoreStore.clear()
        refreshRestorableSession()
        gameViewModel = GameEngineViewModel(players: normalizedPlayers, session: sessionConfig)
        showGame = true
        path = NavigationPath()
        scheduleFlowUnlock(after: AppFlowTiming.launch)
    }

    func replayHistoryRecord(_ record: PlayedSessionRecord) {
        guard acquireFlowLock(key: "historyReplay", cooldown: AppFlowTiming.launch) else { return }
        guard let config = record.replayConfig, record.replayPlayers.count >= 2, !showGame else {
            releaseFlowLock()
            return
        }

        let normalizedPlayers = record.replayPlayers.map { player in
            Player(
                id: player.id,
                name: player.name,
                gender: player.gender,
                role: player.role,
                colorHex: player.colorHex,
                isActive: true,
                jokersRemaining: 3
            )
        }
        pendingPlayers = normalizedPlayers
        pendingSelectedAtmosphere = nil
        GameSessionRestoreStore.clear()
        refreshRestorableSession()
        saveSessionConfig(config)
        gameViewModel = GameEngineViewModel(players: normalizedPlayers, session: config)
        showGame = true
        path = NavigationPath()
        scheduleFlowUnlock(after: AppFlowTiming.launch)
    }

    func completePlayPlayerSetup(with players: [Player]) {
        guard acquireFlowLock(key: "playPlayerSetup", cooldown: AppFlowTiming.setupStep) else { return }
        pendingPlayers = players
        if !path.isEmpty {
            path.removeLast()
        }
        proceedWithSelectedAtmosphere(ownsLock: true)
    }

    func selectAtmosphere(_ atmosphere: PlayAtmosphere) {
        guard acquireFlowLock(key: "selectAtmosphere", cooldown: AppFlowTiming.setupStep) else { return }
        pendingSelectedAtmosphere = atmosphere
        proceedWithSelectedAtmosphere(ownsLock: true)
    }

    func proceedWithSelectedAtmosphere(ownsLock: Bool = false) {
        if !ownsLock {
            guard acquireFlowLock(key: "proceedAtmosphere", cooldown: AppFlowTiming.setupStep) else { return }
        }

        guard let atmosphere = pendingSelectedAtmosphere else {
            if ownsLock { scheduleFlowUnlock(after: AppFlowTiming.setupStep) }
            return
        }

        guard pendingPlayers.count >= 2 else {
            path.append(AppRoute.playPlayers)
            scheduleFlowUnlock(after: AppFlowTiming.setupStep)
            return
        }

        if atmosphere.isLighterGame {
            launchLighterGame(ownsLock: true)
            return
        }

        path.append(AppRoute.playSetup(atmosphere))
        scheduleFlowUnlock(after: AppFlowTiming.setupStep)
    }

    func launchLighterGame(ownsLock: Bool = false) {
        if !ownsLock {
            guard acquireFlowLock(key: "launchLighter", cooldown: AppFlowTiming.launch) else { return }
        }
        guard !showLighterGame, pendingPlayers.count >= 2 else {
            if ownsLock { scheduleFlowUnlock(after: AppFlowTiming.launch) }
            return
        }
        lighterGameViewModel = LighterGameViewModel(players: pendingPlayers)
        showLighterGame = true
        path = NavigationPath()
        scheduleFlowUnlock(after: AppFlowTiming.launch)
    }

    func endLighterGame() {
        guard acquireFlowLock(key: "endLighter", cooldown: AppFlowTiming.shortTransition) else { return }
        showLighterGame = false
        lighterGameViewModel = nil
        pendingSelectedAtmosphere = nil
        scheduleFlowUnlock(after: AppFlowTiming.shortTransition)
    }

    func resumeSavedGame() {
        guard acquireFlowLock(key: "resumeGame", cooldown: AppFlowTiming.launch) else { return }
        guard !showGame, let snapshot = GameSessionRestoreStore.loadValidated() else {
            refreshRestorableSession()
            releaseFlowLock()
            return
        }
        gameViewModel = GameEngineViewModel(restoring: snapshot)
        showGame = true
        path = NavigationPath()
        scheduleFlowUnlock(after: AppFlowTiming.launch)
    }

    func discardRestorableSession() {
        GameSessionRestoreStore.clear()
        refreshRestorableSession()
    }

    func launchGame(config: GameSessionConfig) {
        guard acquireFlowLock(key: "launchGame", cooldown: AppFlowTiming.launch) else { return }
        guard !showGame, pendingPlayers.count >= 2 else {
            releaseFlowLock()
            return
        }
        GameSessionRestoreStore.clear()
        refreshRestorableSession()
        var merged = config
        if merged.partnerPlayerIds.isEmpty {
            merged.partnerPlayerIds = PartnerPairingStore.load()
        }
        saveSessionConfig(merged)
        gameViewModel = GameEngineViewModel(players: pendingPlayers, session: merged)
        showGame = true
        path = NavigationPath()
        scheduleFlowUnlock(after: AppFlowTiming.launch)
    }

    func replayGame() {
        guard acquireFlowLock(key: "replayGame", cooldown: AppFlowTiming.launch) else { return }
        guard let previous = gameViewModel else {
            releaseFlowLock()
            return
        }
        let players = previous.allPlayers
        var config = previous.currentSessionConfig
        if config.partnerPlayerIds.isEmpty {
            config.partnerPlayerIds = PartnerPairingStore.load()
        }
        GameSessionRestoreStore.clear()
        refreshRestorableSession()
        gameViewModel = GameEngineViewModel(players: players, session: config)
        showGame = true
        scheduleFlowUnlock(after: AppFlowTiming.launch)
    }

    func endGame() {
        guard acquireFlowLock(key: "endGame", cooldown: AppFlowTiming.shortTransition) else { return }
        gameViewModel?.discardSavedSession()
        showGame = false
        gameViewModel = nil
        refreshRestorableSession()
        scheduleFlowUnlock(after: AppFlowTiming.shortTransition)
    }

    @discardableResult
    private func acquireFlowLock(key: String, cooldown: TimeInterval = AppFlowTiming.setupStep) -> Bool {
        guard !isFlowLocked else { return false }
        guard TapThrottle.tryFire(key: "appState.\(key)", cooldown: cooldown) else { return false }
        isFlowLocked = true
        return true
    }

    private func scheduleFlowUnlock(after seconds: TimeInterval = AppFlowTiming.setupStep) {
        let delay = UInt64(seconds * 1_000_000_000)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: delay)
            isFlowLocked = false
        }
    }

    private func releaseFlowLock() {
        isFlowLocked = false
    }
}

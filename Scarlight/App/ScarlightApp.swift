import SwiftUI

@main
struct ScarlightApp: App {
    @StateObject private var appState = AppStateViewModel()
    @StateObject private var playerVM = PlayerSetupViewModel()

    init() {
        PerformanceDefaults.registerAndApplyMVPDefaults()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(playerVM)
                .preferredColorScheme(.dark)
                .onChange(of: appState.path.count) { _, _ in
                    playerVM.loadPlayers()
                }
        }
    }
}

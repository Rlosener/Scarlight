import SwiftUI

struct PropSelectionView: View {
    let players: [Player]
    let initialConfig: GameSessionConfig
    var onBack: (() -> Void)? = nil
    var onContinue: (GameSessionConfig) -> Void

    var body: some View {
        SessionSetupView(
            mode: .preGame,
            players: players,
            initialConfig: initialConfig,
            onBack: onBack,
            onContinue: onContinue
        )
    }
}

#Preview {
    PropSelectionView(
        players: [
            Player(name: "Efe", gender: .male, role: .dominant, colorHex: "#E02B3F"),
            Player(name: "Su", gender: .female, role: .receptive, colorHex: "#F2A6B3")
        ],
        initialConfig: .default,
        onContinue: { _ in }
    )
}

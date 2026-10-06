import SwiftUI

struct WheelView: View {
    @ObservedObject var viewModel: GameEngineViewModel
    @Environment(\.sessionTheme) private var theme
    @Environment(\.visualEffectBudget) private var effectBudget
    @State private var rotation: Double = 0
    @State private var isSpinning: Bool = false
    @State private var selectedPlayer: Player?
    @State private var spinTask: Task<Void, Never>?

    private var players: [Player] {
        viewModel.allPlayers
    }

    private var segmentPlayers: [Player] {
        guard players.count >= 2 else { return players }
        return players
    }

    private var segmentCount: Int {
        segmentPlayers.count
    }

    var body: some View {
        VStack(spacing: 36) {
            Text("ÇARK")
                .font(AppTypography.sectionTitle)
                .foregroundColor(AppColors.textPrimary)
                .tracking(2)

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [theme.cardElevated, theme.cardDark, theme.backgroundWine],
                            center: .center,
                            startRadius: 50,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)
                    .overlay(
                        Circle()
                            .stroke(AppColors.borderSoft, lineWidth: 2)
                    )
                    .shadow(
                        color: effectBudget.allowsPremiumGlow ? theme.glow.opacity(0.3) : .clear,
                        radius: min(20, effectBudget.shadowRadius),
                        x: 0,
                        y: 8
                    )

                WheelSegments(players: segmentPlayers)
                    .rotationEffect(.degrees(rotation))

                Circle()
                    .fill(AppColors.glassDeep)
                    .overlay {
                        Circle()
                            .fill(theme.glassCardGradient)
                    }
                    .overlay {
                        Circle()
                            .strokeBorder(theme.borderAccent, lineWidth: 2)
                    }
                    .frame(width: 80, height: 80)
                    .shadow(
                        color: effectBudget.allowsPremiumGlow ? theme.shadowGlow : .clear,
                        radius: min(8, effectBudget.shadowRadius),
                        x: 0,
                        y: 4
                    )

                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 32))
                    .foregroundColor(theme.accent)
                    .offset(y: -150)
                    .shadow(
                        color: effectBudget.allowsPremiumGlow ? theme.glow : .clear,
                        radius: min(10, effectBudget.shadowRadius),
                        x: 0,
                        y: 0
                    )
            }

            Group {
                if let selected = selectedPlayer {
                    VStack(spacing: 20) {
                        Text("Seçilen:")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)

                        Text(selected.name)
                            .font(AppTypography.playerName)
                            .foregroundColor(theme.accent)

                        FFPrimaryButton(title: "Kartı Aç") {
                            HapticManager.shared.success()
                            viewModel.wheelPlayerSelected(selected)
                            selectedPlayer = nil
                        }
                    }
                    .padding(.horizontal, 20)
                    .transition(.opacity.combined(with: .scale))
                } else if !isSpinning {
                    FFPrimaryButton(title: "Çarkı Çevir") {
                        spinWheel()
                    }
                    .padding(.horizontal, 20)
                    .transition(.opacity)
                } else {
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(theme.accent)
                            .scaleEffect(1.5)

                        Text("Çark dönüyor...")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: selectedPlayer?.id)
            .animation(.easeInOut(duration: 0.25), value: isSpinning)


        }
        .onChange(of: viewModel.gameState) { _, newState in
            if newState == .wheelSpin {
                spinTask?.cancel()
                isSpinning = false
                selectedPlayer = nil
            }
        }
        .onDisappear {
            spinTask?.cancel()
        }
    }

    private func spinWheel() {
        guard let player = viewModel.spinWheel() else { return }

        spinTask?.cancel()
        isSpinning = true
        selectedPlayer = nil
        FeedbackManager.wheelSpinStart()

        let targetIndex = segmentPlayers.firstIndex(where: { $0.id == player.id }) ?? 0
        let segmentAngle = 360.0 / Double(segmentCount)
        let segmentCenter = Double(targetIndex) * segmentAngle - 90.0
        let pointerAngle = -90.0

        let edgeMargin = max(5.0, segmentAngle * 0.14)
        let maxOffset = max(0, segmentAngle / 2 - edgeMargin)
        let landingOffset = maxOffset > 0 ? Double.random(in: -maxOffset...maxOffset) : 0
        let landingAngle = segmentCenter + landingOffset

        // Tam tur sayısı — mod 360 kaymasın diye kesin kat
        let fullRotations = Double(Int.random(in: 4...7))
        let fullSpins = fullRotations * 360.0
        let spinDuration = Double.random(in: 3.6...4.8)

        let currentNormalized = positiveRemainder(rotation, modulo: 360)
        let targetNormalized = positiveRemainder(pointerAngle - landingAngle, modulo: 360)
        var delta = targetNormalized - currentNormalized
        if delta <= 0 { delta += 360 }

        let finalRotation = rotation + fullSpins + delta

        withAnimation(.timingCurve(0.08, 0.82, 0.18, 1.0, duration: spinDuration)) {
            rotation = finalRotation
        }

        spinTask = Task { @MainActor in
            guard await sleep(seconds: spinDuration) else { return }

            FeedbackManager.wheelSpinEnd()

            // Görsel açıyı koruyarak state'i küçült (sonraki dönüşler için)
            let visualAngle = positiveRemainder(finalRotation, modulo: 360)
            var resetTransaction = Transaction()
            resetTransaction.disablesAnimations = true
            withTransaction(resetTransaction) {
                rotation = visualAngle
            }

            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                isSpinning = false
                selectedPlayer = player
            }
        }
    }

    private func positiveRemainder(_ value: Double, modulo: Double) -> Double {
        let remainder = value.truncatingRemainder(dividingBy: modulo)
        return remainder < 0 ? remainder + modulo : remainder
    }

    private func sleep(seconds: Double) async -> Bool {
        do {
            try await Task.sleep(nanoseconds: UInt64((seconds * 1_000_000_000).rounded()))
            return !Task.isCancelled
        } catch {
            return false
        }
    }
}

struct WheelSegments: View {
    @Environment(\.sessionTheme) private var theme

    let players: [Player]

    private var segmentAngle: Double {
        360.0 / Double(players.count)
    }

    var body: some View {
        ZStack {
            ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                let startAngle = Double(index) * segmentAngle - 90 - segmentAngle / 2
                WheelSlice(
                    startAngle: startAngle,
                    segmentAngle: segmentAngle,
                    fillColor: index % 2 == 0 ? player.color.opacity(0.35) : theme.cardDark.opacity(0.9)
                )
            }

            ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                let midAngle = Double(index) * segmentAngle - 90
                WheelSegmentLabel(
                    name: player.name,
                    midAngle: midAngle,
                    segmentAngle: segmentAngle
                )
            }
        }
        .frame(width: 240, height: 240)
    }
}

struct WheelSlice: View {
    let startAngle: Double
    let segmentAngle: Double
    let fillColor: Color

    var body: some View {
        Path { path in
            let center = CGPoint(x: 120, y: 120)
            let radius: CGFloat = 120

            path.move(to: center)
            path.addArc(
                center: center,
                radius: radius,
                startAngle: .degrees(startAngle),
                endAngle: .degrees(startAngle + segmentAngle),
                clockwise: false
            )
            path.closeSubpath()
        }
        .fill(fillColor)
        .overlay(
            Path { path in
                let center = CGPoint(x: 120, y: 120)
                let radius: CGFloat = 120

                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(startAngle),
                    endAngle: .degrees(startAngle + segmentAngle),
                    clockwise: false
                )
                path.closeSubpath()
            }
            .stroke(AppColors.borderSoft, lineWidth: 1)
        )
    }
}

struct WheelSegmentLabel: View {
    let name: String
    let midAngle: Double
    let segmentAngle: Double

    private let wheelCenter: CGFloat = 120
    private let labelRadius: CGFloat = 76

    private var normalizedMid: Double {
        var angle = midAngle.truncatingRemainder(dividingBy: 360)
        if angle < 0 { angle += 360 }
        return angle
    }

    /// Dışarıdan okunur; alt yarıda ters dönmez
    private var textRotation: Double {
        let angle = normalizedMid
        if angle > 90 && angle < 270 {
            return angle - 90
        }
        return angle + 90
    }

    private var maxLabelWidth: CGFloat {
        let arcLength = segmentAngle * .pi / 180 * labelRadius
        return max(40, min(arcLength * 0.9, 96))
    }

    private var fontSize: CGFloat {
        if segmentAngle < 36 { return 9 }
        if segmentAngle < 55 { return 10 }
        if segmentAngle < 90 { return 11 }
        return 13
    }

    var body: some View {
        let radians = midAngle * .pi / 180
        let x = wheelCenter + CGFloat(cos(radians)) * labelRadius
        let y = wheelCenter + CGFloat(sin(radians)) * labelRadius

        Text(name)
            .font(.system(size: fontSize, weight: .semibold, design: .rounded))
            .foregroundColor(AppColors.textPrimary)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.55)
            .frame(width: maxLabelWidth)
            .fixedSize(horizontal: false, vertical: true)
            .rotationEffect(.degrees(textRotation))
            .position(x: x, y: y)
    }
}

#Preview {
    let players = [
        Player(name: "Efe", gender: .male, role: .dominant, colorHex: "#E02B3F"),
        Player(name: "Su", gender: .female, role: .receptive, colorHex: "#F2A6B3")
    ]
    WheelView(viewModel: GameEngineViewModel(players: players))
}

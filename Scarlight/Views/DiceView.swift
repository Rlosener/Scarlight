import SwiftUI

private enum DiceFlowStep {
    case idle
    case rolling
    case fateReveal
    case positionReveal
    case wildChoice
}

struct DiceView: View {
    @ObservedObject var viewModel: GameEngineViewModel
    @Environment(\.sessionTheme) private var theme
    @State private var fateValue: Int?
    @State private var flowStep: DiceFlowStep = .idle
    @State private var revealedCategory: FateCategory?
    @State private var rollingIconName: String = SurprisePositionCatalog.all.first?.assetName ?? "dice_oral"
    @State private var revealedPosition: SurprisePosition?
    @State private var rollTask: Task<Void, Never>?

    private var isFateTurn: Bool { viewModel.isDiceFateTurn }
    private var isPositionTurn: Bool { viewModel.isDicePositionTurn }

    var body: some View {
        VStack(spacing: 24) {
            turnBadge
            header

            if let roller = viewModel.diceRoller {
                Text(rollerLine(for: roller.name))
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            switch flowStep {
            case .wildChoice:
                wildCategoryPicker
            case .fateReveal:
                fateRevealPanel
            case .positionReveal:
                positionRevealPanel
            default:
                diceStage
            }

            footerHintView
        }
        .animation(.easeInOut(duration: 0.28), value: flowStep)
        .onAppear { resetForNewTurn() }
        .onDisappear { rollTask?.cancel() }
        .onChange(of: viewModel.diceRollToken) { _, _ in resetForNewTurn() }
        .onChange(of: viewModel.gameState) { _, newState in
            if newState == .diceWildChoice {
                flowStep = .wildChoice
            }
        }
    }

    private var turnBadge: some View {
        Text(isFateTurn ? "KADER TURU" : "POZİSYON TURU")
            .font(AppTypography.labelSmall)
            .foregroundColor(isFateTurn ? .white : theme.accentSoft)
            .tracking(1.5)
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
            .background {
                if isFateTurn {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(AppColors.heroGradient)
                } else {
                    FFGlassBackground(cornerRadius: 20, style: .chip, glow: true)
                }
            }
    }

    private func rollerLine(for name: String) -> String {
        if isFateTurn {
            return "\(name) kader zarı atıyor"
        }
        return "\(name) pozisyon zarı atıyor"
    }

    private var header: some View {
        HStack(spacing: 20) {
            diceTitleBlock(
                label: "KADER ZARI",
                color: isFateTurn ? AppColors.champagne : AppColors.textMuted
            )
            diceTitleBlock(
                label: "POZİSYON ZARI",
                color: isPositionTurn ? theme.accentSoft : AppColors.textMuted
            )
        }
    }

    private func diceTitleBlock(label: String, color: Color) -> some View {
        Text(label)
            .font(AppTypography.labelSmall)
            .foregroundColor(color)
            .tracking(1.5)
            .frame(maxWidth: .infinity)
    }

    private var footerHint: String {
        if isFateTurn {
            switch flowStep {
            case .idle: return "Bu turda kader zarı — kategori belirler."
            case .rolling: return "Kader belirleniyor…"
            case .fateReveal, .wildChoice: return "Kategori seçildi — kartı aç."
            default: return ""
            }
        } else {
            switch flowStep {
            case .idle: return "Bu turda pozisyon zarı — görev ekler."
            case .rolling: return "Pozisyon seçiliyor…"
            case .positionReveal: return "Görevi başlat, süre bitince tamamla."
            default: return ""
            }
        }
    }

    private var footerHintView: some View {
        Text(footerHint)
            .font(AppTypography.caption)
            .foregroundColor(AppColors.textSecondary.opacity(0.7))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
    }

    // MARK: - Zar alanı

    private var diceStage: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                fateDiceCube
                    .opacity(isFateTurn ? 1 : 0.4)
                    .scaleEffect(isFateTurn ? 1.05 : 0.9)
                positionDiceCube
                    .opacity(isPositionTurn ? 1 : 0.4)
                    .scaleEffect(isPositionTurn ? 1.05 : 0.9)
            }
            .padding(.horizontal, 20)
            .animation(.easeInOut(duration: 0.25), value: isFateTurn)

            if flowStep == .idle {
                FFPrimaryButton(title: rollButtonTitle) {
                    if isFateTurn {
                        rollFateDice()
                    } else {
                        rollPositionDice()
                    }
                }
                .padding(.horizontal, 20)
            } else if flowStep == .rolling {
                VStack(spacing: 8) {
                    ProgressView()
                        .tint(isFateTurn ? theme.accent : theme.accentSoft)
                        .scaleEffect(1.5)
                    Text(isFateTurn ? "Kader belirleniyor..." : "Pozisyon seçiliyor...")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }

    private var rollButtonTitle: String {
        isFateTurn ? "Kader Zarını At" : "Pozisyon Zarını At"
    }

    private var fateRevealPanel: some View {
        VStack(spacing: 20) {
            if let category = revealedCategory {
                VStack(spacing: 8) {
                    Image(systemName: category.icon)
                        .font(.system(size: 40))
                        .foregroundColor(Color(hex: category.color))
                    Text(category.displayName)
                        .font(AppTypography.playerName)
                        .foregroundColor(Color(hex: category.color))
                }
            }

            FFPrimaryButton(title: "Kartı Aç") {
                openFateCard()
            }
            .padding(.horizontal, 20)
        }
    }

    private var positionRevealPanel: some View {
        VStack(spacing: 20) {
            if let position = revealedPosition {
                VStack(spacing: 8) {
                    DiceSurpriseIcon(assetName: position.assetName, size: 52)
                    Text("Pozisyon · \(position.name)")
                        .font(AppTypography.button)
                        .foregroundColor(AppColors.mutedRed)
                    Text(viewModel.renderedSurpriseTaskText)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                    Text("\(position.durationSeconds) sn")
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.textSecondary)
                        .monospacedDigit()
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .ffGlassCardStyle(cornerRadius: 16, glow: false)
            }

            FFPrimaryButton(title: "Görevi Başlat") {
                viewModel.openPositionTurn()
            }
            .padding(.horizontal, 20)
        }
    }

    private var fateDiceCube: some View {
        ZStack {
            FFGlassBackground(cornerRadius: 20, style: .card, glow: isFateTurn)
                .frame(width: 96, height: 96)

            if flowStep == .rolling, isFateTurn {
                Text("\(fateValue ?? 1)")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundColor(theme.accentBright)
            } else if fateValue == 6 {
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: FateCategory.wild.color))
            } else if let value = fateValue {
                Text("\(value)")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
            } else {
                Image(systemName: "die.face.5.fill")
                    .font(.system(size: 36))
                    .foregroundColor(AppColors.textMuted)
            }
        }
        .rotation3DEffect(.degrees(flowStep == .rolling && isFateTurn ? 360 : 0), axis: (x: 1, y: 1, z: 0))
        .frame(maxWidth: .infinity)
    }

    private var positionDiceCube: some View {
        ZStack {
            FFGlassBackground(cornerRadius: 20, style: .chip, glow: isPositionTurn)
                .frame(width: 96, height: 96)

            if flowStep == .rolling, isPositionTurn {
                DiceSurpriseIcon(assetName: rollingIconName, size: 52)
            } else if let position = revealedPosition {
                DiceSurpriseIcon(assetName: position.assetName, size: 52)
            } else {
                Image(systemName: "questionmark")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(theme.accentSoft.opacity(0.8))
            }
        }
        .rotation3DEffect(.degrees(flowStep == .rolling && isPositionTurn ? 360 : 0), axis: (x: 0, y: 1, z: 0))
        .frame(maxWidth: .infinity)
    }

    private var wildCategoryPicker: some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundColor(Color(hex: FateCategory.wild.color))
                Text("Wild — Kategori Seç")
                    .font(AppTypography.sectionTitle)
                    .foregroundColor(AppColors.textPrimary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(FateCategory.selectableCategories) { category in
                    Button {
                        HapticManager.shared.success()
                        viewModel.exitWildChoice()
                        fateValue = 6
                        revealedCategory = category
                        flowStep = .fateReveal
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: category.icon)
                                .font(.system(size: 24))
                            Text(category.displayName)
                                .font(AppTypography.labelSmall)
                        }
                        .foregroundColor(Color(hex: category.color))
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .background(AppColors.glassDeep)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppColors.borderSoft, lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Actions

    private func resetForNewTurn() {
        rollTask?.cancel()
        fateValue = nil
        revealedCategory = nil
        revealedPosition = nil
        flowStep = .idle
    }

    private func rollFateDice() {
        guard isFateTurn else { return }

        flowStep = .rolling
        FeedbackManager.diceRollStart()

        let result = viewModel.rollFateDice()

        rollTask?.cancel()
        rollTask = Task { @MainActor in
            for _ in 1...8 {
                guard await sleep(seconds: 0.1) else { return }
                fateValue = Int.random(in: 1...6)
                HapticManager.shared.selection()
            }

            guard await sleep(seconds: 0.2) else { return }
            fateValue = result
            FeedbackManager.selection()

            let category = FateCategory.from(diceValue: result)
            revealedCategory = category

            if category == .wild {
                viewModel.enterWildChoice()
                flowStep = .wildChoice
            } else {
                flowStep = .fateReveal
            }
        }
    }

    private func rollPositionDice() {
        guard isPositionTurn else { return }

        flowStep = .rolling
        FeedbackManager.diceRollStart()

        rollTask?.cancel()
        rollTask = Task { @MainActor in
            for _ in 1...8 {
                guard await sleep(seconds: 0.08) else { return }
                rollingIconName = SurprisePositionCatalog.all.randomElement()?.assetName ?? rollingIconName
                FeedbackManager.selection()
            }

            guard await sleep(seconds: 0.26) else { return }
            if let position = viewModel.rollPositionDice() {
                revealedPosition = position
                FeedbackManager.success()
            }
            flowStep = .positionReveal
        }
    }

    private func openFateCard() {
        guard let category = revealedCategory else { return }
        HapticManager.shared.success()
        viewModel.openFateCard(category: category)
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

struct DiceSurpriseIcon: View {
    let assetName: String
    var size: CGFloat = 48

    var body: some View {
        Image(assetName)
            .resizable()
            .renderingMode(.template)
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundColor(.white)
    }
}

#Preview {
    let players = [
        Player(name: "Efe", gender: .male, role: .dominant, colorHex: "#E02B3F"),
        Player(name: "Su", gender: .female, role: .receptive, colorHex: "#F2A6B3")
    ]
    DiceView(viewModel: GameEngineViewModel(players: players))
}

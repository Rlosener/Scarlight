import SwiftUI

struct LighterGameView: View {
    @ObservedObject var viewModel: LighterGameViewModel
    private var theme: SessionTheme { .conversation(for: .lighter) }
    @AppStorage(PerformanceDefaults.performanceModeKey) private var isPerformanceModeEnabled = true
    var onExit: () -> Void
    @FocusState private var questionFieldFocused: Bool

    private var selectedTarget: Player? {
        guard let selectedTargetId = viewModel.selectedTargetId else { return nil }
        return viewModel.players.first { $0.id == selectedTargetId }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ConversationBackground()
                VStack(spacing: 0) {
                    header
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 20) {
                                Color.clear.frame(height: 0).id("conversationTop")
                                switch viewModel.turnPhase {
                                case .composing:
                                    askPhase
                                case .waitingReveal:
                                    revealPhase
                                case .answering:
                                    answerPhase
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                            .frame(maxWidth: 680)
                            .frame(maxWidth: .infinity)
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .onChange(of: viewModel.turnPhase) { _, _ in
                            proxy.scrollTo("conversationTop", anchor: .top)
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Kapat", action: dismissKeyboard)
                }
            }
        }
        .environment(\.sessionTheme, theme)
        .environment(\.ffPerformanceMode, isPerformanceModeEnabled)
        .visualEffectBudget(.resolved(performanceModeEnabled: isPerformanceModeEnabled))
    }

    private func dismissKeyboard() {
        questionFieldFocused = false
        KeyboardDismiss.resign()
    }

    private var header: some View {
        HStack {
            Text(AppConstants.gameNameDisplay)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 12)
            Button(action: onExit) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Oyundan çık")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private var askPhase: some View {
        VStack(spacing: 20) {
            ConversationBubble(role: "Soran", name: viewModel.holder.name) {
                TextField("Sorunu buraya yaz…", text: $viewModel.questionText, axis: .vertical)
                    .font(.body)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(3...8)
                    .focused($questionFieldFocused)
                    .accessibilityLabel("Sorun")
            }
            ConversationBubble(role: "Cevaplayan", name: selectedTarget?.name ?? "Birini seç", isAnswer: true) {
                targetPicker
            }
        }
    }

    private var revealPhase: some View {
        VStack(spacing: 20) {
            ConversationBubble(role: "Soran", name: viewModel.holder.name) {
                Label("Kapalı bir soru gönderdi.", systemImage: "envelope")
                    .font(.body)
                    .foregroundColor(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ConversationReplyPrompt(name: viewModel.answerTarget?.name ?? "Masa",
                                    message: "Soru sende. Hazır olduğunda aç.")
        }
    }

    private var answerPhase: some View {
        VStack(spacing: 20) {
            ConversationBubble(role: "Soran", name: viewModel.holder.name) {
                Text(viewModel.activeQuestion ?? "")
                    .font(.system(.title3, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ConversationReplyPrompt(name: viewModel.answerTarget?.name ?? "Masa")
        }
    }

    private var targetPicker: some View {
        FlowLayout(spacing: 8) {
            ForEach(viewModel.players.filter { $0.id != viewModel.holder.id }) { player in
                let isSelected = viewModel.selectedTargetId == player.id
                Button {
                    dismissKeyboard()
                    HapticManager.shared.selection()
                    viewModel.selectTarget(player)
                } label: {
                    HStack(spacing: 6) {
                        if isSelected { Image(systemName: "checkmark") }
                        Text(player.name).fixedSize(horizontal: false, vertical: true)
                    }
                    .font(.subheadline)
                    .foregroundColor(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(minHeight: 44)
                    .background(ConversationPalette.answer.opacity(isSelected ? 0.16 : 0.04),
                                in: RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            switch viewModel.turnPhase {
            case .composing:
                FFSecondaryButton(title: "Soru Öner") {
                    dismissKeyboard()
                    HapticManager.shared.light()
                    viewModel.suggestQuestion()
                }
                FFPrimaryButton(title: "Soruyu Ver", action: {
                    dismissKeyboard()
                    HapticManager.shared.success()
                    viewModel.giveQuestion()
                }, isEnabled: viewModel.canGiveQuestion)
            case .waitingReveal:
                FFPrimaryButton(title: "Soruyu Aç") {
                    dismissKeyboard()
                    HapticManager.shared.success()
                    viewModel.revealQuestion()
                }
            case .answering:
                FFPrimaryButton(title: "Cevaplandı · Çakmağı Al") {
                    dismissKeyboard()
                    HapticManager.shared.success()
                    viewModel.completeAnswer()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(maxWidth: 680)
        .frame(maxWidth: .infinity)
        .background(ConversationPalette.background)
    }
}

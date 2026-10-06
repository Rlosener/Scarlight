import SwiftUI

/// Oyun içinden hızlı kart/soru ekleme
struct QuickAddCardView: View {
    @Environment(\.dismiss) private var dismiss
    var playerCount: Int
    var onSaved: () -> Void

    @State private var deckType: CardDeckType = .neverHaveI
    @State private var contentTier: ContentTier = .beginning
    @State private var playerScope: CardPlayerScope = .mixed
    @State private var questionText = ""
    @State private var yesTaskText = ""
    @State private var duration = 45
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundDeep.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        Text("Yeni soru veya görev ekle. Kaydedince hemen oyunda kullanılır.")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)

                        Picker("Deste", selection: $deckType) {
                            ForEach(DeckContentGroup.playableGroups) { group in
                                Section(group.rawValue) {
                                    ForEach(group.deckTypes) { deck in
                                        Text(deck.displayName).tag(deck)
                                    }
                                }
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: deckType) { _, _ in applyTemplate() }

                        Picker("Seviye", selection: $contentTier) {
                            ForEach(ContentTier.allCases) { tier in
                                Text(tier.displayName).tag(tier)
                            }
                        }
                        .pickerStyle(.segmented)

                        CardPlayerScopePicker(scope: $playerScope)

                        templateHint

                        FormField(title: deckType == .neverHaveI ? "Ben hiç sorusu" : "Kart metni") {
                            TextEditor(text: $questionText)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(AppColors.cardDark)
                                .cornerRadius(8)
                                .foregroundColor(AppColors.textPrimary)
                        }

                        if deckType == .neverHaveI {
                            FormField(title: "Yaptıysan görevi") {
                                TextEditor(text: $yesTaskText)
                                    .frame(minHeight: 70)
                                    .padding(8)
                                    .background(AppColors.cardDark)
                                    .cornerRadius(8)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                        }

                        if deckType != .hardTruth {
                            FormField(title: "Süre (saniye)") {
                                Stepper("\(duration)", value: $duration, in: 15...300, step: 5)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                        }

                        CardTextPreviewView(
                            rawText: questionText,
                            duration: deckType == .hardTruth ? 45 : duration,
                            phase: previewPhase,
                            playerScope: playerScope,
                            secondaryRawText: deckType == .neverHaveI ? yesTaskText : nil
                        )

                        Text("İpuçları: {partner}, {partnere}, {partneri} · 3 kişide {diğer oyuncu}")
                            .font(AppTypography.labelSmall)
                            .foregroundColor(AppColors.textSecondary)

                        FFPrimaryButton(title: "Oyuna Ekle", action: saveCard, isEnabled: canSave)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Hızlı Kart Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .alert("Kaydedilemedi", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("Tamam", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .onAppear {
                playerScope = playerCount >= 3 ? .mixed : .twoPlayers
                applyTemplate()
            }
        }
    }

    private var templateHint: some View {
        Group {
            switch deckType {
            case .neverHaveI:
                hintBox("Örnek: Ben hiç partnerimin elini tutup yönlendirmedim.")
            case .hardTruth:
                hintBox("Örnek: Seni en hızlı kontrolden çıkaran davranış ne?")
            case .hardAction:
                hintBox("Örnek: Partnere göz teması kur.")
            case .fantasyRole:
                hintBox("Örnek: Partneri yönet, ritmi sen belirle.")
            default:
                EmptyView()
            }
        }
    }

    private func hintBox(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.labelSmall)
            .foregroundColor(AppColors.softRose)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.cardDark.opacity(0.5))
            .cornerRadius(12)
    }

    private var previewPhase: GamePhase {
        switch deckType {
        case .hardAction, .propTask: return .timedTask
        case .fantasyRole: return .roleDuo
        default: return .boldQuestion
        }
    }

    private var canSave: Bool {
        !questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func applyTemplate() {
        switch deckType {
        case .neverHaveI:
            if questionText.isEmpty {
                questionText = "Ben hiç "
            }
            if yesTaskText.isEmpty {
                yesTaskText = "Partnere "
            }
            duration = 45
        case .hardTruth:
            duration = 45
        case .hardAction:
            if questionText.isEmpty {
                questionText = "Partnere "
            }
            duration = 60
        case .fantasyRole:
            if questionText.isEmpty {
                questionText = "Partner ile "
            }
            duration = 90
        default:
            break
        }
    }

    private func saveCard() {
        var card = buildCard()
        card.isUserAuthored = true
        do {
            try CardCatalog.saveUserCard(card)
            HapticManager.shared.success()
            onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func buildCard() -> GameCard {
        let tier = contentTier
        let maxLevel: IntensityLevel = {
            switch tier {
            case .beginning: return .medium
            case .medium: return .hot
            case .hot: return .hardcore
            }
        }()

        let (type, phase): (CardType, GamePhase) = {
            switch deckType {
            case .neverHaveI, .hardTruth:
                return (.question, .boldQuestion)
            case .hardAction, .propTask:
                return (.task, .timedTask)
            case .fantasyRole:
                return (.roleDuo, .roleDuo)
            default:
                return (.question, .boldQuestion)
            }
        }()

        let intensity = tier == .hot ? 5 : (tier == .medium ? 4 : 3)

        return GameCard(
            title: deckType.displayName,
            type: type,
            phase: phase,
            intensity: intensity,
            minIntensity: tier.intensityLevel,
            maxIntensity: maxLevel,
            durationSeconds: deckType == .hardTruth ? 45 : duration,
            targetRule: .randomOther,
            text: questionText.trimmingCharacters(in: .whitespacesAndNewlines),
            deckType: deckType,
            contentTier: tier,
            minPlayers: playerScope.minPlayers,
            maxPlayers: playerScope.maxPlayers,
            onYesTask: deckType == .neverHaveI && !yesTaskText.isEmpty ? yesTaskText : nil
        )
    }
}

#Preview {
    QuickAddCardView(playerCount: 2, onSaved: {})
}

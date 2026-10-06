import SwiftUI

enum SessionSetupMode {
    case preGame
    case manage
    case postHardcoreRound

    func title(for profile: SessionContentProfile = .intimate) -> String {
        switch self {
        case .preGame:
            return profile == .social ? "Arkadaş Ortamı" : "Sıcak Ortam"
        case .manage: return "Eşya & Desteler"
        case .postHardcoreRound: return "Yeni Tur Ayarları"
        }
    }

    func subtitle(for profile: SessionContentProfile = .intimate) -> String {
        switch self {
        case .preGame where profile == .social:
            return "Bar destelerini, fazları ve yoğunluğu ayarla — sonra oyuna geç."
        case .preGame:
            return "Deste, eşya ve fazları ayarla — sonra oyuna geç."
        case .manage:
            return "Varsayılan eşya ve deste ayarlarını düzenle. Oyun başlarken bunlar kullanılır."
        case .postHardcoreRound:
            return "Hardcore turu tamamlandı. Hangi kategoride ve hangi ayarla devam etmek istediğinizi seçin."
        }
    }

    var buttonTitle: String {
        switch self {
        case .preGame: return "Oyuna Başla"
        case .manage: return "Kaydet"
        case .postHardcoreRound: return "Yeni Tura Başla"
        }
    }

    var showsBackButton: Bool {
        switch self {
        case .preGame, .manage: return true
        case .postHardcoreRound: return false
        }
    }

    var showsPresetPicker: Bool {
        true
    }
}

/// Oyun öncesi ve hardcore sonrası tur ayarları (deste, eşya, yoğunluk).
struct SessionSetupView: View {
    let mode: SessionSetupMode
    let players: [Player]
    var atmosphere: PlayAtmosphere? = nil
    var initialConfig: GameSessionConfig = .default
    var onBack: (() -> Void)? = nil
    var onContinue: (GameSessionConfig) -> Void

    @State private var selectedPropIds: Set<String>
    @State private var enabledDecks: Set<CardDeckType>
    @State private var playIntensity: IntensityLevel
    @State private var maxCardIntensity: Int
    @State private var enabledTiers: Set<ContentTier>
    @State private var enabledPhases: Set<GamePhase>
    @State private var contentProfile: SessionContentProfile
    @State private var resetDrawnCardsOnStart: Bool
    @State private var boundaryPreferences: BoundaryPreferences
    @State private var catalogCards: [GameCard] = []
    @State private var loadedDeckCounts: [(CardDeckType, Int)] = []
    @State private var playablePropIds: Set<String> = []
    @State private var playableCardCount: Int = 0
    @State private var showSavePresetDialog = false
    @State private var newPresetName = ""
    @State private var showChecklistShare = false
    @State private var presetRefreshToken = 0
    @State private var countRefreshTask: Task<Void, Never>?
    @Environment(\.sessionTheme) private var theme

    init(
        mode: SessionSetupMode,
        players: [Player],
        atmosphere: PlayAtmosphere? = nil,
        initialConfig: GameSessionConfig = .default,
        onBack: (() -> Void)? = nil,
        onContinue: @escaping (GameSessionConfig) -> Void
    ) {
        self.mode = mode
        self.players = players
        self.atmosphere = atmosphere
        self.initialConfig = initialConfig
        self.onBack = onBack
        self.onContinue = onContinue
        _selectedPropIds = State(initialValue: initialConfig.selectedPropIds)
        _enabledDecks = State(initialValue: initialConfig.enabledDeckTypes)
        _playIntensity = State(initialValue: initialConfig.playIntensityLevel)
        _maxCardIntensity = State(initialValue: initialConfig.maxCardIntensity)
        _enabledTiers = State(initialValue: initialConfig.enabledContentTiers)
        _enabledPhases = State(initialValue: initialConfig.enabledPhases)
        _contentProfile = State(initialValue: initialConfig.contentProfile)
        _resetDrawnCardsOnStart = State(initialValue: initialConfig.resetDrawnCardsOnStart)
        _boundaryPreferences = State(initialValue: initialConfig.boundaryPreferences)
    }

    private var activeDeckGroups: [DeckContentGroup] {
        DeckContentGroup.playableGroups(for: contentProfile)
    }

    private var activePlayableDecks: [CardDeckType] {
        CardDeckType.playableDefaults(for: contentProfile)
    }

    private var showsPropsSection: Bool {
        contentProfile == .intimate
    }

    private var effectiveAtmosphere: PlayAtmosphere {
        atmosphere ?? (contentProfile == .social ? .friends : .hot)
    }

    private var setupExperience: ModeExperienceSpec {
        effectiveAtmosphere.experience
    }

    private var screenTitle: String {
        mode == .preGame ? setupExperience.heroTitle : mode.title(for: contentProfile)
    }

    private var screenSubtitle: String {
        mode == .preGame ? setupExperience.moodLine : mode.subtitle(for: contentProfile)
    }

    var body: some View {
        ZStack {
            FFBackground()

            VStack(spacing: 0) {
                if mode.showsBackButton, let onBack {
                    FFScreenHeader(title: screenTitle, onBack: onBack)
                }

                VStack(spacing: 8) {
                    if !mode.showsBackButton || onBack == nil {
                        Text(screenTitle)
                            .font(AppTypography.sectionTitle)
                            .foregroundColor(AppColors.textPrimary)
                    }

                    Text(screenSubtitle)
                        .font(AppTypography.caption)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, mode.showsBackButton && onBack != nil ? 4 : 20)
                .padding(.bottom, 16)

                ScrollView {
                    VStack(spacing: 24) {
                        if mode == .preGame {
                            setupHeroSection
                        }
                        if mode.showsPresetPicker {
                            presetSection
                        }
                        if mode == .preGame || mode == .manage {
                            smartSetupSection
                        }
                        intensitySection
                        boundarySection
                        contentTierSection
                        if mode != .manage {
                            phaseSection
                            playableCardsSection
                        }
                        if mode == .preGame {
                            repeatControlSection
                        }
                        deckSection
                        if showsPropsSection {
                            propAssistantSection
                            propsSection
                            if mode == .preGame && !selectedPropIds.isEmpty {
                                preparationSection
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }

                VStack(spacing: 12) {
                    if mode == .postHardcoreRound {
                        FFPrimaryButton(title: "Aynı ayarlarla devam", action: quickContinue, isEnabled: PlayableCardCounter.countPlayableCards(config: initialConfig, playerCount: players.count, cards: catalogCards) > 0)
                        FFSecondaryButton(title: "Seçili ayarlarla devam", action: confirm)
                    } else if mode == .manage {
                        FFPrimaryButton(title: mode.buttonTitle, action: confirm, isEnabled: canContinue)
                    } else {
                        FFPrimaryButton(title: mode.buttonTitle, action: confirm, isEnabled: canContinue)
                    }

                    if mode != .manage && playableCardCount == 0 {
                        Text("Bu seçimlere uygun kart yok. Deste, oyuncu veya sınır ayarlarını değiştir.")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.softRose)
                            .multilineTextAlignment(.center)
                    }
                    Text(summaryLine)
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .background(
                    LinearGradient(
                        colors: [theme.backgroundDeep.opacity(0), theme.backgroundDeep],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 120)
                    .offset(y: -40)
                )
            }
        }
        .sessionTheme(for: effectiveAtmosphere)
        .onAppear(perform: loadCatalog)
        .onChange(of: selectedPropIds) { _, _ in schedulePlayableCountRefresh() }
        .onChange(of: enabledDecks) { _, _ in schedulePlayableCountRefresh() }
        .onChange(of: enabledTiers) { _, _ in schedulePlayableCountRefresh() }
        .onChange(of: playIntensity) { _, _ in schedulePlayableCountRefresh() }
        .onChange(of: maxCardIntensity) { _, _ in schedulePlayableCountRefresh() }
        .onChange(of: boundaryPreferences) { _, _ in schedulePlayableCountRefresh() }
        .onReceive(NotificationCenter.default.publisher(for: .cardsDidChange)) { _ in loadCatalog() }
        .onChange(of: contentProfile) { _, _ in loadCatalog() }
        .alert("Şablon Kaydet", isPresented: $showSavePresetDialog) {
            TextField("Şablon adı", text: $newPresetName)
            Button("Kaydet") {
                let name = newPresetName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { return }
                _ = SessionPresetStore.saveUserPreset(name: name, config: buildConfig())
                newPresetName = ""
            }
            Button("İptal", role: .cancel) { newPresetName = "" }
        } message: {
            Text("Mevcut eşya, deste ve faz ayarlarını şablon olarak sakla.")
        }
    }

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("HAZIR OYUN KURULUMLARI")
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.textSecondary)
                        .tracking(2)
                    Text("Bir kurulum seç; istersen kopyasını alıp kendi presetin yap.")
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.textMuted)
                }
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(availablePresets) { preset in
                        presetChip(preset)
                    }
                }
            }

            Button("Mevcut ayarı şablon olarak kaydet") {
                showSavePresetDialog = true
            }
            .font(AppTypography.labelSmall)
            .foregroundColor(theme.accentSoft)
        }
        .padding(16)
        .background(theme.cardDark.opacity(0.6))
        .cornerRadius(20)
    }

    private var setupHeroSection: some View {
        ModeSetupHeroCard(
            experience: setupExperience,
            playerCount: players.count,
            playableCardCount: playableCardCount,
            summary: summaryLine
        )
    }

    private var availablePresets: [SessionPreset] {
        _ = presetRefreshToken
        return SessionPresetStore.allPresets()
    }

    private func presetChip(_ preset: SessionPreset) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                applyPreset(preset)
            } label: {
                VStack(alignment: .leading, spacing: 5) {
                    Text(preset.name)
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)
                    Text(preset.config.contentProfile.displayName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(theme.accentSoft)
                }
                .frame(width: 132, alignment: .leading)
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                Button {
                    _ = SessionPresetStore.duplicateAsUserPreset(preset)
                    presetRefreshToken += 1
                    HapticManager.shared.success()
                } label: {
                    Label("Kopya", systemImage: "plus.square.on.square")
                        .labelStyle(.iconOnly)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                }
                .accessibilityLabel("Şablonu kopyala")

                if !preset.isBuiltIn {
                    Button(role: .destructive) {
                        SessionPresetStore.deleteUserPreset(id: preset.id)
                        presetRefreshToken += 1
                        HapticManager.shared.warning()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.mutedRed)
                    }
                    .accessibilityLabel("Şablonu sil")
                }
            }
        }
        .padding(12)
        .background(theme.accent.opacity(0.16))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.accent.opacity(0.36), lineWidth: 1)
        )
    }

    private var phaseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OYUN FAZLARI")
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.textSecondary)
                .tracking(2)

            Text("Kapattığın fazlar bu turda atlanır.")
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.textMuted)

            ForEach(GamePhase.playablePhases(for: contentProfile)) { phase in
                let isOn = enabledPhases.contains(phase)
                Button {
                    if isOn {
                        if enabledPhases.count > 1 { enabledPhases.remove(phase) }
                    } else {
                        enabledPhases.insert(phase)
                    }
                    HapticManager.shared.selection()
                } label: {
                    HStack {
                        Text(phase.rawValue)
                            .font(AppTypography.labelSmall)
                        Spacer()
                        Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isOn ? theme.accent : AppColors.textMuted)
                    }
                    .foregroundColor(isOn ? AppColors.textPrimary : AppColors.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(isOn ? theme.accent.opacity(0.15) : theme.cardElevated)
                    .cornerRadius(12)
                }
            }
        }
        .padding(16)
        .background(theme.cardDark.opacity(0.6))
        .cornerRadius(20)
    }

    private var playableCardsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("KULLANILABİLİR KARTLAR")
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.textSecondary)
                .tracking(2)

            Text("\(playableCardCount) kart bu ayarlarla oynanabilir")
                .font(AppTypography.button)
                .foregroundColor(AppColors.champagne)

            let breakdown = PlayableCardCounter.deckBreakdown(config: previewConfig, playerCount: max(players.count, 2), cards: catalogCards)
            ForEach(breakdown, id: \.0) { deck, count in
                if count > 0 {
                    Text("\(deck.displayName): \(count)")
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding(16)
        .background(theme.cardDark.opacity(0.6))
        .cornerRadius(20)
    }

    private var preparationSection: some View {
        PreparationChecklistSection(
            selectedPropIds: selectedPropIds,
            showShare: $showChecklistShare
        )
    }

    private var previewConfig: GameSessionConfig {
        buildConfig()
    }

    private func applyPreset(_ preset: SessionPreset) {
        let config = preset.config
        contentProfile = config.contentProfile
        selectedPropIds = config.contentProfile == .social ? [] : config.selectedPropIds
        enabledDecks = config.enabledDeckTypes
        playIntensity = config.playIntensityLevel
        maxCardIntensity = config.maxCardIntensity
        enabledTiers = config.enabledContentTiers
        enabledPhases = config.enabledPhases
        resetDrawnCardsOnStart = config.resetDrawnCardsOnStart
        boundaryPreferences = config.boundaryPreferences
        loadedDeckCounts = CardCatalog.deckStats(from: CardCatalog.loadForGameplay(), profile: contentProfile)
        refreshPlayableCount()
        HapticManager.shared.success()
    }

    private func refreshPlayableCount() {
        playableCardCount = PlayableCardCounter.countPlayableCards(
            config: previewConfig,
            playerCount: max(players.count, 2),
            cards: catalogCards
        )
    }

    private var canContinue: Bool {
        !enabledDecks.subtracting(boundaryPreferences.disabledDeckTypes).isEmpty && !enabledTiers.isEmpty
            && (mode == .manage || playableCardCount > 0)
    }

    private var summaryLine: String {
        let deckCount = enabledDecks.subtracting(boundaryPreferences.disabledDeckTypes).count
        if contentProfile == .social {
            return "\(deckCount) deste • \(enabledTiers.count) seviye • \(playIntensity.displayName(for: contentProfile))"
        }
        return "\(deckCount) deste • \(enabledTiers.count) seviye • \(playIntensity.displayName) • \(selectedPropIds.count) eşya"
    }

    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(contentProfile == .social ? "BAR TEMPO" : "OYUN YOĞUNLUĞU")
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.textSecondary)
                .tracking(2)

            Picker("Yoğunluk", selection: $playIntensity) {
                ForEach(IntensityLevel.playableLevels(for: contentProfile)) { level in
                    Text(level.displayName(for: contentProfile)).tag(level)
                }
            }
            .pickerStyle(.segmented)

            Text(intensityHint)
                .font(AppTypography.labelSmall)
                .foregroundColor(theme.accentSoft)

            if contentProfile == .intimate {
                HStack {
                    Text("Kart yoğunluğu üst sınırı")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Stepper("\(maxCardIntensity)", value: $maxCardIntensity, in: 3...5)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
        .padding(16)
        .background(theme.cardDark.opacity(0.6))
        .cornerRadius(20)
    }

    private var smartSetupSection: some View {
        let recommendation = recommendedPreset
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.accent)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 5) {
                    Text("AKILLI KURULUM")
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.textSecondary)
                        .tracking(2)
                    Text(recommendation?.name ?? "Mevcut ayar uygun")
                        .font(AppTypography.button)
                        .foregroundColor(AppColors.textPrimary)
                    Text(smartSetupMessage)
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                if let recommendation {
                    Button {
                        applyPreset(recommendation)
                    } label: {
                        Label("Öneriyi uygula", systemImage: "checkmark.circle.fill")
                            .font(AppTypography.labelSmall)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, 12)
                            .frame(height: 36)
                            .background(theme.accent.opacity(0.26))
                            .cornerRadius(18)
                    }
                }

                Button {
                    applyQuestionFirstDefaults()
                } label: {
                    Label("Soru ağırlıklı", systemImage: "questionmark.bubble.fill")
                        .font(AppTypography.labelSmall)
                        .foregroundColor(theme.accentSoft)
                        .padding(.horizontal, 12)
                        .frame(height: 36)
                        .background(theme.cardElevated)
                        .cornerRadius(18)
                }
            }
        }
        .padding(16)
        .background(theme.cardDark.opacity(0.6))
        .cornerRadius(20)
    }

    private var recommendedPreset: SessionPreset? {
        let presets = SessionPreset.builtIns
        if players.count >= 3 {
            return presets.first { $0.id == "builtin_three_player" }
        }
        if contentProfile == .social {
            return presets.first { $0.id == "builtin_bar" }
        }
        if !boundaryPreferences.allowsProps || selectedPropIds.isEmpty {
            return presets.first { $0.id == "builtin_no_props" }
        }
        if playIntensity == .soft {
            return presets.first { $0.id == "builtin_soft_start" }
        }
        return presets.first { $0.id == "builtin_balanced_night" }
    }

    private var smartSetupMessage: String {
        if players.count >= 3 {
            return "3 kişilik özel kartlar açık kalır; 2 kişilik kartlar da güvenli şekilde oynanabilir."
        }
        if contentProfile == .social {
            return "Bar profili +18 olmayan soru ve hafif cesaret temposuna göre sıralanır."
        }
        if !boundaryPreferences.allowsProps {
            return "Propsuz sınır açık; eşya isteyen kartlar oyun havuzundan çıkarılır."
        }
        return "İlk turlar soru ağırlıklı kalır, ilerledikçe görev ve rol kartları devreye girer."
    }

    private func applyQuestionFirstDefaults() {
        if contentProfile == .social {
            enabledDecks = [.barNeverHaveI, .barTruth]
            enabledPhases = [.boldQuestion, .surpriseQuestion]
            enabledTiers = [.beginning, .medium]
            playIntensity = .soft
            boundaryPreferences.allowsTimedCards = false
        } else {
            enabledDecks = [.neverHaveI, .hardTruth]
            enabledPhases = [.boldQuestion, .surpriseQuestion, .finalFocus]
            enabledTiers = [.beginning, .medium]
            playIntensity = .soft
            maxCardIntensity = 3
            boundaryPreferences.maximumCardIntensity = 3
        }
        HapticManager.shared.success()
    }

    private var boundarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SINIRLAR")
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.textSecondary)
                        .tracking(2)
                    Text(boundaryPreferences.hasActiveLimits ? "Bu oyun için sert filtreler aktif." : "İstersen konfor sınırlarını önceden kilitle.")
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.textMuted)
                }
                Spacer()
            }

            Toggle(isOn: propsDisabledBinding) {
                boundaryToggleLabel(
                    title: "Propsuz oyna",
                    subtitle: "Eşya isteyen kartlar ve eşya destesi çıkmaz."
                )
            }
            .tint(theme.accent)
            .disabled(contentProfile == .social)

            Toggle(isOn: timedCardsDisabledBinding) {
                boundaryToggleLabel(
                    title: "Süreli kartları kapat",
                    subtitle: "Timer isteyen görev ve cevap sonrası görevler havuzdan çıkar."
                )
            }
            .tint(theme.accent)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Maksimum yoğunluk")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                    Text("Kart yoğunluğu \(boundaryPreferences.maximumCardIntensity) üst sınırında kalır.")
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.textMuted)
                }
                Spacer()
                Stepper(
                    "\(boundaryPreferences.maximumCardIntensity)",
                    value: Binding(
                        get: { boundaryPreferences.maximumCardIntensity },
                        set: { newValue in
                            boundaryPreferences.maximumCardIntensity = min(5, max(3, newValue))
                            maxCardIntensity = min(maxCardIntensity, boundaryPreferences.maximumCardIntensity)
                        }
                    ),
                    in: 3...5
                )
                .foregroundColor(AppColors.champagne)
            }

            FlowLayout(spacing: 8) {
                ForEach(activePlayableDecks) { deck in
                    boundaryDeckChip(deck)
                }
            }
        }
        .padding(16)
        .background(theme.cardDark.opacity(0.6))
        .cornerRadius(20)
    }

    private var propsDisabledBinding: Binding<Bool> {
        Binding(
            get: { !boundaryPreferences.allowsProps || contentProfile == .social },
            set: { newValue in
                boundaryPreferences.allowsProps = !newValue
                if newValue {
                    selectedPropIds.removeAll()
                    enabledDecks.remove(.propTask)
                    boundaryPreferences.disabledDeckTypes.insert(.propTask)
                } else {
                    boundaryPreferences.disabledDeckTypes.remove(.propTask)
                }
            }
        )
    }

    private var timedCardsDisabledBinding: Binding<Bool> {
        Binding(
            get: { !boundaryPreferences.allowsTimedCards },
            set: { boundaryPreferences.allowsTimedCards = !$0 }
        )
    }

    private func boundaryToggleLabel(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
            Text(subtitle)
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.textMuted)
        }
    }

    private func boundaryDeckChip(_ deck: CardDeckType) -> some View {
        let isBlocked = boundaryPreferences.disabledDeckTypes.contains(deck)
        return Button {
            if isBlocked {
                boundaryPreferences.disabledDeckTypes.remove(deck)
            } else {
                boundaryPreferences.disabledDeckTypes.insert(deck)
                enabledDecks.remove(deck)
            }
            HapticManager.shared.selection()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isBlocked ? "lock.fill" : deck.icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(deck.displayName)
                    .lineLimit(1)
            }
            .font(AppTypography.labelSmall)
            .foregroundColor(isBlocked ? AppColors.textMuted : theme.accentSoft)
            .padding(.horizontal, 10)
            .frame(height: 32)
            .background(isBlocked ? AppColors.cardElevated.opacity(0.7) : theme.accent.opacity(0.14))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isBlocked ? AppColors.borderSoft : theme.accent.opacity(0.35), lineWidth: 1)
            )
        }
    }

    private var intensityHint: String {
        if contentProfile == .social {
            switch playIntensity {
            case .soft: return "Hafif bar soruları ve görevler."
            case .medium: return "Biraz daha cesur bar içeriği."
            default: return ""
            }
        }
        switch playIntensity {
        case .soft: return "Daha yumuşak sorular ve görevler."
        case .medium: return "Dengeli cesaret ve tempo."
        case .hot: return "Daha ateşli içerikler öncelikli."
        case .hardcore: return "En sert kartlar dahil."
        }
    }

    private var contentTierSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("İÇERİK SEVİYESİ")
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.textSecondary)
                .tracking(2)

            HStack(spacing: 8) {
                ForEach(ContentTier.playableTiers(for: contentProfile)) { tier in
                    let isOn = enabledTiers.contains(tier)
                    Button {
                        if isOn {
                            if enabledTiers.count > 1 { enabledTiers.remove(tier) }
                        } else {
                            enabledTiers.insert(tier)
                        }
                        HapticManager.shared.selection()
                    } label: {
                        Text(tier.displayName(for: contentProfile))
                            .font(AppTypography.labelSmall)
                            .foregroundColor(isOn ? AppColors.textPrimary : AppColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isOn ? theme.accent.opacity(0.25) : theme.cardElevated)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isOn ? theme.accent.opacity(0.5) : AppColors.borderSoft, lineWidth: 1)
                            )
                    }
                }
            }
        }
        .padding(16)
        .background(theme.cardDark.opacity(0.6))
        .cornerRadius(20)
    }

    private var deckSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("KART DESTELERİ")
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.textSecondary)
                .tracking(2)

            ForEach(activeDeckGroups) { group in
                deckGroupBlock(group)
            }

            let total = loadedDeckCounts.reduce(0) { $0 + $1.1 }
            if total > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(total) kart yüklü")
                        .font(AppTypography.caption)
                        .foregroundColor(theme.accentSoft)

                    ForEach(activeDeckGroups) { group in
                        let groupCount = loadedDeckCounts
                            .filter { group.deckTypes.contains($0.0) }
                            .reduce(0) { $0 + $1.1 }
                        if groupCount > 0 {
                            Text("\(group.rawValue): \(groupCount)")
                                .font(AppTypography.labelSmall)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(theme.cardDark.opacity(0.6))
        .cornerRadius(20)
    }

    private var propAssistantSection: some View {
        let analysis = PropSetupAssistant.analyze(config: previewConfig, playerCount: max(players.count, 2), cards: catalogCards)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: analysis.propDeckEnabled ? "bag.fill" : "bag")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.accent)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text("EŞYA ASİSTANI")
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.textSecondary)
                        .tracking(2)
                    Text(analysis.title)
                        .font(AppTypography.button)
                        .foregroundColor(AppColors.textPrimary)
                    Text(analysis.message)
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                if !analysis.propDeckEnabled || analysis.missingPropSelection || analysis.playablePropCardCount == 0 {
                    Button {
                        enableRecommendedProps(analysis.recommendedPropIds)
                    } label: {
                        Text(analysis.propDeckEnabled ? "Önerilenleri seç" : "Eşya görevlerini aç")
                            .font(AppTypography.labelSmall)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, 12)
                            .frame(height: 36)
                            .background(theme.accent.opacity(0.26))
                            .cornerRadius(18)
                    }
                }

                Button {
                    selectedPropIds.removeAll()
                    enabledDecks.remove(.propTask)
                    HapticManager.shared.selection()
                } label: {
                    Text("Propsuz devam")
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, 12)
                        .frame(height: 36)
                        .background(theme.cardElevated)
                        .cornerRadius(18)
                }
            }
        }
        .padding(16)
        .background(theme.cardDark.opacity(0.6))
        .cornerRadius(20)
    }

    private func enableRecommendedProps(_ ids: Set<String>) {
        enabledDecks.insert(.propTask)
        let playable = ids.intersection(playablePropIds)
        if selectedPropIds.isEmpty {
            let fallback = Set(playablePropIds.prefix(8))
            selectedPropIds.formUnion(playable.isEmpty ? fallback : playable)
        }
        HapticManager.shared.success()
    }

    private func deckGroupBlock(_ group: DeckContentGroup) -> some View {
        let decks = group.deckTypes.filter { activePlayableDecks.contains($0) }
        let enabledCount = decks.filter { enabledDecks.contains($0) }.count

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: group.icon)
                    .foregroundColor(theme.accent)
                    .font(.system(size: 16))
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 4) {
                    Text(group.rawValue)
                        .font(AppTypography.button)
                        .foregroundColor(AppColors.textPrimary)
                    Text(group.subtitle)
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                Text("\(enabledCount)/\(decks.count)")
                    .font(AppTypography.labelSmall)
                    .foregroundColor(theme.accentSoft)
            }

            VStack(spacing: 8) {
                ForEach(decks) { deck in
                    deckToggle(deck)
                }
            }
        }
        .padding(.top, 4)
    }

    private func deckToggle(_ deck: CardDeckType) -> some View {
        let isBlocked = boundaryPreferences.disabledDeckTypes.contains(deck)
        let isOn = enabledDecks.contains(deck) && !isBlocked
        let count = loadedDeckCounts.first(where: { $0.0 == deck })?.1 ?? 0
        return Button {
            guard !isBlocked else { return }
            if isOn { enabledDecks.remove(deck) } else { enabledDecks.insert(deck) }
            HapticManager.shared.selection()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isBlocked ? "lock.fill" : deck.icon)
                    .font(.system(size: 14))
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(deck.displayName)
                            .font(AppTypography.labelSmall)
                            .lineLimit(1)
                        if count > 0 {
                            Text("(\(count))")
                                .font(AppTypography.labelSmall)
                                .foregroundColor(AppColors.textMuted)
                        }
                    }
                    Text(deck.subtitle)
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.textMuted)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if !deck.contentLabels.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(deck.contentLabels) { label in
                                Text(label.rawValue)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(theme.accentSoft)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(theme.accent.opacity(0.12))
                                    .cornerRadius(6)
                            }
                        }
                    }
                }

                Spacer(minLength: 4)

                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isOn ? theme.accent : AppColors.textMuted)
            }
            .foregroundColor(isOn ? AppColors.textPrimary : AppColors.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isOn ? theme.accent.opacity(0.18) : theme.cardElevated)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isOn ? theme.accent.opacity(0.45) : AppColors.borderSoft, lineWidth: 1)
            )
            .opacity(isBlocked ? 0.55 : 1)
        }
        .disabled(isBlocked)
    }

    private var propsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("EŞYALAR")
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.textSecondary)
                .tracking(2)

            ForEach(PropCategory.allCases) { category in
                propCategorySection(category)
            }
        }
    }

    private func propCategorySection(_ category: PropCategory) -> some View {
        let props = PropCatalog.allProps(for: category)
        let selectedInCategory = props.filter { selectedPropIds.contains($0.id) }.count
        let playableCount = props.filter { playablePropIds.contains($0.id) }.count

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: category.icon)
                    .foregroundColor(theme.accent)
                    .font(.system(size: 18))
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(category.rawValue)
                        .font(AppTypography.button)
                        .foregroundColor(AppColors.textPrimary)
                    Text(category.subtitle)
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                Text("\(selectedInCategory)/\(playableCount)")
                    .font(AppTypography.labelSmall)
                    .foregroundColor(theme.accentSoft)
            }

            HStack(spacing: 12) {
                Button("Tümünü seç") {
                    props.filter { playablePropIds.contains($0.id) }
                        .forEach { selectedPropIds.insert($0.id) }
                    HapticManager.shared.selection()
                }
                .font(AppTypography.labelSmall)
                .foregroundColor(theme.accent)

                Button("Temizle") {
                    props.forEach { selectedPropIds.remove($0.id) }
                    HapticManager.shared.selection()
                }
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.textSecondary)
            }

            ForEach(category.subcategories) { subcategory in
                propSubcategoryBlock(subcategory)
            }
        }
        .padding(16)
        .background(theme.cardDark.opacity(0.6))
        .cornerRadius(20)
    }

    @ViewBuilder
    private func propSubcategoryBlock(_ subcategory: PropSubcategory) -> some View {
        let props = PropCatalog.allProps(for: subcategory)
        let playable = props.filter { playablePropIds.contains($0.id) }

        if !props.isEmpty, !playable.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: subcategory.icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.champagne)
                    Text(subcategory.rawValue)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.champagne)
                    Spacer()
                    Text("\(playable.filter { selectedPropIds.contains($0.id) }.count)/\(playable.count)")
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.textMuted)
                }

                FlowLayout(spacing: 8) {
                    ForEach(props) { prop in
                        propChip(prop)
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    private func propChip(_ prop: GameProp) -> some View {
        let hasCards = playablePropIds.contains(prop.id)
        let isSelected = selectedPropIds.contains(prop.id)

        return Button {
            guard hasCards else { return }
            if isSelected { selectedPropIds.remove(prop.id) } else { selectedPropIds.insert(prop.id) }
            HapticManager.shared.selection()
        } label: {
            Text(prop.name)
                .font(AppTypography.labelSmall)
                .foregroundColor(chipTextColor(hasCards: hasCards, isSelected: isSelected))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(chipBackground(hasCards: hasCards, isSelected: isSelected))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(chipBorder(hasCards: hasCards, isSelected: isSelected), lineWidth: 1)
                )
                .opacity(hasCards ? 1 : 0.45)
        }
        .disabled(!hasCards)
    }

    private func chipTextColor(hasCards: Bool, isSelected: Bool) -> Color {
        guard hasCards else { return AppColors.textSecondary.opacity(0.5) }
        return isSelected ? AppColors.textPrimary : AppColors.textSecondary
    }

    private func chipBackground(hasCards: Bool, isSelected: Bool) -> Color {
        guard hasCards else { return theme.cardElevated.opacity(0.5) }
        return isSelected ? theme.accent.opacity(0.3) : theme.cardElevated
    }

    private func chipBorder(hasCards: Bool, isSelected: Bool) -> Color {
        guard hasCards else { return AppColors.borderSoft.opacity(0.4) }
        return isSelected ? theme.accent.opacity(0.5) : AppColors.borderSoft
    }

    private func loadCatalog() {
        let all = CardCatalog.loadForGameplay()
        catalogCards = all
        loadedDeckCounts = CardCatalog.deckStats(from: all, profile: contentProfile)
        playablePropIds = Set(all.flatMap { $0.requiredPropIds ?? [] })
        if contentProfile == .social {
            enabledTiers = enabledTiers.intersection(Set(ContentTier.playableTiers(for: .social)))
            if enabledTiers.isEmpty { enabledTiers = [.beginning, .medium] }
            enabledPhases = enabledPhases.intersection(Set(GamePhase.playablePhases(for: .social)))
            if enabledPhases.isEmpty {
                enabledPhases = Set(GamePhase.playablePhases(for: .social))
            }
            if playIntensity.rawValue > IntensityLevel.medium.rawValue {
                playIntensity = .medium
            }
            boundaryPreferences = boundaryPreferences.normalized(for: .social)
            selectedPropIds.removeAll()
            enabledDecks.remove(.propTask)
        }
        refreshPlayableCount()
    }

    private func schedulePlayableCountRefresh() {
        countRefreshTask?.cancel()
        countRefreshTask = Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }
            refreshPlayableCount()
        }
    }

    private func confirm() {
        refreshPlayableCount()
        guard canContinue else { return }
        HapticManager.shared.success()
        onContinue(buildConfig())
    }

    private func quickContinue() {
        guard PlayableCardCounter.countPlayableCards(config: initialConfig, playerCount: players.count, cards: catalogCards) > 0 else { return }
        HapticManager.shared.success()
        onContinue(initialConfig)
    }

    private func buildConfig() -> GameSessionConfig {
        let normalizedBoundaries = boundaryPreferences.normalized(for: contentProfile)
        let deckFallback = Set(activePlayableDecks)
        let tiers = enabledTiers.intersection(Set(ContentTier.playableTiers(for: contentProfile)))
        let phases = enabledPhases.intersection(Set(GamePhase.playablePhases(for: contentProfile)))
        let intensity: IntensityLevel = {
            let allowed = IntensityLevel.playableLevels(for: contentProfile)
            return allowed.contains(playIntensity) ? playIntensity : (allowed.first ?? .soft)
        }()
        let effectiveDecks = (enabledDecks.isEmpty ? deckFallback : enabledDecks)
            .subtracting(normalizedBoundaries.disabledDeckTypes)
        let effectiveSelectedProps = contentProfile == .social || !normalizedBoundaries.allowsProps ? [] : selectedPropIds
        return GameSessionConfig(
            selectedPropIds: effectiveSelectedProps,
            enabledDeckTypes: effectiveDecks.isEmpty ? deckFallback.subtracting(normalizedBoundaries.disabledDeckTypes) : effectiveDecks,
            contentProfile: contentProfile,
            playIntensityLevel: intensity,
            maxCardIntensity: contentProfile == .social ? min(maxCardIntensity, 3) : maxCardIntensity,
            enabledContentTiers: tiers.isEmpty ? Set(ContentTier.playableTiers(for: contentProfile)) : tiers,
            enabledPhases: phases.isEmpty ? Set(GamePhase.playablePhases(for: contentProfile)) : phases,
            resetDrawnCardsOnStart: resetDrawnCardsOnStart,
            boundaryPreferences: normalizedBoundaries
        )
    }

    private var repeatControlSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TEKRARLAR")
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.textSecondary)
                .tracking(2)

            Toggle(isOn: $resetDrawnCardsOnStart) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sorulan / çıkan soruları sıfırla")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                    Text(resetDrawnCardsOnStart
                         ? "Açık: yeni oyunda tekrarlar daha erken görülebilir."
                         : "Kapalı: tekrar eden soruların önüne geçmek için geçmiş korunur.")
                        .font(AppTypography.caption)
                        .foregroundColor(theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(theme.accentBright)
            .padding(16)
            .ffGlassPanelStyle(cornerRadius: 18)
        }
    }
}

/// Basit akış düzeni — eşya etiketleri için
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let idealWidth = subviews.reduce(CGFloat.zero) { $0 + $1.sizeThatFits(.unspecified).width + spacing }
        let maxWidth = max(0, proposal.width.flatMap { $0.isFinite ? $0 : nil } ?? max(0, idealWidth - spacing))
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var frames: [CGRect] = []

        for subview in subviews {
            let measured = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            let size = CGSize(width: min(maxWidth, measured.width), height: measured.height)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}

import SwiftUI

struct CardEditorView: View {
    @StateObject private var viewModel = CardEditorViewModel()
    @State private var showAddCard = false
    @State private var cardPendingDelete: GameCard?
    @State private var cardPendingPreview: GameCard?
    @State private var cardPendingEdit: GameCard?
    @State private var deleteErrorMessage: String?
    @Environment(\.dismiss) private var dismiss
    var onBack: (() -> Void)? = nil

    var body: some View {
        ZStack {
            FFBackground()

            VStack(spacing: 0) {
                if let onBack {
                    FFScreenHeader(
                        title: "Kartlar",
                        onBack: onBack,
                        trailing: AnyView(
                            Button(action: { showAddCard = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(AppColors.ruby)
                            }
                        )
                    )
                } else {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer()

                        Text("Kart Editörü")
                            .font(AppTypography.sectionTitle)
                            .foregroundColor(AppColors.textPrimary)

                        Spacer()

                        Button(action: { showAddCard = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(AppColors.ruby)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 12)
                }

                CardEditorFilterToolbar(
                    searchText: $viewModel.searchText,
                    deckFilter: $viewModel.deckFilter,
                    tierFilter: $viewModel.tierFilter,
                    playerFilter: $viewModel.playerFilter,
                    visibilityFilter: $viewModel.visibilityFilter,
                    qualityFilter: $viewModel.qualityFilter,
                    resultCount: viewModel.filteredCards.count,
                    onBulkHideHot: { viewModel.bulkSetTierHidden(.hot) },
                    onBulkShowAll: { viewModel.bulkSetActive(true, for: viewModel.cards) }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                ScrollView {
                    LazyVStack(spacing: 12) {
                        CardQualitySummaryPanel(
                            summary: viewModel.auditSummary,
                            activeFilter: viewModel.qualityFilter
                        )
                            .padding(.bottom, 2)

                        if viewModel.filteredCards.isEmpty {
                            Text("Bu filtrede kart yok.")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.top, 24)
                        }
                        ForEach(viewModel.filteredCards) { card in
                            CardRow(
                                card: card,
                                isFavorite: viewModel.isFavorite(card),
                                isHidden: viewModel.isHidden(card),
                                canDelete: viewModel.canDelete(card),
                                issues: viewModel.qualityIssues(for: card),
                                onToggle: {
                                    viewModel.toggleCardActive(card)
                                },
                                onToggleFavorite: {
                                    viewModel.toggleFavorite(card)
                                },
                                onPreview: {
                                    cardPendingPreview = card
                                },
                                onDelete: {
                                    cardPendingDelete = card
                                },
                                onEdit: card.isUserCard ? { cardPendingEdit = card } : nil
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showAddCard) {
            AddCardSheet { card in
                if viewModel.addCard(card) { showAddCard = false }
            }
            .alert("Kaydedilemedi", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("Tamam", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .sheet(item: $cardPendingEdit) { card in
            AddCardSheet(card: card) { updated in
                if viewModel.addCard(updated) { cardPendingEdit = nil }
            }
            .alert("Kaydedilemedi", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("Tamam", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .sheet(item: $cardPendingPreview) { card in
            CardPreviewSheet(
                card: card,
                issues: viewModel.qualityIssues(for: card)
            )
        }
        .confirmationDialog(
            "Bu kartı kalıcı olarak sil?",
            isPresented: Binding(
                get: { cardPendingDelete != nil },
                set: { if !$0 { cardPendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Sil", role: .destructive) {
                guard let card = cardPendingDelete else { return }
                if viewModel.deleteCard(card) {
                    HapticManager.shared.success()
                } else {
                    deleteErrorMessage = "Kart silinemedi."
                    HapticManager.shared.error()
                }
                cardPendingDelete = nil
            }
            Button("İptal", role: .cancel) {
                cardPendingDelete = nil
            }
        } message: {
            if let card = cardPendingDelete {
                Text(card.text)
            }
        }
        .alert("İşlem tamamlanamadı", isPresented: Binding(
            get: { !showAddCard && cardPendingEdit == nil && (deleteErrorMessage != nil || viewModel.errorMessage != nil) },
            set: { if !$0 { deleteErrorMessage = nil; viewModel.errorMessage = nil } }
        )) {
            Button("Tamam", role: .cancel) { deleteErrorMessage = nil; viewModel.errorMessage = nil }
        } message: {
            Text(deleteErrorMessage ?? viewModel.errorMessage ?? "")
        }
    }
}

struct CardQualitySummaryPanel: View {
    let summary: CardContentAuditSummary
    let activeFilter: CardQualityFilter

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: summary.issueCount == 0 ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(summary.issueCount == 0 ? AppColors.gold : AppColors.softRose)

                VStack(alignment: .leading, spacing: 3) {
                    Text("İçerik Kalitesi")
                        .font(AppTypography.button)
                        .foregroundColor(AppColors.textPrimary)
                    Text(summary.statusText)
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                qualityChip("Duplicate", summary.duplicateCount)
                qualityChip("Uzun", summary.longTextCount)
                qualityChip("Placeholder", summary.placeholderCount)
            }

            if activeFilter != .all {
                Text("Aktif filtre: \(activeFilter.displayName)")
                    .font(AppTypography.labelSmall)
                    .foregroundColor(AppColors.champagne)
            }
        }
        .padding(14)
        .ffGlassPanelStyle(cornerRadius: 16)
    }

    private func qualityChip(_ title: String, _ count: Int) -> some View {
        Text("\(title): \(count)")
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(count == 0 ? AppColors.textSecondary : AppColors.champagne)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(count == 0 ? AppColors.cardElevated : AppColors.ruby.opacity(0.18))
            .cornerRadius(10)
    }
}

struct CardEditorFilterToolbar: View {
    @Binding var searchText: String
    @Binding var deckFilter: CardDeckType?
    @Binding var tierFilter: ContentTier?
    @Binding var playerFilter: PlayerCountFilter
    @Binding var visibilityFilter: CardVisibilityFilter
    @Binding var qualityFilter: CardQualityFilter
    let resultCount: Int
    var onBulkHideHot: () -> Void
    var onBulkShowAll: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.textSecondary)

                TextField("Kart ara", text: $searchText)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(AppColors.backgroundDeep.opacity(0.55))
            .cornerRadius(12)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterMenu(
                        title: "Deste",
                        value: deckFilter?.displayName ?? "Tümü",
                        icon: "rectangle.stack.fill"
                    ) {
                        Button("Tümü") { deckFilter = nil }
                        Divider()
                        ForEach(DeckContentGroup.allCases) { group in
                            Section(group.rawValue) {
                                ForEach(group.deckTypes) { deck in
                                    Button(deck.displayName) { deckFilter = deck }
                                }
                            }
                        }
                    }

                    filterMenu(
                        title: "Seviye",
                        value: tierFilter?.displayName ?? "Tümü",
                        icon: "slider.horizontal.3"
                    ) {
                        Button("Tümü") { tierFilter = nil }
                        Divider()
                        ForEach(ContentTier.allCases) { tier in
                            Button(tier.displayName) { tierFilter = tier }
                        }
                    }

                    filterMenu(
                        title: "Oyuncu",
                        value: playerFilter.displayName,
                        icon: "person.2.fill"
                    ) {
                        ForEach(PlayerCountFilter.allCases) { option in
                            Button(option.displayName) { playerFilter = option }
                        }
                    }

                    filterMenu(
                        title: "Görünüm",
                        value: visibilityFilter.displayName,
                        icon: "eye.fill"
                    ) {
                        ForEach(CardVisibilityFilter.allCases) { option in
                            Button(option.displayName) { visibilityFilter = option }
                        }
                    }

                    filterMenu(
                        title: "Kalite",
                        value: qualityFilter.displayName,
                        icon: "checkmark.seal.fill"
                    ) {
                        ForEach(CardQualityFilter.allCases) { option in
                            Button(option.displayName) { qualityFilter = option }
                        }
                    }

                    Menu {
                        Button("Ateşli tier'ı gizle", action: onBulkHideHot)
                        Button("Tümünü göster", action: onBulkShowAll)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "square.stack.3d.down.right")
                            Text("Toplu")
                        }
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, 11)
                        .frame(height: 34)
                        .background(AppColors.cardElevated)
                        .cornerRadius(17)
                    }

                    Text("\(resultCount) kart")
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.softRose)
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(AppColors.ruby.opacity(0.14))
                        .cornerRadius(17)
                }
            }
        }
        .padding(12)
        .background(AppColors.cardDark)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.borderSoft, lineWidth: 1)
        )
    }

    private func filterMenu<Content: View>(
        title: String,
        value: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Menu {
            content()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text("\(title): \(value)")
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
            }
            .font(AppTypography.labelSmall)
            .foregroundColor(AppColors.textPrimary)
            .padding(.horizontal, 11)
            .frame(height: 34)
            .background(AppColors.cardElevated)
            .cornerRadius(17)
            .overlay(
                RoundedRectangle(cornerRadius: 17)
                    .stroke(AppColors.borderSoft, lineWidth: 1)
            )
        }
    }
}

struct CardRow: View {
    let card: GameCard
    var isFavorite: Bool = false
    var isHidden: Bool = false
    var canDelete: Bool = true
    var issues: [ContentAuditIssue] = []
    var onToggle: () -> Void
    var onToggleFavorite: () -> Void
    var onPreview: () -> Void
    var onDelete: () -> Void
    var onEdit: (() -> Void)? = nil

    private var isEffectivelyActive: Bool {
        card.isActive && !isHidden
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(card.title)
                        .font(AppTypography.button)
                        .foregroundColor(isEffectivelyActive ? AppColors.textPrimary : AppColors.textSecondary)
                    if isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundColor(AppColors.gold)
                    }
                    if isHidden {
                        Image(systemName: "eye.slash.fill")
                            .font(.system(size: 11))
                            .foregroundColor(AppColors.textMuted)
                    }
                }

                Text(card.text)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(card.phase.rawValue)
                    if let deck = card.deckType {
                        Text("•")
                        Text(deck.displayName)
                    }
                    ForEach(card.contentLabels.prefix(3)) { label in
                        Text("•")
                        Text(label.rawValue)
                            .foregroundColor(AppColors.softRose)
                    }
                }
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.textMuted)

                if !issues.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text("\(issues.count) kalite uyarısı")
                            .font(AppTypography.labelSmall)
                    }
                    .foregroundColor(AppColors.champagne)
                }
            }

            Spacer()

            VStack(spacing: 10) {
                if let onEdit {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .accessibilityLabel("Kartı düzenle")
                }
                Button(action: onPreview) {
                    Image(systemName: "eye.fill")
                        .foregroundColor(AppColors.textSecondary)
                }

                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(isFavorite ? AppColors.gold : AppColors.textSecondary)
                }

                Button(action: onToggle) {
                    Image(systemName: isEffectivelyActive ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isEffectivelyActive ? AppColors.ruby : AppColors.textMuted)
                }

                if canDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(AppColors.mutedRed)
                    }
                }
            }
        }
        .padding(16)
        .background(AppColors.cardDark)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.borderSoft, lineWidth: 1)
        )
    }
}

struct CardPreviewSheet: View {
    let card: GameCard
    let issues: [ContentAuditIssue]
    @Environment(\.dismiss) private var dismiss

    private var playerScope: CardPlayerScope {
        CardPlayerScope.from(minPlayers: card.minPlayers, maxPlayers: card.maxPlayers)
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundDeep.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(card.title)
                                .font(AppTypography.sectionTitle)
                                .foregroundColor(AppColors.textPrimary)
                            Text("\(card.effectiveDeckType.displayName) · \(card.phase.rawValue) · \(playerScope.displayName)")
                                .font(AppTypography.labelSmall)
                                .foregroundColor(AppColors.textSecondary)
                        }

                        CardPreviewMetadataPanel(card: card, playerScope: playerScope)

                        CardTextPreviewView(
                            rawText: card.text,
                            duration: card.durationSeconds,
                            phase: card.phase,
                            playerScope: .twoPlayers,
                            secondaryRawText: card.onYesTask,
                            itemName: card.requiredPropIds?.first.flatMap { PropCatalog.resolveProp(id: $0)?.name } ?? "kırbaç"
                        )

                        CardTextPreviewView(
                            rawText: card.text,
                            duration: card.durationSeconds,
                            phase: card.phase,
                            playerScope: .threePlayers,
                            secondaryRawText: card.onYesTask,
                            itemName: card.requiredPropIds?.first.flatMap { PropCatalog.resolveProp(id: $0)?.name } ?? "kırbaç"
                        )

                        if !issues.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("UYARILAR")
                                    .font(AppTypography.labelSmall)
                                    .foregroundColor(AppColors.textSecondary)
                                    .tracking(1.4)
                                ForEach(issues) { issue in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: issue.severity == .warning ? "exclamationmark.triangle.fill" : "info.circle.fill")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(issue.severity == .warning ? AppColors.champagne : AppColors.textSecondary)
                                        Text(issue.message)
                                            .font(AppTypography.labelSmall)
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                }
                            }
                            .padding(14)
                            .ffGlassPanelStyle(cornerRadius: 16)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Kart Önizleme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }
}

struct CardPreviewMetadataPanel: View {
    let card: GameCard
    let playerScope: CardPlayerScope

    private var propText: String {
        guard card.requiredPropIds?.isEmpty == false || card.propCategory != nil else {
            return "Yok"
        }
        let names = (card.requiredPropIds ?? [])
            .compactMap { PropCatalog.resolveProp(id: $0)?.name }
        if !names.isEmpty {
            return names.prefix(2).joined(separator: ", ")
        }
        return card.propCategory?.rawValue ?? "Eşya gerekli"
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            metaTile("Oyuncu", playerScope.displayName, icon: "person.2.fill")
            metaTile("Süre", card.hasTimedSurface ? "\(card.durationSeconds) sn" : "Süresiz", icon: "timer")
            metaTile("Yoğunluk", "\(card.intensity)", icon: "flame.fill")
            metaTile("Eşya", propText, icon: "bag.fill")
        }
    }

    private func metaTile(_ title: String, _ value: String, icon: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.champagne)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(AppTypography.labelSmall)
                    .foregroundColor(AppColors.textMuted)
                Text(value)
                    .font(AppTypography.labelSmall)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .ffGlassPanelStyle(cornerRadius: 14)
    }
}

struct AddCardSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var type: CardType = .question
    @State private var phase: GamePhase = .boldQuestion
    @State private var deckType: CardDeckType = .standard
    @State private var contentTier: ContentTier = .beginning
    @State private var playerScope: CardPlayerScope = .mixed
    @State private var intensity = 3
    @State private var duration = 30
    @State private var text = ""
    @State private var onYesTask = ""
    @State private var useItemPlaceholder = false
    @State private var propCategory: PropCategory = .hotStimulating

    private let originalCard: GameCard?
    var onAdd: (GameCard) -> Void

    init(card: GameCard? = nil, onAdd: @escaping (GameCard) -> Void) {
        originalCard = card
        self.onAdd = onAdd
        _title = State(initialValue: card?.title ?? "")
        _type = State(initialValue: card?.type ?? .question)
        _phase = State(initialValue: card?.phase ?? .boldQuestion)
        _deckType = State(initialValue: card?.effectiveDeckType ?? .standard)
        _contentTier = State(initialValue: card?.contentTier ?? .beginning)
        _playerScope = State(initialValue: CardPlayerScope.from(minPlayers: card?.minPlayers, maxPlayers: card?.maxPlayers))
        _intensity = State(initialValue: card?.intensity ?? 3)
        _duration = State(initialValue: card?.durationSeconds ?? 30)
        _text = State(initialValue: card?.text ?? "")
        _onYesTask = State(initialValue: card?.onYesTask ?? "")
        _useItemPlaceholder = State(initialValue: card?.propCategory != nil)
        _propCategory = State(initialValue: card?.propCategory ?? .hotStimulating)
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundDeep.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        FormField(title: "Kart Başlığı") {
                            TextField("Başlık", text: $title)
                                .textFieldStyle(CustomTextFieldStyle())
                        }

                        FormField(title: "Deste Türü") {
                            Picker("Deste", selection: $deckType) {
                                ForEach(DeckContentGroup.allCases) { group in
                                    Section(group.rawValue) {
                                        ForEach(group.deckTypes) { deck in
                                            Text(deck.displayName).tag(deck)
                                        }
                                    }
                                }
                            }
                            .pickerStyle(.menu)
                            .onChange(of: deckType) { _, newValue in
                                switch newValue {
                                case .neverHaveI, .hardTruth:
                                    type = .question
                                    phase = .boldQuestion
                                case .hardAction, .propTask:
                                    type = .task
                                    phase = .timedTask
                                case .fantasyRole:
                                    type = .roleDuo
                                    phase = .roleDuo
                                default:
                                    break
                                }
                            }
                        }

                        FormField(title: "Seviye") {
                            Picker("Seviye", selection: $contentTier) {
                                ForEach(ContentTier.allCases) { tier in
                                    Text(tier.displayName).tag(tier)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        CardPlayerScopePicker(scope: $playerScope)

                        FormField(title: "Faz") {
                            Picker("Faz", selection: $phase) {
                                ForEach(GamePhase.allCases) { p in
                                    Text(p.rawValue).tag(p)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        if deckType == .neverHaveI {
                            FormField(title: "Yaptıysan Görevi") {
                                TextEditor(text: $onYesTask)
                                    .frame(height: 80)
                                    .padding(8)
                                    .background(AppColors.cardDark)
                                    .cornerRadius(8)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                        }

                        Toggle(isOn: $useItemPlaceholder) {
                            Text("Metinde {item} eşya placeholder'ı kullan")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .tint(AppColors.ruby)

                        if useItemPlaceholder {
                            FormField(title: "Eşya Kategorisi") {
                                Picker("Kategori", selection: $propCategory) {
                                    ForEach(PropCategory.allCases) { cat in
                                        Section(cat.rawValue) {
                                            ForEach(cat.subcategories) { sub in
                                                Label(sub.rawValue, systemImage: sub.icon)
                                                    .tag(cat)
                                            }
                                        }
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }

                        FormField(title: "Yoğunluk (3-5)") {
                            Stepper("\(intensity)", value: $intensity, in: 3...5)
                                .foregroundColor(AppColors.textPrimary)
                        }

                        FormField(title: "Süre (saniye)") {
                            Stepper("\(duration)", value: $duration, in: 10...300, step: 5)
                                .foregroundColor(AppColors.textPrimary)
                        }

                        FormField(title: "Kart Metni") {
                            TextEditor(text: $text)
                                .frame(height: 120)
                                .padding(8)
                                .background(AppColors.cardDark)
                                .cornerRadius(8)
                                .foregroundColor(AppColors.textPrimary)
                        }

                        CardTextPreviewView(
                            rawText: text,
                            duration: duration,
                            phase: phase,
                            playerScope: playerScope,
                            secondaryRawText: deckType == .neverHaveI ? onYesTask : nil,
                            itemName: useItemPlaceholder ? "kırbaç" : nil
                        )

                        Text("İpuçları: {partner}, {partnere}, {partneri}, {diğer oyuncu}, {eşya}")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)

                        FFPrimaryButton(
                            title: "Kaydet",
                            action: {
                                var cardText = text
                                if useItemPlaceholder && !cardText.contains("{item}") {
                                    cardText += " ({item} kullan)"
                                }
                                let card = GameCard(
                                    title: title,
                                    type: type,
                                    phase: phase,
                                    intensity: intensity,
                                    minIntensity: contentTier.intensityLevel,
                                    maxIntensity: {
                                        switch contentTier {
                                        case .beginning: return IntensityLevel.medium
                                        case .medium: return IntensityLevel.hot
                                        case .hot: return IntensityLevel.hardcore
                                        }
                                    }(),
                                    durationSeconds: duration,
                                    targetRule: .randomOther,
                                    text: cardText,
                                    deckType: deckType == .standard ? nil : deckType,
                                    contentTier: contentTier,
                                    minPlayers: playerScope.minPlayers,
                                    maxPlayers: playerScope.maxPlayers,
                                    onYesTask: onYesTask.isEmpty ? nil : onYesTask,
                                    propCategory: useItemPlaceholder ? propCategory : nil,
                                    isUserAuthored: true
                                )
                                var updated = originalCard ?? card
                                updated.title = card.title.trimmingCharacters(in: .whitespacesAndNewlines)
                                updated.text = card.text.trimmingCharacters(in: .whitespacesAndNewlines)
                                updated.type = card.type
                                updated.phase = card.phase
                                updated.deckType = card.deckType
                                updated.contentTier = card.contentTier
                                updated.intensity = card.intensity
                                updated.minIntensity = card.minIntensity
                                updated.maxIntensity = card.maxIntensity
                                updated.durationSeconds = card.durationSeconds
                                if originalCard == nil || playerScope != CardPlayerScope.from(minPlayers: originalCard?.minPlayers, maxPlayers: originalCard?.maxPlayers) {
                                    updated.minPlayers = card.minPlayers
                                    updated.maxPlayers = card.maxPlayers
                                }
                                updated.onYesTask = card.onYesTask
                                updated.propCategory = card.propCategory
                                onAdd(updated)
                            },
                            isEnabled: !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )
                        .padding(.top, 20)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(originalCard == nil ? "Yeni Kart" : "Kartı Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }
}

struct FormField<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)

            content
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(AppTypography.body)
            .foregroundColor(AppColors.textPrimary)
            .padding()
            .background(AppColors.cardDark)
            .cornerRadius(12)
    }
}

#Preview {
    CardEditorView()
}

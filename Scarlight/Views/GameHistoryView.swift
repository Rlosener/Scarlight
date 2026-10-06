import SwiftUI
import UniformTypeIdentifiers

struct GameHistoryView: View {
    @EnvironmentObject private var appState: AppStateViewModel
    @State private var records: [PlayedSessionRecord] = []
    @State private var selectedRecord: PlayedSessionRecord?
    @State private var exportURL: URL?
    @State private var message: String?
    @State private var showImportHistory = false
    var onBack: (() -> Void)? = nil

    var body: some View {
        ZStack {
            FFBackground()

            VStack(spacing: 0) {
                if let onBack {
                    FFScreenHeader(title: "Oyun Geçmişi", onBack: onBack)
                        .padding(.bottom, 16)
                }

                if records.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            HistoryBackupPanel(
                                exportURL: exportURL,
                                onExport: exportHistory,
                                onImport: { showImportHistory = true }
                            )

                            ForEach(records) { record in
                                Button {
                                    selectedRecord = record
                                } label: {
                                    historyRow(record)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .onAppear { reload() }
        .sheet(item: $selectedRecord) { record in
            HistoryDetailView(record: record) {
                selectedRecord = nil
                appState.replayHistoryRecord(record)
            }
        }
        .fileImporter(
            isPresented: $showImportHistory,
            allowedContentTypes: [.json]
        ) { result in
            importHistory(result)
        }
        .alert("Geçmiş", isPresented: Binding(
            get: { message != nil },
            set: { if !$0 { message = nil } }
        )) {
            Button("Tamam", role: .cancel) { message = nil }
        } message: {
            Text(message ?? "")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 40))
                .foregroundColor(AppColors.textMuted)
            Text("Henüz kayıtlı oturum yok.")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)

            Button {
                showImportHistory = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down")
                    Text("Geçmiş İçe Aktar")
                }
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.champagne)
                .padding(.horizontal, 16)
                .frame(height: 42)
                .ffGlassPanelStyle(cornerRadius: 21)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private func historyRow(_ record: PlayedSessionRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.formattedDate)
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.softRose)
                    Text(record.contentProfile.displayName)
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.textMuted)
                }
                Spacer()
                Text(record.formattedDuration)
                    .font(AppTypography.labelSmall)
                    .foregroundColor(AppColors.textSecondary)
            }

            Text(record.playerNames.joined(separator: ", "))
                .font(AppTypography.button)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            HStack(spacing: 8) {
                statChip("\(record.totalTurns) tur")
                statChip(record.finalIntensity.displayName(for: record.contentProfile))
                statChip("\(record.passCount) pas")
                statChip("\(record.jokersUsed) joker")
            }
        }
        .padding(16)
        .ffGlassPanelStyle(cornerRadius: 16)
    }

    private func statChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(AppColors.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppColors.cardElevated)
            .cornerRadius(8)
    }

    private func reload() {
        records = PlayedHistoryStore.load()
    }

    private func exportHistory() {
        do {
            exportURL = try LocalJSONStore.shared.exportData(records)
            message = "Geçmiş yedeği hazır."
            HapticManager.shared.success()
        } catch {
            message = "Geçmiş dışa aktarılamadı: \(error.localizedDescription)"
        }
    }

    private func importHistory(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            do {
                let imported = try LocalJSONStore.shared.importData(from: url, as: [PlayedSessionRecord].self)
                PlayedHistoryStore.replace(imported)
                reload()
                message = "\(imported.count) oturum içe aktarıldı."
                HapticManager.shared.success()
            } catch {
                message = "Geçmiş içe aktarılamadı: \(error.localizedDescription)"
            }
        case .failure(let error):
            message = "Dosya seçimi tamamlanamadı: \(error.localizedDescription)"
        }
    }
}

struct HistoryBackupPanel: View {
    let exportURL: URL?
    let onExport: () -> Void
    let onImport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "archivebox.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.champagne)
                    .frame(width: 40, height: 40)
                    .background(AppColors.ruby.opacity(0.18))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Geçmiş Yedeği")
                        .font(AppTypography.button)
                        .foregroundColor(AppColors.textPrimary)
                    Text("Oturum kayıtlarını ayrı JSON olarak taşı.")
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
            }

            HStack(spacing: 10) {
                Button(action: onExport) {
                    Label("Dışa Aktar", systemImage: "square.and.arrow.up")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(AppColors.ruby)
                        .cornerRadius(12)
                }

                Button(action: onImport) {
                    Label("İçe Aktar", systemImage: "square.and.arrow.down")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.softRose)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(AppColors.cardElevated)
                        .cornerRadius(12)
                }
            }

            if let exportURL {
                ShareLink(item: exportURL) {
                    Label("Hazır yedeği paylaş", systemImage: "paperplane.fill")
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.champagne)
                }
            }
        }
        .padding(16)
        .ffGlassPanelStyle(cornerRadius: 18)
    }
}

struct HistoryDetailView: View {
    let record: PlayedSessionRecord
    var onReplay: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundDeep.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        detailHeader
                        statGrid
                        if record.canReplay {
                            replayButton
                        }
                        listSection(title: "Oyuncular", values: record.playerNames)
                        listSection(title: "Fazlar", values: record.phaseNames)
                        listSection(title: "Desteler", values: record.enabledDeckNames)
                        listSection(title: "Eşyalar", values: record.selectedPropNames)
                        if !record.playerStats.isEmpty {
                            playerStatsSection
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Oturum Detayı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }

    private var detailHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(record.contentProfile.displayName)
                .font(AppTypography.sectionTitle)
                .foregroundColor(AppColors.textPrimary)
            Text(record.formattedDate)
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.textSecondary)
        }
    }

    private var statGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            detailStat("Süre", record.formattedDuration)
            detailStat("Tur", "\(record.totalTurns)")
            detailStat("Yoğunluk", record.finalIntensity.displayName(for: record.contentProfile))
            detailStat("Döngü", "\(record.completedCycles)")
            detailStat("Pas", "\(record.passCount)")
            detailStat("Ceza", "\(record.penaltyCount)")
            detailStat("Joker", "\(record.jokersUsed)")
            detailStat("Deste", "\(record.enabledDeckCount)")
        }
    }

    private var replayButton: some View {
        Button {
            dismiss()
            onReplay?()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "arrow.clockwise.circle.fill")
                Text("Aynı Kurulumla Yeniden Başlat")
                Spacer()
                Image(systemName: "play.fill")
                    .font(.system(size: 12, weight: .bold))
            }
            .font(AppTypography.button)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(AppColors.heroGradient)
            .cornerRadius(18)
        }
    }

    private func detailStat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased())
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.textSecondary)
            Text(value)
                .font(AppTypography.button)
                .foregroundColor(AppColors.champagne)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .ffGlassPanelStyle(cornerRadius: 14)
    }

    @ViewBuilder
    private func listSection(title: String, values: [String]) -> some View {
        if !values.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(title.uppercased())
                    .font(AppTypography.labelSmall)
                    .foregroundColor(AppColors.textSecondary)
                    .tracking(1.2)
                FlowLayout(spacing: 8) {
                    ForEach(values, id: \.self) { value in
                        Text(value)
                            .font(AppTypography.labelSmall)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppColors.cardElevated)
                            .cornerRadius(12)
                    }
                }
            }
        }
    }

    private var playerStatsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("OYUNCU İSTATİSTİKLERİ")
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.textSecondary)
                .tracking(1.2)

            ForEach(record.playerStats) { stat in
                HStack {
                    Text(stat.name)
                        .font(AppTypography.button)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Text("\(stat.turnCount) tur")
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.textSecondary)
                    Text("\(stat.jokersRemaining) joker")
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.champagne)
                }
                .padding(14)
                .ffGlassPanelStyle(cornerRadius: 14)
            }
        }
    }
}

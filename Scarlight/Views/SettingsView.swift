import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var playerVM: PlayerSetupViewModel
    @EnvironmentObject private var appState: AppStateViewModel
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showCardEditor = false
    @State private var showPenaltyEditor = false
    @State private var showExportCards = false
    @State private var showImportCards = false
    @State private var showExportPenalties = false
    @State private var showImportPenalties = false
    @State private var showImportFullBackup = false
    @State private var pendingBackup: LocalBackupPackage?
    @State private var lastExportURL: URL?
    @State private var lastExportTitle: String?
    @State private var lastBackupStatus = LocalBackupActivityStore.statusText
    @State private var lastImportReport: LocalBackupImportReport?
    @StateObject private var cardEditorVM = CardEditorViewModel()
    @State private var resyncMessage: String?
    @State private var dataMessage: String?
    @State private var timerDefaults = TimerDefaultsStore.load()
    @AppStorage(PerformanceDefaults.performanceModeKey) private var isPerformanceModeEnabled = true
    @Environment(\.dismiss) private var dismiss
    var onBack: (() -> Void)? = nil

    var body: some View {
        ZStack {
            FFBackground()

            ScrollView {
                VStack(spacing: 0) {
                    if let onBack {
                        FFScreenHeader(title: "Ayarlar", onBack: onBack)
                            .padding(.bottom, 16)
                    } else {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(AppColors.textSecondary)
                            }

                            Spacer()

                            Text("Ayarlar")
                                .font(AppTypography.sectionTitle)
                                .foregroundColor(AppColors.textPrimary)

                            Spacer()

                            Color.clear
                                .frame(width: 28, height: 28)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 32)
                    }

                    VStack(spacing: 20) {
                        SettingsSection(title: "Oyun") {
                            SettingsToggle(
                                title: "Haptic Feedback",
                                isOn: $viewModel.isHapticEnabled,
                                action: { viewModel.setHapticEnabled($0) }
                            )

                            SettingsToggle(
                                title: "Ses Efektleri",
                                isOn: $viewModel.isSoundEnabled,
                                action: { viewModel.setSoundEnabled($0) }
                            )

                            SettingsToggle(
                                title: "Performans Modu",
                                isOn: $isPerformanceModeEnabled,
                                action: { _ in HapticManager.shared.selection() }
                            )

                            TimerDefaultsPanel(defaults: $timerDefaults)
                        }

                        SettingsSection(title: "İçerik") {
                            DeckStatsPanel(stats: cardEditorVM.deckStats, total: cardEditorVM.cards.filter(\.isActive).count)

                            SettingsButton(title: "Kartları Düzenle", icon: "rectangle.stack.fill") {
                                showCardEditor = true
                            }

                            SettingsButton(title: "Cezaları Düzenle", icon: "exclamationmark.triangle.fill") {
                                showPenaltyEditor = true
                            }

                            SettingsButton(title: "Deste Kartlarını Yenile", icon: "arrow.clockwise.circle.fill") {
                                resyncDeckPacks()
                            }
                        }

                        SettingsSection(title: "Veri") {
                            LocalBackupPanel(
                                exportURL: lastExportURL,
                                exportTitle: lastExportTitle,
                                onExport: {
                                    exportFullBackup()
                                }
                            )

                            SettingsButton(title: "Tam Yedeği İçe Aktar", icon: "externaldrive.badge.plus") {
                                showImportFullBackup = true
                            }

                            if let lastImportReport {
                                BackupImportReportPanel(report: lastImportReport)
                            }

                            SettingsButton(title: "Kartları Dışa Aktar", icon: "square.and.arrow.up") {
                                exportCards()
                            }

                            SettingsButton(title: "Kartları İçe Aktar", icon: "square.and.arrow.down") {
                                showImportCards = true
                            }

                            SettingsButton(title: "Cezaları Dışa Aktar", icon: "square.and.arrow.up") {
                                exportPenalties()
                            }

                            SettingsButton(title: "Cezaları İçe Aktar", icon: "square.and.arrow.down") {
                                showImportPenalties = true
                            }
                        }

                        SettingsSection(title: "QA") {
                            QAStatusPanel(
                                auditSummary: cardEditorVM.auditSummary,
                                historyCount: PlayedHistoryStore.load().count,
                                presetCount: SessionPresetStore.allPresets().count,
                                hasSavedSession: appState.restorableSnapshot != nil,
                                lastExportURL: lastExportURL,
                                lastBackupStatus: lastBackupStatus
                            )
                        }

                        SettingsSection(title: "Sıfırla") {
                            SettingsButton(title: "Kayıtlı Oturumu Sil", icon: "xmark.circle", color: AppColors.mutedRed) {
                                viewModel.clearSavedGameSession()
                                appState.refreshRestorableSession()
                            }

                            SettingsButton(title: "Oyun Geçmişini Sıfırla", icon: "trash", color: AppColors.mutedRed) {
                                viewModel.resetGameHistory()
                            }

                            SettingsButton(title: "Kart Tercihlerini Sıfırla", icon: "star.slash", color: AppColors.mutedRed) {
                                viewModel.resetCardHistory()
                            }

                            SettingsButton(title: "Rehberi Tekrar Göster", icon: "book.fill", color: AppColors.textSecondary) {
                                OnboardingStore.reset()
                            }

                            SettingsButton(title: "18+ Onayını Sıfırla", icon: "arrow.counterclockwise", color: AppColors.mutedRed) {
                                appState.resetConsent()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showCardEditor) {
            CardEditorView()
        }
        .sheet(isPresented: $showPenaltyEditor) {
            PenaltyEditorView()
        }
        .fileImporter(
            isPresented: $showImportCards,
            allowedContentTypes: [.json]
        ) { result in
            handleImportCards(result)
        }
        .fileImporter(
            isPresented: $showImportPenalties,
            allowedContentTypes: [.json]
        ) { result in
            handleImportPenalties(result)
        }
        .fileImporter(
            isPresented: $showImportFullBackup,
            allowedContentTypes: [.json]
        ) { result in
            handleImportFullBackup(result)
        }
        .confirmationDialog("Yedek geri yüklensin mi?", isPresented: Binding(
            get: { pendingBackup != nil },
            set: { if !$0 { pendingBackup = nil } }
        ), titleVisibility: .visible) {
            Button("Yedeği Geri Yükle", role: .destructive) {
                if let package = pendingBackup { restoreBackup(package) }
                pendingBackup = nil
            }
            Button("İptal", role: .cancel) { pendingBackup = nil }
        } message: {
            Text("\(pendingBackup?.restoreSummary ?? ""). Yedekteki veriler bu cihazdaki karşılıklarının yerine geçecek.")
        }
        .onAppear {
            cardEditorVM.loadCards()
            appState.refreshRestorableSession()
        }
        .alert("Deste Güncellendi", isPresented: Binding(
            get: { resyncMessage != nil },
            set: { if !$0 { resyncMessage = nil } }
        )) {
            Button("Tamam", role: .cancel) { resyncMessage = nil }
        } message: {
            Text(resyncMessage ?? "")
        }
        .alert("Veri İşlemi", isPresented: Binding(
            get: { dataMessage != nil },
            set: { if !$0 { dataMessage = nil } }
        )) {
            Button("Tamam", role: .cancel) { dataMessage = nil }
        } message: {
            Text(dataMessage ?? "")
        }
    }

    private func resyncDeckPacks() {
        cardEditorVM.loadCards()
        let total = cardEditorVM.cards.filter(\.isActive).count
        let packCount = DeckPackLoader.bundledPackCards().count
        resyncMessage = "\(total) kart hazır (\(packCount) deste kartı bundle'dan)."
        HapticManager.shared.success()
    }

    private func exportCards() {
        do {
            let url = try viewModel.exportCards()
            lastExportURL = url
            lastExportTitle = "Kart yedeği hazır"
            showExportCards = true
        } catch {
            dataMessage = "Kart yedeği oluşturulamadı: \(error.localizedDescription)"
            print("Export failed: \(error)")
        }
    }

    private func exportFullBackup() {
        do {
            let url = try viewModel.exportFullBackup()
            lastExportURL = url
            lastExportTitle = "Tam yerel yedek hazır"
            lastBackupStatus = LocalBackupActivityStore.statusText
            dataMessage = "Yedek hazır. Paylaş butonu ile dışa aktarabilirsin."
            HapticManager.shared.success()
        } catch {
            dataMessage = "Tam yedek oluşturulamadı: \(error.localizedDescription)"
            print("Full backup export failed: \(error)")
        }
    }

    private func exportPenalties() {
        do {
            let url = try viewModel.exportPenalties()
            lastExportURL = url
            lastExportTitle = "Ceza yedeği hazır"
            showExportPenalties = true
        } catch {
            dataMessage = "Ceza yedeği oluşturulamadı: \(error.localizedDescription)"
            print("Export failed: \(error)")
        }
    }

    private func handleImportCards(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            do {
                try viewModel.importCards(from: url)
                cardEditorVM.loadCards()
                dataMessage = "Kartlar içe aktarıldı."
            } catch {
                dataMessage = "Kartlar içe aktarılamadı: \(error.localizedDescription)"
                print("Import failed: \(error)")
            }
        case .failure(let error):
            dataMessage = "Dosya seçimi tamamlanamadı: \(error.localizedDescription)"
            print("File selection failed: \(error)")
        }
    }

    private func handleImportPenalties(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            do {
                try viewModel.importPenalties(from: url)
                dataMessage = "Cezalar içe aktarıldı."
            } catch {
                dataMessage = "Cezalar içe aktarılamadı: \(error.localizedDescription)"
                print("Import failed: \(error)")
            }
        case .failure(let error):
            dataMessage = "Dosya seçimi tamamlanamadı: \(error.localizedDescription)"
            print("File selection failed: \(error)")
        }
    }

    private func handleImportFullBackup(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            do {
                pendingBackup = try ExportImportService.shared.previewFullBackup(from: url)
            } catch {
                dataMessage = "Tam yedek içe aktarılamadı: \(error.localizedDescription)"
                print("Full backup import failed: \(error)")
            }
        case .failure(let error):
            dataMessage = "Dosya seçimi tamamlanamadı: \(error.localizedDescription)"
            print("File selection failed: \(error)")
        }
    }
    private func restoreBackup(_ package: LocalBackupPackage) {
        do {
            let result = try ExportImportService.shared.restoreFullBackup(package)
            lastImportReport = result.report
            cardEditorVM.loadCards()
            timerDefaults = package.timerDefaults
            appState.reloadSessionConfigFromStore()
            playerVM.loadPlayers()
            lastBackupStatus = LocalBackupActivityStore.statusText
            dataMessage = result.report.summaryText
            HapticManager.shared.success()
        } catch {
            dataMessage = "Tam yedek içe aktarılamadı: \(error.localizedDescription)"
        }
    }

}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.textSecondary)
                .tracking(1)
                .padding(.leading, 4)

            VStack(spacing: 1) {
                content
            }
            .background(AppColors.cardDark)
            .cornerRadius(16)
        }
    }
}

struct SettingsToggle: View {
    let title: String
    @Binding var isOn: Bool
    let action: (Bool) -> Void

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
        }
        .tint(AppColors.ruby)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .onChange(of: isOn) { _, newValue in
            action(newValue)
        }
    }
}

struct DeckStatsPanel: View {
    let stats: [(CardDeckType, Int)]
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Deste Özeti")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("\(total) kart")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.softRose)
            }

            ForEach(DeckContentGroup.playableGroups) { group in
                let groupStats = stats.filter { group.deckTypes.contains($0.0) && $0.1 > 0 }
                if !groupStats.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: group.icon)
                                .font(.system(size: 11))
                                .foregroundColor(AppColors.softRose)
                            Text(group.rawValue)
                                .font(AppTypography.labelSmall)
                                .foregroundColor(AppColors.champagne)
                        }

                        ForEach(groupStats, id: \.0) { deck, count in
                            HStack {
                                Text(deck.displayName)
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                Spacer()
                                Text("\(count)")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct LocalBackupPanel: View {
    let exportURL: URL?
    let exportTitle: String?
    let onExport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "externaldrive.badge.checkmark")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(AppColors.ruby.opacity(0.24))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Yerel Yedek")
                        .font(AppTypography.button)
                        .foregroundColor(AppColors.textPrimary)
                    Text(exportTitle ?? "Kartlar, geçmiş, preset ve ayarları tek JSON olarak dışa aktar")
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)
            }

            HStack(spacing: 10) {
                Button(action: onExport) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up.fill")
                        Text("Yedek Al")
                    }
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(AppColors.ruby)
                    .cornerRadius(12)
                }

                if let exportURL {
                    ShareLink(item: exportURL) {
                        HStack(spacing: 8) {
                            Image(systemName: "paperplane.fill")
                            Text("Paylaş")
                        }
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.softRose)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(AppColors.cardElevated)
                        .cornerRadius(12)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppColors.ruby.opacity(0.1))
    }
}

struct BackupImportReportPanel: View {
    let report: LocalBackupImportReport

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: report.warnings.isEmpty ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(report.warnings.isEmpty ? AppColors.gold : AppColors.champagne)
                Text("Son İçe Aktarma")
                    .font(AppTypography.button)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("v\(report.packageVersion)")
                    .font(AppTypography.labelSmall)
                    .foregroundColor(AppColors.textMuted)
            }

            Text(report.summaryText)
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if !report.warnings.isEmpty {
                ForEach(report.warnings, id: \.self) { warning in
                    Text("• \(warning)")
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.champagne)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppColors.cardElevated.opacity(0.55))
    }
}

struct QAStatusPanel: View {
    let auditSummary: CardContentAuditSummary
    let historyCount: Int
    let presetCount: Int
    let hasSavedSession: Bool
    let lastExportURL: URL?
    let lastBackupStatus: String

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            qaRow("Sürüm", "\(appVersion) (\(buildNumber))", icon: "app.badge")
            qaRow("Kart Kalitesi", auditSummary.statusText, icon: auditSummary.issueCount == 0 ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
            qaRow("Geçmiş", "\(historyCount) oturum", icon: "clock.arrow.circlepath")
            qaRow("Preset", "\(presetCount) kurulum", icon: "slider.horizontal.3")
            qaRow("Restore", hasSavedSession ? "Kayıt var" : "Temiz", icon: hasSavedSession ? "play.circle.fill" : "checkmark.circle")
            qaRow("Son Yedek", lastBackupStatus, icon: lastExportURL == nil ? "externaldrive" : "externaldrive.fill")
            qaRow("Pre-release", "Scripts/pre_release_check.sh", icon: "checklist")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func qaRow(_ title: String, _ value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(AppColors.softRose)
                .frame(width: 22)
            Text(title)
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct SettingsButton: View {
    let title: String
    let icon: String
    var color: Color = AppColors.textPrimary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                    .frame(width: 24)

                Text(title)
                    .font(AppTypography.body)
                    .foregroundColor(color)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

struct TimerDefaultsPanel: View {
    @Binding var defaults: TimerDefaults

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Varsayılan süreler (sn)")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)

            stepperRow("Başlangıç", value: $defaults.beginningSeconds, range: 15...120)
            stepperRow("Orta", value: $defaults.mediumSeconds, range: 20...180)
            stepperRow("Ateşli", value: $defaults.hotSeconds, range: 30...240)
            stepperRow("Ceza tabanı", value: $defaults.penaltyFloorSeconds, range: 15...120)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onChange(of: defaults) { _, newValue in
            TimerDefaultsStore.save(newValue)
        }
    }

    private func stepperRow(_ title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack {
            Text(title)
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Stepper("\(value.wrappedValue)", value: value, in: range)
                .foregroundColor(AppColors.champagne)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppStateViewModel())
}

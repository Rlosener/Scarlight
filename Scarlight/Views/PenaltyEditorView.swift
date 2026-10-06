import SwiftUI
import Combine

struct PenaltyEditorView: View {
    @StateObject private var viewModel = PenaltyEditorViewModel()
    @State private var showAddPenalty = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            FFBackground()

            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(AppColors.textSecondary)
                    }

                    Spacer()

                    Text("Ceza Editörü")
                        .font(AppTypography.sectionTitle)
                        .foregroundColor(AppColors.textPrimary)

                    Spacer()

                    Button(action: { showAddPenalty = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(AppColors.ruby)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.penalties) { penalty in
                            PenaltyRow(penalty: penalty) {
                                viewModel.togglePenaltyActive(penalty)
                            } onDelete: {
                                viewModel.deletePenalty(penalty)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showAddPenalty) {
            AddPenaltySheet { penalty in
                viewModel.addPenalty(penalty)
                showAddPenalty = false
            }
        }
    }
}

struct PenaltyRow: View {
    let penalty: PenaltyCard
    var onToggle: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(penalty.title)
                    .font(AppTypography.button)
                    .foregroundColor(penalty.isActive ? AppColors.textPrimary : AppColors.textSecondary)

                Text(penalty.type.rawValue)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.ruby)

                Text("Yoğunluk: \(penalty.intensity) • \(penalty.durationSeconds)s")
                    .font(AppTypography.labelSmall)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            Button(action: onToggle) {
                Image(systemName: penalty.isActive ? "eye.fill" : "eye.slash.fill")
                    .foregroundColor(penalty.isActive ? AppColors.ruby : AppColors.textSecondary)
            }

            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .foregroundColor(AppColors.mutedRed)
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

struct AddPenaltySheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var type: PenaltyType = .related
    @State private var category: CardType = .question
    @State private var intensity = 3
    @State private var duration = 30
    @State private var text = ""

    var onAdd: (PenaltyCard) -> Void

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundDeep.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        FormField(title: "Ceza Başlığı") {
                            TextField("Başlık", text: $title)
                                .textFieldStyle(CustomTextFieldStyle())
                        }

                        FormField(title: "Ceza Tipi") {
                            Picker("Tip", selection: $type) {
                                ForEach(PenaltyType.allCases) { t in
                                    Text(t.rawValue).tag(t)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        FormField(title: "Yoğunluk (3-5)") {
                            Stepper("\(intensity)", value: $intensity, in: 3...5)
                                .foregroundColor(AppColors.textPrimary)
                        }

                        FormField(title: "Süre (saniye)") {
                            Stepper("\(duration)", value: $duration, in: 10...300, step: 5)
                                .foregroundColor(AppColors.textPrimary)
                        }

                        FormField(title: "Ceza Metni") {
                            TextEditor(text: $text)
                                .frame(height: 120)
                                .padding(8)
                                .background(AppColors.cardDark)
                                .cornerRadius(8)
                                .foregroundColor(AppColors.textPrimary)
                        }

                        Text("İpuçları: {partner}, {partnere}, {partneri}")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)

                        FFPrimaryButton(
                            title: "Kaydet",
                            action: {
                                let penalty = PenaltyCard(
                                    title: title,
                                    type: type,
                                    relatedCategory: category,
                                    intensity: intensity,
                                    durationSeconds: duration,
                                    text: text
                                )
                                onAdd(penalty)
                            },
                            isEnabled: !title.isEmpty && !text.isEmpty
                        )
                        .padding(.top, 20)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Yeni Ceza")
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

class PenaltyEditorViewModel: ObservableObject {
    @Published var penalties: [PenaltyCard] = []
    private let store = LocalJSONStore.shared
    private let filename = "penalties.json"

    init() {
        loadPenalties()
    }

    func loadPenalties() {
        if store.fileExists(filename) {
            do {
                penalties = try store.load(from: filename, as: [PenaltyCard].self)
            } catch {
                print("Failed to load penalties: \(error)")
                penalties = PenaltyCatalog.loadForGameplay()
            }
        } else {
            penalties = PenaltyCatalog.loadForGameplay()
        }
    }

    func savePenalties() {
        do {
            try store.save(penalties, to: filename)
        } catch {
            print("Failed to save penalties: \(error)")
        }
    }

    func addPenalty(_ penalty: PenaltyCard) {
        penalties.append(penalty)
        savePenalties()
    }

    func updatePenalty(_ penalty: PenaltyCard) {
        if let index = penalties.firstIndex(where: { $0.id == penalty.id }) {
            penalties[index] = penalty
            savePenalties()
        }
    }

    func deletePenalty(_ penalty: PenaltyCard) {
        penalties.removeAll { $0.id == penalty.id }
        savePenalties()
    }

    func togglePenaltyActive(_ penalty: PenaltyCard) {
        if let index = penalties.firstIndex(where: { $0.id == penalty.id }) {
            penalties[index].isActive.toggle()
            savePenalties()
        }
    }
}

#Preview {
    PenaltyEditorView()
}

import SwiftUI

struct CustomPropsView: View {
    @State private var userProps: [UserProp] = []
    @State private var newName = ""
    @State private var newSubcategory: PropSubcategory = .sensory
    var onBack: (() -> Void)? = nil

    var body: some View {
        ZStack {
            FFBackground()

            VStack(spacing: 0) {
                if let onBack {
                    FFScreenHeader(title: "Özel Eşyalar", onBack: onBack)
                        .padding(.bottom, 16)
                }

                ScrollView {
                    VStack(spacing: 20) {
                        addSection

                        if userProps.isEmpty {
                            Text("Kendi eşyalarını ekle; eşya seçiminde ve hazırlık listesinde görünür.")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(userProps) { prop in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(prop.name)
                                                .font(AppTypography.button)
                                                .foregroundColor(AppColors.textPrimary)
                                            Text(prop.subcategory.rawValue)
                                                .font(AppTypography.labelSmall)
                                                .foregroundColor(AppColors.textSecondary)
                                        }
                                        Spacer()
                                        Button(role: .destructive) {
                                            UserPropStore.delete(id: prop.id)
                                            reload()
                                        } label: {
                                            Image(systemName: "trash")
                                                .foregroundColor(AppColors.mutedRed)
                                        }
                                    }
                                    .padding(14)
                                    .ffGlassPanelStyle(cornerRadius: 14)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear(perform: reload)
    }

    private var addSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("YENİ EŞYA")
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.textSecondary)
                .tracking(2)

            TextField("Eşya adı", text: $newName)
                .padding(12)
                .background(AppColors.cardDark)
                .cornerRadius(12)
                .foregroundColor(AppColors.textPrimary)

            Picker("Kategori", selection: $newSubcategory) {
                ForEach(PropSubcategory.allCases) { sub in
                    Text(sub.rawValue).tag(sub)
                }
            }
            .pickerStyle(.menu)

            FFPrimaryButton(title: "Ekle", action: addProp, isEnabled: !newName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(16)
        .background(AppColors.cardDark.opacity(0.6))
        .cornerRadius(20)
        .padding(.horizontal, 20)
    }

    private func addProp() {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        _ = UserPropStore.add(name: name, subcategory: newSubcategory)
        newName = ""
        reload()
        HapticManager.shared.success()
    }

    private func reload() {
        userProps = UserPropStore.load()
    }
}

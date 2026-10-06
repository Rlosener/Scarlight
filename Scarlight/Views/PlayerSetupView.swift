import SwiftUI

enum PlayerSetupMode {
    case playFlow
    case manage

    var title: String {
        switch self {
        case .playFlow: return "Kimler Oynuyor?"
        case .manage: return "Kişiler"
        }
    }

    var subtitle: String {
        switch self {
        case .playFlow: return "En az 2 oyuncu ekle, ardından eşya ve desteleri seç."
        case .manage: return "Oyuncuları ekle, düzenle veya kaldır."
        }
    }

    var actionTitle: String? {
        switch self {
        case .playFlow: return "Devam"
        case .manage: return nil
        }
    }
}

struct PlayerSetupView: View {
    @EnvironmentObject private var viewModel: PlayerSetupViewModel
    @State private var showAddPlayer = false
    @State private var playerPendingDelete: Player?
    @State private var playerPendingEdit: Player?

    let mode: PlayerSetupMode
    var onBack: (() -> Void)? = nil
    var onContinue: (([Player]) -> Void)? = nil

    var body: some View {
        ZStack {
            FFBackground()

            VStack(spacing: 24) {
                if let onBack {
                    FFScreenHeader(title: mode.title, onBack: onBack)
                }

                VStack(spacing: 8) {
                    if onBack == nil {
                        Text(mode.title)
                            .font(AppTypography.sectionTitle)
                            .foregroundColor(AppColors.textPrimary)
                    }

                    Text(mode.subtitle)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, onBack == nil ? 20 : 0)

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.players) { player in
                            PlayerCard(player: player, onEdit: {
                                playerPendingEdit = player
                            }, onDelete: {
                                playerPendingDelete = player
                            })
                        }

                        Button(action: { showAddPlayer = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                Text("Oyuncu Ekle")
                                    .font(AppTypography.button)
                            }
                            .foregroundColor(AppColors.ruby)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(AppColors.cardDark)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(AppColors.borderSoft, lineWidth: 1)
                            )
                        }

                        if viewModel.showsPartnerPairing {
                            PartnerPairingSection(viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                if let actionTitle = mode.actionTitle, let onContinue {
                    FFPrimaryButton(
                        title: actionTitle,
                        action: {
                            HapticManager.shared.success()
                            onContinue(viewModel.activePlayers)
                        },
                        isEnabled: viewModel.canStartGame
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                } else {
                    Spacer(minLength: 0)
                        .frame(height: 24)
                }
            }
        }
        .sheet(isPresented: $showAddPlayer) {
            AddPlayerSheet(errorMessage: $viewModel.errorMessage, onAdd: { name, gender, role in
                if viewModel.addPlayer(name: name, gender: gender, role: role) {
                    showAddPlayer = false
                }
            })
        }
        .sheet(item: $playerPendingEdit) { player in
            AddPlayerSheet(player: player, errorMessage: $viewModel.errorMessage) { name, gender, role in
                var updated = player
                updated.name = name
                updated.gender = gender
                updated.role = role
                if viewModel.updatePlayer(updated) { playerPendingEdit = nil }
            }
        }
        .confirmationDialog("Oyuncu kaldırılsın mı?", isPresented: Binding(
            get: { playerPendingDelete != nil },
            set: { if !$0 { playerPendingDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Kaldır", role: .destructive) {
                if let player = playerPendingDelete { viewModel.removePlayer(player) }
                playerPendingDelete = nil
            }
            Button("İptal", role: .cancel) { playerPendingDelete = nil }
        }
        .alert("İşlem tamamlanamadı", isPresented: Binding(
            get: { !showAddPlayer && playerPendingEdit == nil && viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("Tamam", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

struct PlayerCard: View {
    let player: Player
    var onEdit: (() -> Void)? = nil
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(player.color)
                .frame(width: 16, height: 16)

            VStack(alignment: .leading, spacing: 4) {
                Text(player.name)
                    .font(AppTypography.playerName)
                    .foregroundColor(AppColors.textPrimary)

                HStack(spacing: 12) {
                    Text(player.gender.rawValue)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    Text("•")
                        .foregroundColor(AppColors.textSecondary)

                    Text(player.role.rawValue)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Spacer()

            if let onEdit {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Oyuncuyu düzenle")
            }
            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .foregroundColor(AppColors.mutedRed)
                    .font(.system(size: 18))
            }
        }
        .padding(20)
        .background(AppColors.cardElevated)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppColors.borderSoft, lineWidth: 1)
        )
    }
}

struct PartnerPairingSection: View {
    @ObservedObject var viewModel: PlayerSetupViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PARTNER ÇİFTİ")
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.textSecondary)
                .tracking(1.2)

            Text("3 kişide kartlardaki partner kime denk gelir? Üçüncü kişi otomatik “diğer oyuncu” olur.")
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.textSecondary)

            ForEach(viewModel.partnerPairOptions, id: \.self) { pair in
                Button {
                    HapticManager.shared.selection()
                    viewModel.selectPartnerPair(pair)
                } label: {
                    HStack {
                        Text(viewModel.partnerPairLabel(for: pair))
                            .font(AppTypography.button)
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        if viewModel.isPartnerPairSelected(pair) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppColors.ruby)
                        }
                    }
                    .padding(14)
                    .background(
                        viewModel.isPartnerPairSelected(pair)
                            ? AppColors.ruby.opacity(0.18)
                            : AppColors.cardDark
                    )
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                viewModel.isPartnerPairSelected(pair)
                                    ? AppColors.ruby.opacity(0.45)
                                    : AppColors.borderSoft,
                                lineWidth: 1
                            )
                    )
                }
            }
        }
        .padding(16)
        .background(AppColors.cardDark.opacity(0.5))
        .cornerRadius(20)
    }
}

struct AddPlayerSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var gender: Gender = .female
    @State private var role: PlayerRole = .mixed

    @Binding var errorMessage: String?
    private let isEditing: Bool
    var onAdd: (String, Gender, PlayerRole) -> Void

    init(player: Player? = nil, errorMessage: Binding<String?> = .constant(nil), onAdd: @escaping (String, Gender, PlayerRole) -> Void) {
        _name = State(initialValue: player?.name ?? "")
        _gender = State(initialValue: player?.gender ?? .female)
        _role = State(initialValue: player?.role ?? .mixed)
        _errorMessage = errorMessage
        isEditing = player != nil
        self.onAdd = onAdd
    }

    var body: some View {
        ZStack {
            AppColors.backgroundDeep.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(isEditing ? "OYUNCU PROFİLİ" : "YENİ OYUNCU")
                                .font(AppTypography.labelSmall)
                                .tracking(1.6)
                                .foregroundColor(AppColors.rubyBright)
                            Text(isEditing ? "Bilgileri düzenle." : "Masaya katıl.")
                                .font(AppTypography.sectionTitle)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)
                                .frame(width: 44, height: 44)
                                .ffGlassChipStyle(cornerRadius: 12)
                        }
                        .accessibilityLabel("Kapat")
                    }
                    FormField(title: "İsim") {
                        TextField("Oyuncu adı", text: $name)
                            .textFieldStyle(CustomTextFieldStyle())
                            .textInputAutocapitalization(.words)
                            .submitLabel(.done)
                    }
                    FormField(title: "Cinsiyet") {
                        Picker("Cinsiyet", selection: $gender) {
                            ForEach(Gender.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                    FormField(title: "Rol") {
                        Picker("Rol", selection: $role) {
                            ForEach(PlayerRole.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(24)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FFPrimaryButton(
                title: isEditing ? "Değişiklikleri Kaydet" : "Oyuncuyu Ekle",
                action: {
                    guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    KeyboardDismiss.resign()
                    onAdd(name, gender, role)
                },
                isEnabled: !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
            .background(AppColors.backgroundDeep)
        }
        .alert("Kaydedilemedi", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("Tamam", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
}

#Preview {
    PlayerSetupView(mode: .playFlow, onContinue: { _ in })
        .environmentObject(PlayerSetupViewModel())
}

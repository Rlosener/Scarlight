import SwiftUI

struct PreparationChecklistSection: View {
    let selectedPropIds: Set<String>
    @Binding var showShare: Bool

    private var items: [GameProp] {
        PropCatalog.allIncludingUser
            .filter { selectedPropIds.contains($0.id) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var checklistText: String {
        var lines = ["Scarlight — Hazırlık Listesi", "Yanına al:"]
        for prop in items {
            lines.append("• \(prop.name)")
        }
        return lines.joined(separator: "\n")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("HAZIRLIK LİSTESİ")
                    .font(AppTypography.labelSmall)
                    .foregroundColor(AppColors.textSecondary)
                    .tracking(2)
                Spacer()
                if !items.isEmpty {
                    ShareLink(item: checklistText) {
                        Label("Paylaş", systemImage: "square.and.arrow.up")
                            .font(AppTypography.labelSmall)
                            .foregroundColor(AppColors.ruby)
                    }
                }
            }

            if items.isEmpty {
                Text("Seçili eşya yok.")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            } else {
                ForEach(items) { prop in
                    HStack(spacing: 10) {
                        Image(systemName: prop.subcategory.icon)
                            .foregroundColor(AppColors.ruby)
                            .frame(width: 20)
                        Text(prop.name)
                            .font(AppTypography.labelSmall)
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Text(prop.subcategory.rawValue)
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.textMuted)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
        .background(AppColors.cardDark.opacity(0.6))
        .cornerRadius(20)
    }
}

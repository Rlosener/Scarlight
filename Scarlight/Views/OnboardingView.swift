import SwiftUI

struct OnboardingView: View {
    var onComplete: () -> Void

    @State private var page = 0

    private let pages: [(icon: String, title: String, body: String)] = [
        ("flame.fill", "Yoğunluk Kademeli Artar", "Soft ile başla; oyun ilerledikçe Medium, Ateşli ve Hardcore açılır. İstediğin zaman manuel de yükseltebilirsin."),
        ("star.fill", "Joker Hakkın Var", "Her oyuncunun 3 jokeri vardır. Zor bir kartta joker kullan — ceza almadan sonraki karta geç."),
        ("hand.raised.fill", "Pas = Ceza", "Pas geçersen hafif veya red cezası gelir. Partner onayı gereken kartlarda hedef oyuncu reddedebilir."),
        ("bag.fill", "Eşya & Deste Filtresi", "Sahip olmadığın eşyaları kapat; sadece o eşyalarla oynanabilir kartlar çıkar. Desteleri de gruplara göre seç.")
    ]

    var body: some View {
        ZStack {
            FFBackground()

            VStack(spacing: 28) {
                Spacer()

                Image(systemName: pages[page].icon)
                    .font(.system(size: 52))
                    .foregroundColor(AppColors.ruby)
                    .shadow(color: AppColors.glowRed.opacity(0.4), radius: 16)

                VStack(spacing: 12) {
                    Text(pages[page].title)
                        .font(AppTypography.sectionTitle)
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(pages[page].body)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }

                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == page ? AppColors.ruby : AppColors.cardElevated)
                            .frame(width: 8, height: 8)
                    }
                }

                Spacer()

                VStack(spacing: 12) {
                    FFPrimaryButton(title: page < pages.count - 1 ? "Devam" : "Başla") {
                        if page < pages.count - 1 {
                            withAnimation { page += 1 }
                        } else {
                            onComplete()
                        }
                    }

                    if page < pages.count - 1 {
                        Button("Atla") { onComplete() }
                            .font(AppTypography.labelSmall)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }
}

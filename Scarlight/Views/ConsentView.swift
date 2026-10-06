import SwiftUI

struct ConsentView: View {
    @Environment(\.sessionTheme) private var theme

    var onConsent: () -> Void

    var body: some View {
        ZStack {
            FFBackground()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    AppLogoMark(style: .withTitle, iconSize: 88)

                    Text("Bu uygulama yalnızca 18 yaş üzeri kullanıcılar için tasarlanmıştır. Oyundaki her görev karşılıklı rızaya bağlıdır. Her oyuncu istediği an pas geçebilir veya oyunu durdurabilir.")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)

                    Text("Her oyuncu istediği an pas geçebilir.")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary.opacity(0.7))
                }
                .padding(32)
                .ffGlassCardStyle(cornerRadius: 30, glow: true)
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(theme.heroGradient)
                        .frame(height: 3)
                        .padding(.horizontal, 42)
                        .padding(.top, 1)
                        .opacity(0.85)
                }
                .padding(.horizontal, 20)

                Spacer()

                FFPrimaryButton(title: "Kabul Ediyorum") {
                    HapticManager.shared.success()
                    onConsent()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    ConsentView(onConsent: {})
}

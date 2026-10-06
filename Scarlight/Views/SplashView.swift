import SwiftUI

struct SplashView: View {
    @State private var scale: CGFloat = 0.96
    @State private var opacity: Double = 0.0
    @State private var glowIntensity: Double = 0.3

    var onComplete: () -> Void

    var body: some View {
        ZStack {
            FFBackground()

            VStack(spacing: 16) {
                AppLogoMark(style: .withTitle, iconSize: 96, showsTagline: true)
                    .scaleEffect(scale)
                    .opacity(opacity)
            }
            .shadow(color: AppColors.glowRed.opacity(glowIntensity), radius: 40, x: 0, y: 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }

            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowIntensity = 0.6
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                onComplete()
            }
        }
    }
}

#Preview {
    SplashView(onComplete: {})
}

import SwiftUI

/// Oturum / ortam içeriğine göre tüm oyun arayüzü renkleri.
struct SessionTheme {
    let profile: SessionContentProfile

    var accent: Color
    var accentBright: Color
    var accentMuted: Color
    var accentSoft: Color
    var glow: Color
    var shadowGlow: Color
    var borderAccent: Color
    var backgroundDeep: Color
    var backgroundWine: Color
    var backgroundGlow: Color
    var backgroundHighlight: Color
    var cardDark: Color
    var cardElevated: Color
    var textSecondary: Color
    var heroGradient: LinearGradient
    var glassAccent: Color
    var glassCardGradient: LinearGradient
    var glassTintGradient: LinearGradient
    var radialAccent: Color
    var radialSecondary: Color

    static func forProfile(_ profile: SessionContentProfile) -> SessionTheme {
        switch profile {
        case .social: return .social
        case .intimate: return .intimate
        }
    }

    static func forAtmosphere(_ atmosphere: PlayAtmosphere) -> SessionTheme {
        switch atmosphere {
        case .friends: return .social
        case .hot: return .intimate
        case .lighter: return .lighter
        }
    }

    /// Ana yüzeylerde grafit zemin ve marka vurgusu.
    static let neutral = SessionTheme(
        profile: .social,
        accent: AppColors.ruby, accentBright: AppColors.rubyBright,
        accentMuted: AppColors.mutedRed, accentSoft: AppColors.softRose,
        glow: .clear, shadowGlow: .clear, borderAccent: AppColors.borderSoft,
        backgroundDeep: AppColors.backgroundDeep, backgroundWine: AppColors.backgroundWine,
        backgroundGlow: AppColors.backgroundGlow, backgroundHighlight: AppColors.backgroundWine,
        cardDark: AppColors.cardDark, cardElevated: AppColors.cardElevated,
        textSecondary: AppColors.textSecondary, heroGradient: AppColors.heroGradient,
        glassAccent: .clear, glassCardGradient: AppColors.glassCardGradient,
        glassTintGradient: AppColors.glassTintGradient, radialAccent: .clear, radialSecondary: .clear
    )

    static let intimate = SessionTheme(
        profile: .intimate,
        accent: AppColors.ruby,
        accentBright: AppColors.rubyBright,
        accentMuted: AppColors.mutedRed,
        accentSoft: AppColors.softRose,
        glow: AppColors.glowRed,
        shadowGlow: AppColors.shadowGlow,
        borderAccent: AppColors.borderRuby,
        backgroundDeep: AppColors.backgroundDeep,
        backgroundWine: AppColors.backgroundWine,
        backgroundGlow: AppColors.backgroundGlow,
        backgroundHighlight: AppColors.backgroundHighlight,
        cardDark: AppColors.cardDark,
        cardElevated: AppColors.cardElevated,
        textSecondary: AppColors.textSecondary,
        heroGradient: AppColors.heroGradient,
        glassAccent: AppColors.glassRose,
        glassCardGradient: AppColors.glassCardGradient,
        glassTintGradient: AppColors.glassTintGradient,
        radialAccent: AppColors.ruby,
        radialSecondary: AppColors.ember
    )

    static let social = SessionTheme(
        profile: .social,
        accent: AppColors.socialBlue,
        accentBright: AppColors.socialBlueBright,
        accentMuted: Color(hex: "#1E4A7A"),
        accentSoft: AppColors.socialSky,
        glow: AppColors.socialBlueBright.opacity(0.50),
        shadowGlow: AppColors.socialBlue.opacity(0.28),
        borderAccent: AppColors.socialBlueBright.opacity(0.45),
        backgroundDeep: Color(hex: "#0B0D12"),
        backgroundWine: Color(hex: "#10141C"),
        backgroundGlow: Color(hex: "#141C29"),
        backgroundHighlight: Color(hex: "#1A2533"),
        cardDark: Color(hex: "#141B26"),
        cardElevated: Color(hex: "#1A2534"),
        textSecondary: Color(hex: "#B4BECC"),
        heroGradient: AppColors.socialHeroGradient,
        glassAccent: AppColors.socialBlue.opacity(0.14),
        glassCardGradient: LinearGradient(
            colors: [
                AppColors.socialBlueBright.opacity(0.18),
                Color(hex: "#141C29").opacity(0.52),
                Color(hex: "#0B0D12").opacity(0.75)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        glassTintGradient: LinearGradient(
            colors: [
                Color.white.opacity(0.10),
                AppColors.socialBlue.opacity(0.14),
                Color(hex: "#10141C").opacity(0.62)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        radialAccent: AppColors.socialBlueBright,
        radialSecondary: AppColors.socialSky
    )

    static let lighter = SessionTheme(
        profile: .social,
        accent: AppColors.lighterOrange,
        accentBright: AppColors.lighterOrangeBright,
        accentMuted: AppColors.lighterBrown,
        accentSoft: AppColors.lighterAmber,
        glow: AppColors.lighterFlame.opacity(0.50),
        shadowGlow: AppColors.lighterOrange.opacity(0.32),
        borderAccent: AppColors.lighterOrangeBright.opacity(0.50),
        backgroundDeep: Color(hex: "#0F0D0B"),
        backgroundWine: Color(hex: "#181410"),
        backgroundGlow: Color(hex: "#241C16"),
        backgroundHighlight: Color(hex: "#2B2119"),
        cardDark: Color(hex: "#1B1612"),
        cardElevated: Color(hex: "#272019"),
        textSecondary: Color(hex: "#C4BBB2"),
        heroGradient: AppColors.lighterHeroGradient,
        glassAccent: AppColors.lighterOrange.opacity(0.16),
        glassCardGradient: LinearGradient(
            colors: [
                AppColors.lighterFlame.opacity(0.20),
                Color(hex: "#241C16").opacity(0.55),
                Color(hex: "#0F0D0B").opacity(0.78)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        glassTintGradient: LinearGradient(
            colors: [
                Color.white.opacity(0.10),
                AppColors.lighterOrange.opacity(0.14),
                AppColors.lighterDeep.opacity(0.68)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        radialAccent: AppColors.lighterFlame,
        radialSecondary: AppColors.lighterOrangeBright
    )
}

private struct SessionThemeKey: EnvironmentKey {
    static let defaultValue = SessionTheme.neutral
}

extension EnvironmentValues {
    var sessionTheme: SessionTheme {
        get { self[SessionThemeKey.self] }
        set { self[SessionThemeKey.self] = newValue }
    }
}

extension View {
    func sessionTheme(_ profile: SessionContentProfile) -> some View {
        environment(\.sessionTheme, SessionTheme.forProfile(profile))
    }

    func sessionTheme(for atmosphere: PlayAtmosphere) -> some View {
        environment(\.sessionTheme, SessionTheme.forAtmosphere(atmosphere))
    }

    func neutralAppTheme() -> some View {
        environment(\.sessionTheme, .neutral)
    }

    func gamePerformanceMode() -> some View {
        environment(\.ffPerformanceMode, true)
            .visualEffectBudget(.reduced)
    }
}

private struct FFPerformanceModeKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var ffPerformanceMode: Bool {
        get { self[FFPerformanceModeKey.self] }
        set { self[FFPerformanceModeKey.self] = newValue }
    }
}

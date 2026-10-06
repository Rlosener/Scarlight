import SwiftUI

struct AppColors {
    // MARK: - Atmosphere (ateşli, derin, okunabilir)
    static let backgroundDeep = Color(hex: "#0C0B0E")
    static let backgroundWine = Color(hex: "#121014")
    static let backgroundGlow = Color(hex: "#21141B")
    static let backgroundHighlight = Color(hex: "#2A161F")

    // MARK: - Solid surfaces (cam alt katman)
    static let cardDark = Color(hex: "#17161B")
    static let cardElevated = Color(hex: "#211E25")

    // MARK: - Brand / ateş
    static let primaryRed = Color(hex: "#B11226")
    static let ruby = Color(hex: "#E02B3F")
    static let rubyBright = Color(hex: "#FF3D55")
    static let mutedRed = Color(hex: "#6E1823")
    static let softRose = Color(hex: "#F2A6B3")
    static let ember = Color(hex: "#FF6B4A")
    static let champagne = Color(hex: "#D4CED8")
    static let gold = Color(hex: "#C5C0CC")

    // MARK: - Arkadaş / bar (mavi)
    static let socialBlue = Color(hex: "#2B6CB0")
    static let socialBlueBright = Color(hex: "#4299E1")
    static let socialSky = Color(hex: "#90CDF4")
    static let socialNavy = Color(hex: "#1A365D")

    static let socialHeroGradient = LinearGradient(
        colors: [socialBlueBright, socialBlue, socialNavy],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Çakmak oyunu (turuncu / amber)
    static let lighterOrange = Color(hex: "#EA580C")
    static let lighterOrangeBright = Color(hex: "#FB923C")
    static let lighterAmber = Color(hex: "#FDBA74")
    static let lighterFlame = Color(hex: "#FF6B35")
    static let lighterBrown = Color(hex: "#7C2D12")
    static let lighterDeep = Color(hex: "#1A0F08")

    static let lighterHeroGradient = LinearGradient(
        colors: [lighterFlame, lighterOrangeBright, lighterOrange, lighterBrown],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Text
    static let textPrimary = Color(hex: "#FFF6F7")
    static let textSecondary = Color(hex: "#B8B4BE")
    static let textMuted = Color(hex: "#89838F")

    // MARK: - Glass tints
    static let glassWhite = Color.white.opacity(0.10)
    static let glassRose = Color(hex: "#E02B3F").opacity(0.14)
    static let glassWine = Color(hex: "#2A0E16").opacity(0.62)
    static let glassDeep = Color(hex: "#12060C").opacity(0.78)

    // MARK: - Borders & glow
    static let borderSoft = Color.white.opacity(0.14)
    static let borderStrong = Color.white.opacity(0.24)
    static let borderRuby = Color(hex: "#E02B3F").opacity(0.45)
    static let glowRed = Color(hex: "#E02B3F").opacity(0.50)
    static let shadowColor = Color(hex: "#050104").opacity(0.55)
    static let shadowGlow = Color(hex: "#E02B3F").opacity(0.28)

    // MARK: - Gradients
    static let heroGradient = LinearGradient(
        colors: [rubyBright, ruby, primaryRed, Color(hex: "#7A1020")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let glassSheen = LinearGradient(
        colors: [
            Color.white.opacity(0.22),
            Color.white.opacity(0.06),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .center
    )

    static let stageDepth = LinearGradient(
        colors: [
            Color.white.opacity(0.08),
            Color.clear,
            Color.black.opacity(0.34)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let edgeLight = LinearGradient(
        colors: [
            Color.white.opacity(0.52),
            Color.white.opacity(0.08),
            Color.white.opacity(0.22)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let glassTintGradient = LinearGradient(
        colors: [glassWhite, glassRose, glassWine],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let glassCardGradient = LinearGradient(
        colors: [
            Color(hex: "#E02B3F").opacity(0.18),
            Color(hex: "#21141B").opacity(0.52),
            Color(hex: "#12060C").opacity(0.75)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let glassBorderGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.38),
            Color.white.opacity(0.10),
            borderRuby.opacity(0.35)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

enum FFGlassStyle {
    case panel
    case card
    case chip
}

struct FFGlassBackground: View {
    @Environment(\.sessionTheme) private var theme
    @Environment(\.ffPerformanceMode) private var performanceMode
    @Environment(\.visualEffectBudget) private var effectBudget

    var cornerRadius: CGFloat
    var style: FFGlassStyle = .panel
    var glow: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(baseFill)
            .overlay {
                if !usesReducedEffects {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(tintGradient)
                }
            }
            .overlay {
                if !usesReducedEffects {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(AppColors.glassSheen)
                        .blendMode(.screen)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(style == .chip ? 0.08 : 0.10), lineWidth: 1)
            }
            .overlay {
                if glow && effectBudget.allowsPremiumGlow {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(theme.borderAccent, lineWidth: 1.5)
                }
            }
    }

    private var usesReducedEffects: Bool {
        performanceMode || effectBudget == .reduced
    }

    private var baseFill: Color {
        switch style {
        case .panel:
            return theme.cardDark
        case .card:
            return theme.cardDark
        case .chip:
            return theme.cardElevated
        }
    }

    private var tintGradient: LinearGradient {
        switch style {
        case .panel:
            return theme.glassTintGradient
        case .card:
            return theme.glassCardGradient
        case .chip:
            return LinearGradient(
                colors: [
                    theme.glassAccent,
                    theme.backgroundWine.opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct ThemedGlassShadow: ViewModifier {
    @Environment(\.sessionTheme) private var theme
    @Environment(\.visualEffectBudget) private var effectBudget
    var radius: CGFloat
    var y: CGFloat

    func body(content: Content) -> some View {
        content.shadow(
            color: effectBudget.allowsPremiumGlow ? theme.shadowGlow : .clear,
            radius: min(radius, effectBudget.shadowRadius),
            x: 0,
            y: y
        )
    }
}

extension View {
    func ffGlassPanelStyle(cornerRadius: CGFloat = 20, glow: Bool = false) -> some View {
        self
            .background {
                FFGlassBackground(cornerRadius: cornerRadius, style: .panel, glow: glow)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .modifier(ThemedGlassShadow(radius: 10, y: 6))
    }

    func ffGlassCardStyle(cornerRadius: CGFloat = 18, glow: Bool = true) -> some View {
        self
            .background {
                FFGlassBackground(cornerRadius: cornerRadius, style: .card, glow: glow)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .modifier(ThemedGlassShadow(radius: 16, y: 6))
    }

    func ffGlassChipStyle(cornerRadius: CGFloat = 16) -> some View {
        self
            .background {
                FFGlassBackground(cornerRadius: cornerRadius, style: .chip)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    /// Eski API uyumluluğu
    func ffPanelStyle(cornerRadius: CGFloat = 20) -> some View {
        ffGlassPanelStyle(cornerRadius: cornerRadius)
    }

    func ffContentCardStyle(cornerRadius: CGFloat = 32) -> some View {
        ffGlassCardStyle(cornerRadius: cornerRadius)
    }
}

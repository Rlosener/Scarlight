import Foundation

/// Ana menüden açılan ekranlar — NavigationStack ile yönetilir.
enum AppRoute: Hashable {
    case menu
    case players
    case decksAndProps
    case cards
    case settings
    case history
    case customProps
    case playPlayers
    case playAtmosphere
    case playSetup(PlayAtmosphere)
}

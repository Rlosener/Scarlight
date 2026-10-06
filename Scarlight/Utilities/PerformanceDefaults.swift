import Foundation

enum PerformanceDefaults {
    static let performanceModeKey = "isPerformanceModeEnabled"

    private static let migrationKey = "hasAppliedMVPPerformanceDefault_v2"

    static func registerAndApplyMVPDefaults(userDefaults: UserDefaults = .standard) {
        userDefaults.register(defaults: [performanceModeKey: true])

        guard !userDefaults.bool(forKey: migrationKey) else { return }
        userDefaults.set(true, forKey: performanceModeKey)
        userDefaults.set(true, forKey: migrationKey)
    }
}

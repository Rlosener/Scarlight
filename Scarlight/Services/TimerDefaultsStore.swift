import Foundation

struct TimerDefaults: Codable, Equatable {
    var beginningSeconds: Int = 30
    var mediumSeconds: Int = 45
    var hotSeconds: Int = 60
    var penaltyFloorSeconds: Int = 30

    func seconds(for tier: ContentTier?) -> Int {
        switch tier {
        case .beginning, .none: return beginningSeconds
        case .medium: return mediumSeconds
        case .hot: return hotSeconds
        }
    }
}

enum TimerDefaultsStore {
    private static let key = "timer_defaults_v1"

    static func load() -> TimerDefaults {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(TimerDefaults.self, from: data) else {
            return TimerDefaults()
        }
        return decoded
    }

    static func save(_ defaults: TimerDefaults) {
        if let data = try? JSONEncoder().encode(defaults) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

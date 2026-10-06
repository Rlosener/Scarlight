import Foundation

/// Hızlı çoklu dokunuşları engeller.
enum TapThrottle {
    private static var stamps: [String: Date] = [:]
    private static let lock = NSLock()

    @discardableResult
    static func tryFire(key: String = "global", cooldown: TimeInterval = 0.55) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        let now = Date()
        if let last = stamps[key], now.timeIntervalSince(last) < cooldown {
            return false
        }
        stamps[key] = now
        return true
    }
}

#if canImport(UIKit)
import UIKit

enum KeyboardDismiss {
    static func resign() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
#endif

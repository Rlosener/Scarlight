import Foundation

struct SurpriseTask: Identifiable, Codable, Equatable {
    let id: String
    var text: String
    var durationSeconds: Int
    var requiresTargetConsent: Bool

    init(id: String = UUID().uuidString, text: String, durationSeconds: Int, requiresTargetConsent: Bool = false) {
        self.id = id
        self.text = text
        self.durationSeconds = durationSeconds
        self.requiresTargetConsent = requiresTargetConsent
    }
}

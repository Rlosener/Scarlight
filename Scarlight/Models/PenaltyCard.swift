import Foundation

struct PenaltyCard: Identifiable, Codable, Equatable {
    let id: String
    var title: String
    var type: PenaltyType
    var relatedCategory: CardType
    var intensity: Int
    var durationSeconds: Int
    var text: String
    var isActive: Bool

    init(
        id: String = UUID().uuidString,
        title: String,
        type: PenaltyType,
        relatedCategory: CardType,
        intensity: Int,
        durationSeconds: Int,
        text: String,
        isActive: Bool = true
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.relatedCategory = relatedCategory
        self.intensity = intensity
        self.durationSeconds = durationSeconds
        self.text = text
        self.isActive = isActive
    }
}

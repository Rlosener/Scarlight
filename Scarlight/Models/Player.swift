import Foundation
import SwiftUI

struct Player: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var gender: Gender
    var role: PlayerRole
    var colorHex: String
    var isActive: Bool
    var jokersRemaining: Int

    init(id: UUID = UUID(), name: String, gender: Gender, role: PlayerRole, colorHex: String, isActive: Bool = true, jokersRemaining: Int = 3) {
        self.id = id
        self.name = name
        self.gender = gender
        self.role = role
        self.colorHex = colorHex
        self.isActive = isActive
        self.jokersRemaining = jokersRemaining
    }

    var color: Color {
        Color(hex: colorHex)
    }
}
